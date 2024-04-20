// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import {Vault, IEigenLayerContracts} from "../src/Vault.sol";
import "./TestCoin.sol";
import {HoldingsManager} from "../src/HoldingsManager.sol";
import {IEigenLayerContracts, TestnetContracts} from "../src/EigenLayerContracts.sol";


contract AssetManagerTest is Test {
    Vault public vault;
    TestCoin public rewardsToken;
    TestCoin public liquidStakedToken;

    function setUp() public {
        vm.startPrank(msg.sender);
        
        rewardsToken = new TestCoin("AVS1 Rewards Token", "AVS1");
        rewardsToken.mint(msg.sender, 100);

        liquidStakedToken = new TestCoin("Liquid Staked ETH", "lsETH");
        liquidStakedToken.mint(msg.sender, 100);

        IEigenLayerContracts elContracts = new TestnetContracts();
        HoldingsManager holdingsManager = new HoldingsManager(address(msg.sender));
        vault = new Vault(liquidStakedToken, elContracts, holdingsManager);
    }

    function test_ERC20UnderlyingAsset() public {
        require(vault.asset() == address(liquidStakedToken));
    }

    function test_deposit() public {
        liquidStakedToken.approve(address(vault), 100);
        vault.deposit(10, msg.sender);
        assertEq(vault.balanceOf(msg.sender), 10);
        assertEq(liquidStakedToken.balanceOf(msg.sender), 100 - 10);
        assertEq(vault.totalDeposited(), 10);
    }

    function test_minting() public {
        assertEq(liquidStakedToken.balanceOf(msg.sender), 100);
        assertEq(rewardsToken.balanceOf(msg.sender), 100);
    }


}
