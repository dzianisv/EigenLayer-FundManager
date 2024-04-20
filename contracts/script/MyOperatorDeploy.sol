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
import "./AddressLibrary.sol";

contract DeployTestOperator is Script {
    using AddressLibrary for address;
    
    function setUp() public {}

    function run() public {
        IEigenLayerContracts eigenLayerContracts = IEigenLayerContracts(vm.envAddress("EIGEN_LAYER_CONTRACTS_ADDRESS"));
        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));

        vm.startBroadcast();
        // Coinbase Operator: https://holesky.etherscan.io/address/0xbe4b4fa92b6767fda2c8d1db53a286834db19638
        MyOperator mOperator = new MyOperator(address(0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638));
        vm.stopBroadcast();

        vm.writeFile('.data/MyOperator.txt', address(mOperator).toHexString());
        console2.log("MyOperator address", address(mOperator));
    }
}