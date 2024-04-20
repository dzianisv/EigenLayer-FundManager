// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../src/Vault.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../src/Vault.sol";
import "../test/TestCoin.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "./AddressLibrary.sol";

contract TestDeposit is Script {
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        Vault vault = Vault(vm.readFile(".data/Vault.txt").toAddress());

        // ETHx
        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));
        uint256 testDeposit = 100;
        console2.log("Vault address", address(vault));


        vm.startBroadcast();
    
        liquidStakedToken.approve(address(vault), testDeposit);
        vault.deposit(testDeposit, msg.sender);
        console2.log("totalDeposited()", vault.totalDeposited());
        console2.log("totalAssets()", vault.totalAssets());
        console2.log("balanceOf()", vault.balanceOf(msg.sender));

        vm.stopBroadcast();
    }
}