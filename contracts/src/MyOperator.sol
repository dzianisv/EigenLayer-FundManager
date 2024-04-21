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
    IEigenLayerContracts eigenLayerContracts;

    // modifier onlyVault() {
    //     require(msg.sender == address(vault), "Caller is not Vault contract");
    //     _;
    // }

    // modifier onlyDelegated() {
    //     require(delegationManager.delegatedTo(address(this)) == operator, "Not deletgated to this operator");
    //     _;
    // }

    constructor(
        address _operator, 
        IEigenLayerContracts _eigenLayerContracts
    ) {
        operator = _operator;
        eigenLayerContracts = _eigenLayerContracts;
    }

    // TODO: restrict usage to the vault
    function stake(ERC20 token, uint256 amount) external { 
        _depositToEigenLayer(token, amount);
        
        if (!eigenLayerContracts.delegationManager().isDelegated(address(this))) {
            _delegateToEigenLayer();
        }
    }

    function _depositToEigenLayer(ERC20 token, uint256 amount) private { 
        IStrategy strategy = eigenLayerContracts.strategy(token.symbol());
        IStrategyManager strategyManager = eigenLayerContracts.strategyManager();
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(strategyManager), amount); 
        strategyManager.depositIntoStrategy(strategy, token, amount);
    }

    function _delegateToEigenLayer() private {
        ISignatureUtils.SignatureWithExpiry memory emptySig;
        eigenLayerContracts.delegationManager().delegateTo(operator, emptySig, bytes32(0));
    }

    // TODO: restrict usage to the vault
    function unstake(ERC20 token, uint256 amount) external {
        _withdraw(token, amount);
    }

    function _withdraw(ERC20 token, uint256 amount) private {
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

    function getRewards(uint256 deposited) public view returns (uint256) {
        (IStrategy[] memory strategies, uint256[] memory shares) = eigenLayerContracts.delegationManager().getDelegatableShares(operator);

        uint256 amount = 0;
        for (uint j = 0; j < strategies.length; j++) {
            amount += strategies[j].sharesToUnderlyingView(shares[j]);
        }

        uint256 reward = 0;
        if (amount > deposited) {
            reward = amount - deposited;
        }
        return reward;
    }

    //TODO: ⚠️ rewards simulation function, has to be removed in production
    function rewardsClaim(address receiver, uint256 amount) public returns (uint256) {
        eigenLayerContracts.rewardsToken().transfer(receiver, amount);
        return amount;
    }

    //TODO: ⚠️ rewards simulation function, has to be removed in production
    function rewardAvailable() public view returns (uint256) {
        return eigenLayerContracts.rewardsToken().balanceOf(address(this));
    }

    function rewardsAsset() public view returns (ERC20) {
        return eigenLayerContracts.rewardsToken();
    }
}