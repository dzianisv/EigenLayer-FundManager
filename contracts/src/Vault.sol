// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./HoldingsManager.sol";

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";

// Testnet deployments https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment
interface IUserDeployer {
    function delegationManager() external view returns (DelegationManager);
    function strategyManager() external view returns (StrategyManager);
}

contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;

    constructor(IERC20Metadata _underlyingAsset)
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked("a", _underlyingAsset.symbol()))
        )
    {
        // Additional constructor logic if necessary
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
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        return super.deposit(assets, receiver);
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
    function _stake() private {

    }


    /* Function has to be called from withdraw()
        1. Get the list of Operators and stake in the porfolio
        2. Check out current investment positions (add vault holdings map)
        3. withdraw available funds from the available Operators to keep "stake_bps" relevant
    */
    function _unstake() private {

    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L392
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L91
    */
    function _depositAndDelegateToEigenLayerOperator(address operatorAddress) private {
        // Get the instance of the DelegationManager contract
        DelegationManager delegationManager = DelegationManager();

        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory emptySig;
        uint256 expiry = type(uint256).max;

        // Get signature
        ISignatureUtils.SignatureWithExpiry memory stakerSignatureAndExpiry;
        stakerSignatureAndExpiry.expiry = expiry;
        bytes32 digestHash = delegationManager.calculateCurrentStakerDelegationDigestHash(address(this), operatorAddress, expiry);
        stakerSignatureAndExpiry.signature = bytes(abi.encodePacked(digestHash)); // dummy sig data

        // Mark hash as signed
        signedHashes[digestHash] = true;

        // Delegate
        delegationManager.delegateToBySignature(address(this), address(operator), stakerSignatureAndExpiry, emptySig, bytes32(0));

        // Mark hash as used
        signedHashes[digestHash] = false;
    }

    /*
        Called from _unstake()
        Interacts with EigenLayer DelegationManager
        Check out 
    */
    function _undelegateFromEigenLayerOperator() private  {

    }
}