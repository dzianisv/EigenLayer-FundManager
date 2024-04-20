// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../src/Vault.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Vault} from "../src/Vault.sol";
import "../test/TestCoin.sol";
import {HoldingsManager} from "../src/HoldingsManager.sol";
import {IEigenLayerContracts, TestnetContracts} from "../src/EigenLayerContracts.sol";
import {MyOperator} from "../src/MyOperator.sol";


contract TestMyOperator is Script {
    function setUp() public {}

    function run() public {
        IEigenLayerContracts eigenLayerContracts = IEigenLayerContracts(vm.envAddress("EIGEN_LAYER_CONTRACTS_ADDRESS"));

        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));
        console2.log(liquidStakedToken.symbol(), liquidStakedToken.balanceOf(msg.sender));

        MyOperator mOperator = MyOperator(vm.envAddress("MY_OPERATOR_ADDRESS"));

        vm.startBroadcast();
        liquidStakedToken.approve(address(mOperator), 1);
        mOperator.stake(liquidStakedToken, 1, eigenLayerContracts);
        vm.stopBroadcast();
    }
}