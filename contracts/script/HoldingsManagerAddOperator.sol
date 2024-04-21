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

contract AddOperatorScript is Script {
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        Vault vault = ContractsStore.getVault(vm);
        HoldingsManager holdingsManager = vault.holdingsManager();
     
        vm.startBroadcast();
        holdingsManager.setOperator(address(0x5e29b3107937b4675FdDF113EDC5530498B3Fb70), 10);
        holdingsManager.setOperator(address(0x4E59E88207Ac04e6615D79Ae565E877DD80BCF8e), 10);
        vm.stopBroadcast();
    }
}