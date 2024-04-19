
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract TestCoin is ERC20Upgradeable {
    constructor()  {
        initialize();
    }

    function initialize() public initializer {
        __ERC20_init("Test Stable Coin", "tUSD");
    }

    function mint(address _recepient, uint _amount) public {
        _mint(_recepient, _amount);
    }
}
