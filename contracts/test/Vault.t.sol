// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import "./TestCoin.sol";


contract AssetManagerTest is Test {
    Vault public vault;
    TestCoin public coin;

    function setUp() public {
        vm.startPrank(msg.sender);
        coin = new TestCoin("AVS1 Rewards Token", "AVS1");
        coin.mint(msg.sender, 100);
        vault = new Vault(coin);
    }


    function test_1() public {
        require(coin.balanceOf(msg.sender) == 100);
    }
}
