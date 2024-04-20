// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";


contract MyOperator {
    address operatorAddress;

    constructor(address _operator) {
        this.operatorAddress = _operator;
    }

    function stake(
        uint256 amount, 
        IERC20 token
    ) private {
        token.transferFrom(msg.sender, address(this));

        DelegationManager delegationManager = eigenLayerContracts
            .delegationManager();
        StrategyManager strategyManager = eigenLayerContracts.strategyManager();
        IStrategy strategy = eigenLayerContracts.getStrategy(vault.asset());

        IERC20 underlyingToken = strategy.underlyingToken();
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