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
    uint256 totalDepositedTokens;
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;
    IEgeneLayerConstracts eigenLayerContracts;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private stakedTokensPortfolio; // Map that represents current stake porfolio: OperatorAddress:AssetTokensStaked

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
        return totalDepositedTokens;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        // uint256 unstaked_amount = _unstake(assets);
        // return super.withdraw(unstaked_amount, receiver, owner);
        revert("withdraw function is not supported");
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
        _redistribute();
    }

    function _unstake(uint256 withdrawn) private returns (uint256) {
        _redistribute();
    }

    function _redistribute() private {
        (address[] memory operators, uint256[] memory targetStakesBps) = holdingsManager.getAllOperatorStakes();
        uint256 totalAssets = this.totalAssets();  // Total assets managed by the vault

        // Iterate through the portfolio to adjust or remove stakes
        for (uint i = 0; i < stakedTokensPortfolio.length(); i++) {
            (address operator, uint256 currentStake) = stakedTokensPortfolio.at(i);
            uint256 targetStake = _calculateTargetStake(operator, totalAssets, operators, targetStakesBps);

            if (targetStake > currentStake) {
                uint256 amountToStake = targetStake - currentStake;
                _depositAndDelegateToEigenLayerOperator(operator, amountToStake);
                stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio map to reflect the new stake
            } else if (currentStake > targetStake) {
                uint256 amountToUnstake = currentStake - targetStake;
                _undelegateFromEigenLayerOperator(operator, amountToUnstake);
                if (targetStake == 0) {
                    stakedTokensPortfolio.remove(operator);  // Remove operator from portfolio if no longer needed
                } else {
                    stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio
                }
            }
        }

        // Handle any new operators not already in the portfolio
        for (uint j = 0; j < operators.length; j++) {
            address operator = operators[j];
            uint256 targetStake = totalAssets * targetStakesBps[j] / 10000;
            if (!stakedTokensPortfolio.contains(operator) && targetStake > 0) {
                _depositAndDelegateToEigenLayerOperator(operator, targetStake);
                stakedTokensPortfolio.set(operator, targetStake);  // Add new operator to the portfolio
            }
        }
    }

    function _calculateTargetStake(address operator, uint256 totalAssets, address[] memory operators, uint256[] memory targetStakesBps) private pure returns (uint256) {
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == operator) {
                return totalAssets * targetStakesBps[i] / 10000;
            }
        }
        return 0;  // Return 0 if the operator is not found in the target distribution
    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L392
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L91
    */
    function _depositAndDelegateToEigenLayerOperator(
        address operatorAddress,
        uint256 amount
    ) private {
        DelegationManager delegationManager = eigenLayerContracts
            .delegationManager();
        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry;
        uint256 expiry = type(uint256).max;

        //TODO: get them from HoldingsManager?
        bytes memory approverSignature; 
        bytes32 approverSalt = 0x0; 

        // Get signature
        if (approverSignature.length > 0) {
            // Get signature
            approverSignatureAndExpiry.expiry = expiry;
            approverSignatureAndExpiry.signature = approverSignature; // use the provided signature
        } else {
            // Use empty signature
            approverSignatureAndExpiry = ISignatureUtils.SignatureWithExpiry({expiry: expiry, signature: ""});
        }
        // Use provided salt if it's not zero, otherwise use zero salt
        bytes32 salt = approverSalt != bytes32(0) ? approverSalt : bytes32(0);
        // Delegate to the operator
        delegationManager.delegateTo(operatorAddress, approverSignatureAndExpiry, salt);
    }

    /*
        Called from _unstake()
        Interacts with EigenLayer DelegationManager
        Check out 
    */
    function _undelegateFromEigenLayerOperator(address operator, uint256 amount) private {
        DelegationManager delegationManager = eigenLayerContracts.delegationManager();
        //TODO: undelegate just a part of the staked tokens
        // Call the undelegate function
        delegationManager.undelegate(address(this));
    }
}
