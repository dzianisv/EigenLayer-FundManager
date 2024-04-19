// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Test, console2} from "forge-std/Test.sol";
import {AssetManager} from "../src/AssetManager.sol";
import "./TestCoin.sol";
import "./TestBeefyVault.sol";
import "./TestERC4626Vault.sol";

contract AssetManagerTest is Test {
    AssetManager public aManager;
    TestCoin public coin;

    function setUp() public {
        vm.startPrank(msg.sender);
        coin = new TestCoin();

        aManager = new AssetManager();
        aManager.initialize(IERC20Metadata(address(coin)));
    }

    function test_beefyVaultCRUD() public {
        IVault beefyVault1 = IVault(new TestBeefyVault(coin));
        IVault beefyVault2 = IVault(new TestBeefyVault(coin));

        IERC4626 vault1 = aManager.addBeefyVault(beefyVault1);
        IERC4626 vault2 = aManager.addBeefyVault(beefyVault2);

        aManager.removeVault(vault1);
        aManager.removeVault(vault1);
    }

    function test_userFlow() public {
        uint amount = 1000 * 10**coin.decimals();
        TestERC4626Vault[3] memory vaults;


        uint vaultsCount = 5;
        string[5] memory vaultNames = ["Whale Wading Wonderland", "Stablecoin Slip 'n Slide", "USDC Circus Splash", "Dollar Drenched Delight", "Liquid Laughter Lagoon"];
        string[5] memory vaultSymbols = ["wading", "slip", "circus", "drenched", "liquid"];

        for (uint i = 0; i < vaults.length; i++) {
            TestERC4626Vault vault = new TestERC4626Vault();
            vault.initialize(coin, vaultNames[i], vaultSymbols[i]);
            aManager.addVault(IERC4626(address(vault)));
            vaults[i] = vault;
        }

        uint256 reinvested = aManager.reinvest();
        console2.log("reinvested: ", reinvested);
        require(reinvested == vaults.length, "reinvest() failed");

        console2.log("Perfomance indexes", vaults.length);
        for (uint i = 0; i < vaults.length; i++) {
            console2.log(vaults[i].name(), aManager.getPerfomanceIndex(IERC4626(address(vaults[i]))));
        }

        coin.mint(msg.sender, amount);
        require(coin.totalSupply() == amount, "invalid total supply");
        require(coin.balanceOf(msg.sender) == amount, "invalid balance");

        coin.approve(address(aManager), amount);
        require(coin.allowance(msg.sender, address(aManager)) == amount, "allowance is not set");

        aManager.deposit(amount, msg.sender);
        require(aManager.balanceOf(msg.sender) > 0, "atUSD tokens are not received");
        require(aManager.totalAssets() == amount, "Invalid totalAssets()");

        for (uint i = 0; i < vaults.length; i++) {
            TestERC4626Vault vault = vaults[i];
            
            vault.yield(( vaults.length - i + 1 ) * 100 * 10 ** coin.decimals());
            console2.log("vault", i);
            console2.log("totalAssets()", vault.totalAssets());
            console2.log("totalSupply()", vault.totalSupply());
            console2.log("symbol()", vault.symbol());
            console2.log("name()", vault.name());
        }
        // TODO: investigate reinvestment strategy failure
        // require(aManager.reinvest() > 0, "positions redistribution failed");

        console2.log("AssetManager.totalAssets()", aManager.totalAssets());
        console2.log("AssetManager.totalSupply()", aManager.totalSupply());
        console2.log("AssetManager.balanceOf(msg.sender)", aManager.balanceOf(msg.sender));
        console2.log("TestCoin.balanceOf(AssetManager)", aManager.balanceOf(address(aManager)));

        require(aManager.totalAssets() > amount, "Underlying asset didn't yield");


        aManager.withdraw(100 + 1, msg.sender, msg.sender);
        require(coin.balanceOf(msg.sender) == 100 + 1, "not all coins were withdrawen");
    }
}
