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
    IExchange exchange;
    MintableToken public tokenA;
    MintableToken public tokenB;

    function setUp() public {
        vm.startPrank(msg.sender);
        
        exchange = new TestExchange();
        tokenA = new MintableToken("Token A", "A");
        tokenB = new MintableToken("Token B", "B");

        tokenA.mint(address(exchange), 1000);
        tokenB.mint(address(exchange), 1000);  

        
    }

    function test_swap() public {
        tokenA.mint(msg.sender, 10);     
        assertEq(tokenA.balanceOf(msg.sender), 10);
        assertEq(tokenB.balanceOf(msg.sender), 0);

        tokenA.approve(address(exchange), 10);
        exchange.swap(msg.sender, msg.sender, tokenA, tokenB, 10);
        assertEq(tokenA.balanceOf(msg.sender), 0);
        assertEq(tokenB.balanceOf(msg.sender), 10);
        assertEq(tokenA.balanceOf(address(exchange)), 1000+10);
        assertEq(tokenB.balanceOf(address(exchange)), 1000-10);
    }
}