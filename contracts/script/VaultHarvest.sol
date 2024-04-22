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

contract HarvestRewards is Script {
    using AddressLibrary for string;

    function setUp() public {}

    function run() public {
        Vault vault = LocalContractsStore.getVault(vm);

        vm.startBroadcast();
        OperatorInfo[] memory operators = vault.holdingsManager().getOperatorsInfo();
        address rewardsTokenAddress = address(LocalContractsStore.getContractsDirectory(vm).rewardsToken());
        console2.log("rewardsToken", rewardsTokenAddress);

        for (uint i  = 0; i < operators.length; i++) {
            MintableToken(rewardsTokenAddress).mint(operators[i].staker, 10);
        }

        vault.claimAndReinvest();

        vm.stopBroadcast();
    }
}