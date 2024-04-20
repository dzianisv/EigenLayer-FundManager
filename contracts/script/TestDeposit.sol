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


contract TestDeposit is Script {
    function setUp() public {}

    function run() public {
        Vault vault = Vault(vm.envAddress("VAULT_ADDRESS"));
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

contract DeployTestOperator is Script {
    function setUp() public {}

    function run() public {
        IEigenLayerContracts eigenLayerContracts = IEigenLayerContracts(vm.envAddress("EIGEN_LAYER_CONTRACTS_ADDRESS"));
        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));

        vm.startBroadcast();
        // Coinbase Operator: https://holesky.etherscan.io/address/0xbe4b4fa92b6767fda2c8d1db53a286834db19638
        MyOperator mOperator = new MyOperator(address(0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638));
        vm.stopBroadcast();

        console2.log("MyOperator address", address(mOperator));
    }
}

contract TestMyOperator is Script {
    function setUp() public {}

    function run() public {
        IEigenLayerContracts eigenLayerContracts = IEigenLayerContracts(vm.envAddress("EIGEN_LAYER_CONTRACTS_ADDRESS"));
        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));
        MyOperator mOperator = MyOperator(vm.envAddress("MY_OPERATOR_ADDRESS"));

        vm.startBroadcast();
        liquidStakedToken.approve(address(mOperator), 10);
        mOperator.stake(liquidStakedToken, 10, eigenLayerContracts);
        vm.stopBroadcast();
    }
}