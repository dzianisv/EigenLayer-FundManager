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

    Vault vault;
    ERC20 underlyingToken;
    DelegationManager delegationManager;
    StrategyManager strategyManager;
    IStrategy strategy; // single strategy for now

    modifier onlyVault() {
        require(msg.sender == address(vault), "Caller is not Vault contract");
        _;
    }

    modifier onlyDelegated() {
        require(delegationManager.delegatedTo(address(this)) == operator, "Not deletgated to this operator");
        _;
    }

    constructor(
        address _operator,
        Vault _vault,
        IEigenLayerContracts _eigenLayerContracts
    ) {
        vault = _vault;
        operator = _operator;
        delegationManager = _eigenLayerContracts.delegationManager();
        strategyManager = _eigenLayerContracts.strategyManager();
        underlyingToken = ERC20(_vault.asset());
        strategy = _eigenLayerContracts.strategy(underlyingToken.symbol());
    }

    function delegate() external onlyVault {
        if (delegationManager.delegatedTo(address(this)) != operator) {
            _delegate();
        }
    }

    function stake(uint256 amount) external onlyVault onlyDelegated {
        _depositIntoEigenLayer(amount);
    }

    function unstake(uint256 amount) external onlyVault onlyDelegated {
        _withdrawFromEigenLayer(amount);
    }

    function _delegate() private {
        ISignatureUtils.SignatureWithExpiry memory emptySig;
        delegationManager.delegateTo(operator, emptySig, bytes32(0));
    }

    function _depositIntoEigenLayer(uint256 amount) private { 
        underlyingToken.approve(address(strategyManager), amount); 
        strategyManager.depositIntoStrategy(strategy, underlyingToken, amount);
    }

    function _withdrawFromEigenLayer(uint256 amount) private {
        address withdrawer = address(vault);
        address staker = address(this);
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