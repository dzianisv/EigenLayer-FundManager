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
import "./ContractsStore.sol";
import "../test/Exchange.sol";

contract DeployRewardsToken is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MintableToken token = new MintableToken(
            "EigenLayer Rewards Coin",
            "AVS1"
        );
        token.mint(msg.sender, 100);
        vm.stopBroadcast();

        console2.log("Contract address", address(token));
        vm.writeFile(".data/RewardsToken.txt", address(token).toHexString());
    }
}

contract DeployUSDC is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        MintableToken token = new MintableToken("USD Coin", "USDC");
        vm.stopBroadcast();

        console2.log("Contract address", address(token));
        vm.writeFile(".data/USDC.txt", address(token).toHexString());
    }
}

contract DeployExchange is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        MintableToken rewardsToken = ContractsStore.getRewardsToken(vm);
        ERC20 liquidStakingToken = ContractsStore.getETHxToken(vm);

        vm.startBroadcast();
        uint256 assets = liquidStakingToken.decimals()/100;
        IExchange token = new TestExchange();
        liquidStakingToken.transfer(address(token), assets);
        rewardsToken.mint(address(token), assets);

        vm.stopBroadcast();

        console2.log("Contract address", address(token));
        vm.writeFile(".data/Exchange.txt", address(token).toHexString());
    }
}
