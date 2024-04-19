// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./HoldingsManager.sol";

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// Testnet deployments https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment
interface IEgeneLayerConstracts {
    function delegationManager() external view returns (DelegationManager);
    function strategyManager() external view returns (StrategyManager);
}

contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;
    IEgeneLayerConstracts eigenLayerContracts;

    using EnumerableMap for EnumerableMap.UintToUintMap;
    EnumerableMap.UintToUintMap private oepratorsStake; // in asset() tokens

    constructor(
        IERC20Metadata _underlyingAsset,
        IEgeneLayerConstracts _eigenLayerContracts,
        HoldingsManager _holdingsManager
    )
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked("cb", _underlyingAsset.symbol()))
        )
    {
        eigenLayerContracts = _eigenLayerContracts;
        holdingsManager = _holdingsManager;
    }

    function totalAssets() public view override returns (uint256) {
        // Implementation of how to calculate total assets
        return 0;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        uint256 unstaked_amount = _unstake(assets);
        return  super.withdraw(unstaked_amount, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256) {
        revert("Redeem function is not supported");
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        uint256 deposited = super.deposit(assets, receiver);
        _stake(deposited);
        return deposited;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256) {
        return super.mint(shares, receiver);
    }

    function _stake(uint256 deposited) private {
        (address[] memory operators, uint256[] memory stakes) = holdingsManager
            .getAllOperatorStakes();
        uint256 totalStake = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            totalStake += stakes[i];
        }

        for (uint256 i = 0; i < operators.length; i++) {
            uint256 stakeAmount = (deposited * stakes[i]) / totalStake;
            oepratorsStake.set(
                uint256(uint160(operators[i])),
                oepratorsStake.get(uint256(uint160(operators[i]))) + stakeAmount
            );

            // Approve the deposited tokens to the operator
            IERC20(asset()).approve(operators[i], stakeAmount);

            // Deposit and delegate to the EigenLayer operator
            bytes memory approverSignature = ""; // Provide the approver signature
            _depositAndDelegateToEigenLayerOperator(
                operators[i],
                approverSignature
            );
        }
    }

    function _unstake(uint256 withdrawn) private returns (uint256) {
        (address[] memory operators, uint256[] memory stakes) = holdingsManager
            .getAllOperatorStakes();
        uint256 totalStake = 0;
        for (uint256 i = 0; i < stakes.length; i++) {
            totalStake += stakes[i];
        }

        for (uint256 i = 0; i < operators.length; i++) {
            uint256 unstakeAmount = (withdrawn * stakes[i]) / totalStake;
            uint256 currentStake = oepratorsStake.get(
                uint256(uint160(operators[i]))
            );
            if (unstakeAmount > currentStake) {
                unstakeAmount = currentStake;
            }
            oepratorsStake.set(
                uint256(uint160(operators[i])),
                currentStake - unstakeAmount
            );

            // Undelegate from the EigenLayer operator
            _undelegateFromEigenLayerOperator(operators[i], unstakeAmount);
        }
    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L392
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L91
    */
    function _depositAndDelegateToEigenLayerOperator(
        address operatorAddress,
        bytes memory approverSignature
    ) private {
        DelegationManager delegationManager = eigenLayerContracts
            .delegationManager();
        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory emptySig;
        uint256 expiry = type(uint256).max;

        // Get signature
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry;
        approverSignatureAndExpiry.expiry = expiry;
        approverSignatureAndExpiry.signature = approverSignature; // use the provided signature

        // Delegate
        delegationManager.delegateTo(
            operatorAddress,
            approverSignatureAndExpiry,
            bytes32(0)
        );
    }


    /*
        Called from _unstake()
        Interacts with EigenLayer DelegationManager
        Check out 
    */
    function _undelegateFromEigenLayerOperator(
        address operatorAddress,
        uint256 amount) private
    {}
}
