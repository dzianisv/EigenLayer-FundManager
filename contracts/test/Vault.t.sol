// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";

import "../src/Vault.sol";
import "./MintableToken.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "../src/MyOperator.sol";
import "./Exchange.sol";

contract AssetManagerTest is Test {
    Vault public vault;
    MintableToken public rewardsToken;
    MintableToken public liquidStakedToken;

    function setUp() public {
        vm.startPrank(msg.sender);
        
        rewardsToken = new MintableToken("EigenLayer Rewards Token", "AVS1");
        rewardsToken.mint(msg.sender, 100);

        liquidStakedToken = new MintableToken("Liquid Staked ETH", "lsETH");
        liquidStakedToken.mint(msg.sender, 100);

        IEigenLayerContracts elContracts = new TestContracts(rewardsToken);
        HoldingsManager holdingsManager = new HoldingsManager(address(msg.sender), elContracts);
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
        assertEq(vault.totalAssets(), 10);
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

    function test_rewardsYield() public {
        HoldingsManager holdingManager = vault.holdingsManager();
        
        for (uint i = 0; i < 2; i++) {
            holdingManager.setOperator(address(uint160((0x1 * (i+1)))), 100 * (i+1));
        }

        OperatorInfo[] memory operators = holdingManager.getOperatorsInfo();
        for (uint i = 0; i  < operators.length; i++) {
            uint256 rewardsAmount = 100 * (i+1);
            OperatorInfo memory operator = operators[i];
            MyOperator staker = MyOperator(operator.staker);
            console2.log("Working with staker", address(staker));

            // yeild rewards on the OperatorStaker contract
            rewardsToken.mint(operator.staker, rewardsAmount);
            // get the rewards tokens count on the Vault contract
            uint256 vaultRewardsBalance = rewardsToken.balanceOf(address(vault));
            // get the amount of the rewards tokens on the balance of the OperatorStaker contract
            assertEq(staker.rewardAvailable(), rewardsAmount);
            // claim/withdraw rewards tokens from the StakerOperator contract
            staker.rewardsClaim(address(vault), rewardsAmount / 2);
            // check that claimed rewards arived to the Vault contract
            assertEq(rewardsToken.balanceOf(address(vault)) - vaultRewardsBalance, rewardsAmount / 2);
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
