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

contract DeployVault is Script {
    using AddressLibrary for address;
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        // ETHx @ Honesky: https://holesky.etherscan.io/token/
        ERC20 liquidStakedToken = LocalContractsStore.getETHxToken(vm);

        vm.startBroadcast();
        IContractsDirectory contractsDirectory = new TestnetContracts(
            LocalContractsStore.getRewardsToken(vm),
            LocalContractsStore.getExchnage(vm)
        );

        HoldingsManager holdingsManager = new HoldingsManager(
            address(msg.sender),
            LocalContractsStore.getContractsDirectory(vm)
        );
        Vault vault = new Vault(
            liquidStakedToken,
            holdingsManager,
            contractsDirectory
        );
        // Coinbase Operator: https://holesky.etherscan.io/address/0xbe4b4fa92b6767fda2c8d1db53a286834db19638
        holdingsManager.setOperator(
            address(0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638),
            6000
        );

        holdingsManager.setOperator(
            address(0x5e29b3107937b4675FdDF113EDC5530498B3Fb70),
            2000
        );
        
        holdingsManager.setOperator(
            address(0x4E59E88207Ac04e6615D79Ae565E877DD80BCF8e),
            2000
        );

        vm.stopBroadcast();

        console2.log("ContractsDirectory address", address(contractsDirectory));
        vm.writeFile(
            ".data/ContractsDirectory.txt",
            address(contractsDirectory).toHexString()
        );

        console2.log("Vault address", address(vault));
        vm.writeFile(".data/Vault.txt", address(vault).toHexString());
    }
}
