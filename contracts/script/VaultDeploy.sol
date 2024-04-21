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

contract DeployVault is Script {
    using AddressLibrary for address;
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        // ETHx @ Honesky: https://holesky.etherscan.io/token/
        ERC20 liquidStakedToken = ContractsStore.getETHxToken(vm);

        vm.startBroadcast();
        IEigenLayerContracts elContracts = new TestnetContracts(
            ContractsStore.getRewardsToken(vm),
            ContractsStore.getExchnage(vm)
        );

        HoldingsManager holdingsManager = new HoldingsManager(
            address(msg.sender),
            ContractsStore.getEigenLayerContracts(vm)
        );
        Vault vault = new Vault(
            liquidStakedToken,
            holdingsManager,
            elContracts
        );
        // Coinbase Operator: https://holesky.etherscan.io/address/0xbe4b4fa92b6767fda2c8d1db53a286834db19638
        holdingsManager.setOperator(
            address(0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638),
            10000
        );
        vm.stopBroadcast();

        console2.log("ContractsStore address", address(elContracts));
        vm.writeFile(
            ".data/IEigenLayerContracts.txt",
            address(elContracts).toHexString()
        );

        console2.log("Vault address", address(vault));
        vm.writeFile(".data/Vault.txt", address(vault).toHexString());
        
    }
}
