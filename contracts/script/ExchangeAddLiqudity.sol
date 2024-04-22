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
import {IContractsDirectory, TestnetContracts} from "../src/ContractsDirectory.sol";
import {MyOperator} from "../src/MyOperator.sol";
import "./AddressLibrary.sol";
import "./LocalContractsStore.sol";
import "../test/Exchange.sol";

contract AddLiqudityToExchange is Script {
    using AddressLibrary for address;

    function setUp() public {}

    function run() public {
        ERC20 liquidStakingToken = LocalContractsStore.getETHxToken(vm);
        MintableToken rewardsToken = LocalContractsStore.getRewardsToken(vm);
        uint256 assets = liquidStakingToken.decimals()/10;
        IExchange token = LocalContractsStore.getExchnage(vm);

        vm.startBroadcast();
       
        liquidStakingToken.transfer(address(token), assets);
        rewardsToken.mint(address(token), assets);
        vm.stopBroadcast();
    }
}
