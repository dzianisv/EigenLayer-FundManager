// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {Script, console2} from "forge-std/Script.sol";

import "./AddressLibrary.sol";
import "./ContractsStore.sol";
import "../src/Vault.sol";
import "../test/MintableToken.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "../src/MyOperator.sol";

contract DeployTestOperator is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MyOperator mOperator = new MyOperator(ContractsStore.getOperatorAddress(vm), ContractsStore.getEigenLayerContracts(vm));
        vm.stopBroadcast();

        vm.writeFile('.data/MyOperator.txt', address(mOperator).toHexString());
        console2.log("MyOperator address", address(mOperator));
    }
}