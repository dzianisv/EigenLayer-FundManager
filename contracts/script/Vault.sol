// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../src/Vault.sol";

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Vault, IEgeneLayerConstracts} from "../src/Vault.sol";
import "../test/TestCoin.sol";
import {HoldingsManager} from "../src/HoldingsManager.sol";
import {IEgeneLayerConstracts, TestnetContracts} from "../src/EigenLayerContracts.sol";


contract VaultScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        TestCoin rewardsToken = new TestCoin("AVS1 Rewards Token", "AVS1");
        rewardsToken.mint(msg.sender, 100);

        // ETHx @ Honesky: https://holesky.etherscan.io/token/
        ERC20 liquidStakedToken = ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));

        IEgeneLayerConstracts elContracts = new TestnetContracts();
        HoldingsManager holdingsManager = new HoldingsManager(address(msg.sender));
        Vault vault = new Vault(liquidStakedToken, elContracts, holdingsManager);

        vm.stopBroadcast();
    }
}
