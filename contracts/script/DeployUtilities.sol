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

contract DeployRewardsToken is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        TestCoin rewardsToken = new TestCoin("AVS1 Rewards Token", "AVS1");
        rewardsToken.mint(msg.sender, 100);
        console2.log("Rewards token address", address(rewardsToken));
        vm.stopBroadcast();
    }
}

contract DeployEingenLayerContracts is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        IEigenLayerContracts elContracts = new TestnetContracts();
        console2.log("EingenLayerContracts address", address(elContracts));
        vm.stopBroadcast();
    }
}