// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./HoldingsManager.sol";

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";

// Testnet deployments https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment
interface IEgeneLayerConstracts {
    function delegationManager() external view returns (DelegationManager);
    function strategyManager() external view returns (StrategyManager);
}

contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;
    IEgeneLayerConstracts eigenLayerContracts;

    constructor(IERC20Metadata _underlyingAsset, IEgeneLayerConstracts _eigenLayerContracts, HoldingsManager _holdingsManager)
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked("cb", _underlyingAsset.symbol()))
        )
    {
        eigenLayerContracts = _eigenLayerContracts;
        holdingsManager = _holdingsManager;
    }

    function totalAssets()
        public
        view
        override
        returns (uint256)
    {
        // Implementation of how to calculate total assets
        return 0;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        uint256 r = super.withdraw(assets, receiver, owner);
        _unstake(r);
        return r;
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256) {
        uint256 r = super.redeem(shares, receiver, owner);
        // TODO: what does redeem returns?
        _unstake(r);
        return r;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        uint256 deposited =  super.deposit(assets, receiver);
        _stake(deposited);
        return deposited;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256) {
        return super.mint(shares, receiver);
    }


    /* Function has to be called from deposit()
        1. Get the list of Operators and stake in the porfolio
        2. Check out current investment positions (add vault holdings map)
        3. redistribute available funds over available Operators to keep "stake_bps" relevant
    */
    function _stake(uint256 deposited) private {

    }


    /* Function has to be called from withdraw()
        1. Get the list of Operators and stake in the porfolio
        2. Check out current investment positions (add vault holdings map)
        3. withdraw available funds from the available Operators to keep "stake_bps" relevant
    */
    function _unstake(uint256 withdrawn) private {

    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L392
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L91
    */
    function _depositAndDelegateToEigenLayerOperator(address operatorAddress, bytes memory approverSignature, bytes32 approverSalt) private {
        DelegationManager delegationManager = eigenLayerContracts.delegationManager();
        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry;
        uint256 expiry = type(uint256).max;

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
    function _undelegateFromEigenLayerOperator() private  {

    }
}