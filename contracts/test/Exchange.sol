// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../src/Exchange.sol";

/**
    This is simple exchnage implemnetation for testing-purposes only
    ⚠️ DO NOT USE IN PRODUCTION!!!!
*/
contract TestExchange is IExchange {
    function getExchangeRate(ERC20 /* source */, ERC20 /* destination */) public pure returns (uint) {
        return 1;
    }

    function swap(address owner, address  receiver, ERC20 sourceAsset, ERC20 destinationAsset, uint256 amount) external returns (uint256) {
        uint targetAssets = amount * getExchangeRate(sourceAsset, destinationAsset);
        require(destinationAsset.balanceOf(address(this)) >= targetAssets, "No liquidity in a pool");

        sourceAsset.transferFrom(owner, address(this), amount);
        destinationAsset.transfer(receiver, targetAssets);
        return targetAssets;
    }
}