// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../src/Vault.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Vault} from "../src/Vault.sol";
import "../test/MintableToken.sol";
import {HoldingsManager} from "../src/HoldingsManager.sol";
import {IEigenLayerContracts, TestnetContracts} from "../src/EigenLayerContracts.sol";
import {MyOperator} from "../src/MyOperator.sol";
import "./AddressLibrary.sol";

contract DeployRewardsToken is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MintableToken rewardsToken = new MintableToken("AVS1 Rewards Token", "AVS1");
        rewardsToken.mint(msg.sender, 100);
        vm.stopBroadcast();

        console2.log("Rewards token address", address(rewardsToken));
        vm.writeFile('.data/RewardsToken.txt', address(rewardsToken).toHexString());
    }
}

contract DeployEingenLayerContracts is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        IEigenLayerContracts elContracts = new TestnetContracts();
        vm.stopBroadcast();

        console2.log("EingenLayerContracts address", address(elContracts));
        vm.writeFile('.data/IEigenLayerContracts.txt', address(elContracts).toHexString());
    }
}