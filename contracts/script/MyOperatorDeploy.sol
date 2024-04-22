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
import "../src/MyOperator.sol";

contract DeployTestOperator is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyOperator mOperator = new MyOperator(LocalContractsStore.getOperatorAddress(vm), LocalContractsStore.getContractsDirectory(vm));
        vm.stopBroadcast();

        vm.writeFile('.data/MyOperator.txt', address(mOperator).toHexString());
        console2.log("MyOperator address", address(mOperator));
    }
}