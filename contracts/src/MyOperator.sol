// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "eigenlayer-contracts/src/contracts/core/DelegationManager.sol";
import "eigenlayer-contracts/src/contracts/core/StrategyManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IDelegationManager.sol";
import "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";

import {IEigenLayerContracts} from "./EigenLayerContracts.sol";
import "./Vault.sol";

contract MyOperator {
    address public operator;


    // modifier onlyVault() {
    //     require(msg.sender == address(vault), "Caller is not Vault contract");
    //     _;
    // }

    // modifier onlyDelegated() {
    //     require(delegationManager.delegatedTo(address(this)) == operator, "Not deletgated to this operator");
    //     _;
    // }

    constructor(
        address _operator
    ) {
        operator = _operator;
    }

    function stake(ERC20 token, uint256 amount, IEigenLayerContracts eigenLayerContracts) external { 
        _depositToEigenLayer(token, amount, eigenLayerContracts);
        
        if (!eigenLayerContracts.delegationManager().isDelegated(address(this))) {
            _delegateToEigenLayer(eigenLayerContracts);
        }
    }

    function _depositToEigenLayer(ERC20 token, uint256 amount, IEigenLayerContracts eigenLayerContracts) private { 
        IStrategy strategy = eigenLayerContracts.strategy(token.symbol());
        IStrategyManager strategyManager = eigenLayerContracts.strategyManager();
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(strategyManager), amount); 
        strategyManager.depositIntoStrategy(strategy, token, amount);
    }

    function _delegateToEigenLayer(IEigenLayerContracts eigenLayerContracts) private {
        ISignatureUtils.SignatureWithExpiry memory emptySig;
        eigenLayerContracts.delegationManager().delegateTo(operator, emptySig, bytes32(0));
    }

    function unstake(ERC20 token, uint256 amount, IEigenLayerContracts eigenLayerContracts) external {
        _withdraw(token, amount, eigenLayerContracts);
    }

    function _withdraw(ERC20 token, uint256 amount, IEigenLayerContracts eigenLayerContracts) private {
        address withdrawer = address(msg.sender); //TODO: double check if this works
        address staker = address(this);

        IDelegationManager delegationManager = eigenLayerContracts.delegationManager();
        IStrategy strategy = eigenLayerContracts.strategy(token.symbol());

        uint nonce = delegationManager.cumulativeWithdrawalsQueued(staker);

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = strategy;

        uint256[] memory shares = new uint256[](1);
        shares[0] = strategy.underlyingToSharesView(amount);

        // Create queueWithdrawals params
        IDelegationManager.QueuedWithdrawalParams[] memory params = new IDelegationManager.QueuedWithdrawalParams[](1);
        params[0] = IDelegationManager.QueuedWithdrawalParams({
            strategies: strategies,
            shares: shares,
            withdrawer: withdrawer
        });

        delegationManager.queueWithdrawals(params);

        // Create Withdrawal struct using same info
        IDelegationManager.Withdrawal memory withdrawal = IDelegationManager.Withdrawal({
            staker: staker,
            delegatedTo: operator,
            withdrawer: withdrawer,
            nonce: nonce,
            startBlock: uint32(block.number),
            strategies: strategies,
            shares: shares
        });

        IERC20[] memory tokens = new IERC20[](1);
        tokens[0] = strategy.underlyingToken();

        // TODO: need to wait for blocks
        delegationManager.completeQueuedWithdrawal(withdrawal, tokens, 0, true);
    }
}