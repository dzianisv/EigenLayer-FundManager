// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import "../src/Vault.sol";
import "./TestCoin.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";


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

    function test_holdingManager() public view {
        HoldingsManager holdingManager = vault.holdingsManager();
        holdingManager.setOperator(0x1, 100);
        holdingManager.setOperator(0x2, 200);

        OperatorInfo[] memory operators = holdingManager.getOperatorsInfo();
        for (uint i = 0; i  < operators.length; i++) {
            OperatorInfo memory operator = operators[i];
            console2.log(operator.operator, operator.weight);
        }

        assertEq(operators[0].operator, 0x1);
        assertEq(operators[0].weight, 100);

        assertEq(operators[1].operator, 0x2);
        assertEq(operators[1].weight, 200);
    }
}
