// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";

interface IEgeneLayerConstracts {
    function delegationManager() external view returns (DelegationManager);
    function strategyManager() external view returns (StrategyManager);
}

// Testnet deployments https://github.com/Layr-Labs/eigenlayer-contracts?tab=readme-ov-file#current-testnet-deployment
contract TestnetContracts is IEgeneLayerConstracts {
    function delegationManager() external view returns (DelegationManager) 
    {
        return DelegationManager(address(0xA44151489861Fe9e3055d95adC98FbD462B948e7));
    }

    function strategyManager() external view returns (StrategyManager)
    {
        return StrategyManager(address(0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6));
    }
}
