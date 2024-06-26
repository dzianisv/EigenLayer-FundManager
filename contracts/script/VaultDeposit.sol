// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {Script, console2} from "forge-std/Script.sol";

import "./AddressLibrary.sol";
import "./LocalContractsStore.sol";

import "../src/Vault.sol";
import "../test/MintableToken.sol";
import "../src/HoldingsManager.sol";
import "../src/ContractsDirectory.sol";

contract TestDeposit is Script {
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        Vault vault = LocalContractsStore.getVault(vm);

        // ETHx
        ERC20 liquidStakedToken = LocalContractsStore.getETHxToken(vm);
        uint256 testDeposit = liquidStakedToken.decimals() / 100;

        console2.log("pre-msg.sender", msg.sender);
        console2.log("pre-liquidStakedToken.balanceOf()", liquidStakedToken.balanceOf(msg.sender));
        console2.log("pre-totalAssets()", vault.totalAssets());
        console2.log("pre-balanceOf()", vault.balanceOf(msg.sender));

        vm.startBroadcast();
    
        liquidStakedToken.approve(address(vault), testDeposit);
        vault.deposit(testDeposit, msg.sender);
    
        vm.stopBroadcast();

        console2.log("post-totalAssets()", vault.totalAssets());
        console2.log("post-balanceOf()", vault.balanceOf(msg.sender));

    }
}