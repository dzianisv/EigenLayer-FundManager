// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {Script, console2} from "forge-std/Script.sol";

import "./ContractsStore.sol";
import"../src/Vault.sol";
import "../test/MintableToken.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "../src/MyOperator.sol";


contract TestMyOperator is Script {
    function setUp() public {}

    function run() public {
        ERC20 liquidStakedToken = ContractsStore.getETHxToken(vm);
        console2.log(liquidStakedToken.symbol(), liquidStakedToken.balanceOf(msg.sender));

        MyOperator mOperator = ContractsStore.getMyOperator(vm);
        uint256 amount = 1;
        console2.log("msg.sender", msg.sender);
        console2.log("MyOperator", address(mOperator));

        vm.startBroadcast();
        liquidStakedToken.approve(address(mOperator), amount);
        mOperator.stake(liquidStakedToken, amount);
        vm.stopBroadcast();
        console2.log("Deposited", amount);
    }
}