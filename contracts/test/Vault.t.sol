// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import "../src/Vault.sol";
import "./TestCoin.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "../src/MyOperator.sol";

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
        vault = new Vault(liquidStakedToken, holdingsManager, elContracts);
    }

    function test_ERC20UnderlyingAsset() public view {
        require(vault.asset() == address(liquidStakedToken));
    }

    function test_deposit() public {
        liquidStakedToken.approve(address(vault), 100);
        vault.deposit(10, msg.sender);
        assertEq(vault.balanceOf(msg.sender), 10);
        assertEq(liquidStakedToken.balanceOf(msg.sender), 100 - 10);
        assertEq(vault.totalDeposited(), 10);
    }

    function test_minting() public view {
        assertEq(liquidStakedToken.balanceOf(msg.sender), 100);
        assertEq(rewardsToken.balanceOf(msg.sender), 100);
    }

    function test_holdingManager() public {
        HoldingsManager holdingManager = vault.holdingsManager();
        
        for (uint i = 0; i < 2; i++) {
            holdingManager.setOperator(address(uint160((0x1 * (i+1)))), 100 * (i+1));
        }

        OperatorInfo[] memory operators = holdingManager.getOperatorsInfo();
        for (uint i = 0; i  < operators.length; i++) {
            OperatorInfo memory operator = operators[i];
            console2.log(operator.operator, operator.weight);
        }

        for (uint i = 0; i < 2; i++) {
            assertEq(operators[i].operator, address(uint160((0x1 * (i+1)))));
            assertEq(operators[i].weight, 100 * (i+1));
        }
    }

    function test_getPortfolio() public {
        HoldingsManager holdingManager = vault.holdingsManager();

        for (uint i = 0; i < 2; i++) {
            holdingManager.setOperator(address(uint160((0x1 * (i+1)))), 100 * (i+1));
        }
    
        OperatorAllocation[] memory portfolio = vault.getPortfolio();
        // portoflio.length is going to be 0 until _redistribute is called
        assertEq(portfolio.length, 0);
    }
        
}
