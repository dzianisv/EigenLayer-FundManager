// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";

interface IEigenLayerContracts {
    function delegationManager() external view returns (DelegationManager);
    function strategyManager() external view returns (StrategyManager);
    function strategy(string memory tokenSymbol) external view returns (IStrategy);
}

// Testnet deployments https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment
contract TestnetContracts is IEigenLayerContracts {

    function delegationManager() external view returns (DelegationManager) {
        return DelegationManager(address(0xA44151489861Fe9e3055d95adC98FbD462B948e7));
    }

    function strategyManager() external view returns (StrategyManager) {
        return StrategyManager(address(0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6));
    }

    function strategy(string memory tokenSymbol) external view returns (IStrategy) {
        if (_compareTokenSymbol(tokenSymbol, "stETH")) {
            return IStrategy(address(0x7D704507b76571a51d9caE8AdDAbBFd0ba0e63d3));
        } else if (_compareTokenSymbol(tokenSymbol, "rETH")) {
            return IStrategy(address(0x3A8fBdf9e77DFc25d09741f51d3E181b25d0c4E0));
        } else if (_compareTokenSymbol(tokenSymbol, "WETH")) {
            return IStrategy(address(0x80528D6e9A2BAbFc766965E0E26d5aB08D9CFaF9));
        } else if (_compareTokenSymbol(tokenSymbol, "lsETH")) {
            return IStrategy(address(0x05037A81BD7B4C9E0F7B430f1F2A22c31a2FD943));
        } else if (_compareTokenSymbol(tokenSymbol, "sfrxETH")) {
            return IStrategy(address(0x9281ff96637710Cd9A5CAcce9c6FAD8C9F54631c));
        } else if (_compareTokenSymbol(tokenSymbol, "ETHx")) {
            return IStrategy(address(0x31B6F59e1627cEfC9fA174aD03859fC337666af7));
        } else if (_compareTokenSymbol(tokenSymbol, "osETH")) {
            return IStrategy(address(0x46281E3B7fDcACdBa44CADf069a94a588Fd4C6Ef));
        } else if (_compareTokenSymbol(tokenSymbol, "cbETH")) {
            return IStrategy(address(0x70EB4D3c164a6B4A5f908D4FBb5a9cAfFb66bAB6));
        } else if (_compareTokenSymbol(tokenSymbol, "mETH")) {
            return IStrategy(address(0xaccc5A86732BE85b5012e8614AF237801636F8e5));
        } else if (_compareTokenSymbol(tokenSymbol, "ankrETH")) {
            return IStrategy(address(0x7673a47463F80c6a3553Db9E54c8cDcd5313d0ac));
        } else {
            require(true, "Invalid token symbol");
        }
    }

    function _compareTokenSymbol(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
