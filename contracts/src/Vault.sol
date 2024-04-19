// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./HoldingsManager.sol";

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";

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
    function _stake() {

    }


    /* Function has to be called from withdraw()
        1. Get the list of Operators and stake in the porfolio
        2. Check out current investment positions (add vault holdings map)
        3. withdraw available funds from the available Operators to keep "stake_bps" relevant
    */
    function _unstake() {

    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
    */
    function _delegate() {

    }

    /*
        Called from _unstake()
        Interacts with EigenLayer DelegationManager
        Check out https://github.com/Layr-Labs/eigenlayer-contracts/blob/7229f2b426b6f2a24c7795b1a4687a010eac8ef2/src/test/integration/users/User.t.sol#L19 

    */
    function _undelegate() {

    }
}