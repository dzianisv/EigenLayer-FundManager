// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IExchange {
    function swap(address owner, address  receiver, ERC20 sourceAsset, ERC20 destinationAsset, uint256 amount) external returns (uint256);
}