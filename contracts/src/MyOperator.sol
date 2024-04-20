// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";

import {IEigenLayerContracts} from "./EigenLayerContracts.sol";

contract MyOperator {
    address public operatorAddress;

    constructor(address _operator) {
        operatorAddress = _operator;
    }

    function stake(
        uint256 amount, 
        IERC20Metadata token,
        IEigenLayerContracts eigenLayerContracts
    ) public {
        token.transferFrom(msg.sender, address(this), amount);

        DelegationManager delegationManager = eigenLayerContracts.delegationManager();
        StrategyManager strategyManager = eigenLayerContracts.strategyManager();
        IStrategy strategy = eigenLayerContracts.strategy(token.symbol());

        IERC20 underlyingToken = strategy.underlyingToken();
        require(address(token) == address(underlyingToken), "EigenLayer IStrategy doesn't match to the token");

        //deposit into the strategy
        strategyManager.depositIntoStrategy(strategy, underlyingToken, amount);

        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry;
        uint256 expiry = type(uint256).max;

        //TODO: get them from HoldingsManager?
        bytes memory approverSignature; 
        bytes32 approverSalt = 0x0; 

        // Get signature
        if (approverSignature.length > 0) {
            // Get signature
            approverSignatureAndExpiry.expiry = expiry;
            approverSignatureAndExpiry.signature = approverSignature; // use the provided signature
        } else {
            // Use empty signature
            approverSignatureAndExpiry = ISignatureUtils.SignatureWithExpiry({expiry: expiry, signature: ""});
        }
        // Use provided salt if it's not zero, otherwise use zero salt
        bytes32 salt = approverSalt != bytes32(0) ? approverSalt : bytes32(0);
        // Delegate to the operator
        delegationManager.delegateTo(operatorAddress, approverSignatureAndExpiry, salt);
    }
}