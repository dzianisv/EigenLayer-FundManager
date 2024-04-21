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

        vm.startBroadcast();
        OperatorInfo[] memory operators = vault.holdingsManager().getOperatorsInfo();
        for (uint i  = 0; i < operators.length; i++) {
            MintableToken(address(ContractsStore.getEigenLayerContracts(vm).rewardsToken())).mint(operators[i].staker, 10);
        }

        vm.stopBroadcast();
    }
}