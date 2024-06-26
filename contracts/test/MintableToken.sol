
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableToken is ERC20 {
    constructor(string memory name, string memory symbol)  ERC20(name, symbol) {}

    function mint(address _recepient, uint _amount) public {
        _mint(_recepient, _amount);
    }
}
