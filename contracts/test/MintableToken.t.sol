// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Test, console2} from "forge-std/Test.sol";
import "./MintableToken.sol";


contract MintableTokenTest is Test {

    function setUp() public {

    }

    function test_allowance() public {
        MintableToken coin = new MintableToken("MintableToken", "TCN");
        uint amount = 1000;

        console2.log(coin.symbol());

        coin.mint(msg.sender, amount);
        require(coin.totalSupply() == amount, "invalid total supply");
        require(coin.balanceOf(msg.sender) == amount, "invalid balance");

        address spender = address(0x1);
        vm.prank(msg.sender);
        coin.approve(spender, amount);
        vm.prank(msg.sender);
        uint256 allowance = coin.allowance(msg.sender, spender);
        require(allowance > 0, "allowance is not set");
    }
}
