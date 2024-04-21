// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {Script, console2, VmSafe} from "forge-std/Script.sol";

import "../src/Vault.sol";
import "../test/MintableToken.sol";
import "../src/HoldingsManager.sol";
import "../src/EigenLayerContracts.sol";
import "./AddressLibrary.sol";

library ContractsStore {
    using AddressLibrary for string;
    using AddressLibrary for address;

    function getEigenLayerContracts(VmSafe vm) external view returns (IEigenLayerContracts) {
        return IEigenLayerContracts(vm.readFile(".data/EigenLayerContracts.txt").toAddress());
    }

    function getVault(VmSafe vm) external view returns (Vault) {
        return Vault(vm.readFile(".data/Vault.txt").toAddress());
    }

    function getMyOperator(VmSafe vm) external view returns (MyOperator) {
        return MyOperator(vm.readFile(".data/MyOperator.txt").toAddress());
    }   

    function getETHxToken(VmSafe /* vm */) external pure returns (ERC20) {
        return ERC20(address(0xB4F5fc289a778B80392b86fa70A7111E5bE0F859));
    }

    function getOperatorAddress(VmSafe /* vm */) external pure returns (address) {
        // Coinbase Operator: https://holesky.etherscan.io/address/0xbe4b4fa92b6767fda2c8d1db53a286834db19638
        return address(0xbE4B4Fa92b6767FDa2C8D1db53A286834dB19638);
    }

    function getRewardsToken(VmSafe vm) external view returns (MintableToken) {
        return MintableToken(vm.readFile(".data/RewardsToken.txt").toAddress());
    }

    function getExchnage(VmSafe vm) external view returns (IExchange) {
        return IExchange(vm.readFile(".data/Exchange.txt").toAddress());
    }
    
}