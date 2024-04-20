// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./HoldingsManager.sol";
import {IEigenLayerContracts} from "./EigenLayerContracts.sol";


contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;
    DelegationManager delegationManager;
    StrategyManager strategyManager;
    IStrategy strategy;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    
    uint256 private _totalDepositedTokens;
    EnumerableMap.AddressToUintMap private _stakedTokensPortfolio; // Map that represents current stake porfolio: OperatorAddress:AssetTokensStaked

    constructor(
        IERC20Metadata _underlyingAsset,
        IEigenLayerContracts _eigenLayerContracts,
        HoldingsManager _holdingsManager
    )
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked("cb", _underlyingAsset.symbol()))
        )
    {
        holdingsManager = _holdingsManager;
        delegationManager = _eigenLayerContracts.delegationManager();
        strategyManager = _eigenLayerContracts.strategyManager();
        strategy = _eigenLayerContracts.strategy(_underlyingAsset.symbol());
    }

    function totalDeposited() public view returns (uint256) {
        return _totalDepositedTokens;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        // uint256 unstaked_amount = _unstake(assets);
        // return super.withdraw(unstaked_amount, receiver, owner);
        revert("withdraw function is not supported");
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override returns (uint256) {
        revert("Redeem function is not supported");
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        uint256 deposited = super.deposit(assets, receiver);
        _totalDepositedTokens += assets;
        _stake(deposited);
        return deposited;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256) {
        return super.mint(shares, receiver);
    }

    function _stake(uint256 deposited) private {
        _redistribute();
    }

    function _unstake(uint256 withdrawn) private returns (uint256) {
        _redistribute();
    }

    function _redistribute() private {
        (address[] memory operators, uint256[] memory targetStakesBps) = holdingsManager.getAllOperatorStakes();
        uint256 totalAssets = this.totalAssets();  // Total assets managed by the vault

        // Iterate through the portfolio to adjust or remove stakes
        for (uint i = 0; i < _stakedTokensPortfolio.length(); i++) {
            (address operator, uint256 currentStake) = _stakedTokensPortfolio.at(i);
            uint256 targetStake = _calculateTargetStake(operator, totalAssets);

            if (targetStake > currentStake) {
                uint256 amountToStake = targetStake - currentStake;
                _delegateTo(operator);
                _depositIntoEigenLayer(amountToStake);
                _stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio map to reflect the new stake
            } else if (currentStake > targetStake) {
                _withdrawFromEigenLayer(currentStake);
                if (targetStake == 0) {
                    _stakedTokensPortfolio.remove(operator);  // Remove operator from portfolio if no longer needed
                } else {
                    _depositIntoEigenLayer(targetStake);
                    _stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio
                }
            }
        }

        // Handle any new operators not already in the portfolio
        for (uint j = 0; j < operators.length; j++) {
            address operator = operators[j];
            uint256 targetStake = totalAssets * targetStakesBps[j] / 10000;
            if (!_stakedTokensPortfolio.contains(operator) && targetStake > 0) {
                _delegateTo(operator);
                _depositIntoEigenLayer(targetStake);
                _stakedTokensPortfolio.set(operator, targetStake);  // Add new operator to the portfolio
            }
        }
    }

    function _calculateTargetStake(address operator, uint256 totalAssets) private view returns (uint256) {
        if (holdingsManager.existsOperator(operator)) {
            return totalAssets * holdingsManager.getOperatorStake(operator) / 10000;
        }
        return 0;  // Return 0 if the operator is not found in the target distribution
    }

    /*  Called from the _stake()
        Interact with EigenLayer DelegationManager
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L392
        https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/test/integration/users/User.t.sol#L91
    */

    function _delegateTo(address operator) private {
        // Create empty data
        ISignatureUtils.SignatureWithExpiry memory approverSignatureAndExpiry;
        uint256 expiry = type(uint256).max;

        // TODO: get them from HoldingsManager?
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

        delegationManager.delegateTo(operator, approverSignatureAndExpiry, salt);
    }

    function _depositIntoEigenLayer(
        uint256 amount
    ) private {
        IERC20 underlyingToken = strategy.underlyingToken();

        // deposit into the strategy
        approve(address(strategyManager), amount);
        strategyManager.depositIntoStrategy(strategy, underlyingToken, amount);
    }

    /*
        Called from _unstake()
        Interacts with EigenLayer DelegationManager
        Check out 
    */
    function _withdrawFromEigenLayer(uint256 share) private {
        address operator = delegationManager.delegatedTo(address(this));
        address withdrawer = address(this);
        uint nonce = delegationManager.cumulativeWithdrawalsQueued(address(this));

        IStrategy[] memory strategies = new IStrategy[](1);
        strategies[0] = strategy;

        uint[] memory shares = new uint[](1);
        shares[0] = share;

        // Create queueWithdrawals params
        IDelegationManager.QueuedWithdrawalParams[] memory params = new IDelegationManager.QueuedWithdrawalParams[](1);
        params[0] = IDelegationManager.QueuedWithdrawalParams({
            strategies: strategies,
            shares: shares,
            withdrawer: withdrawer
        });

        // Create Withdrawal struct using same info
        IDelegationManager.Withdrawal[] memory withdrawals = new IDelegationManager.Withdrawal[](1);
        withdrawals[0] = IDelegationManager.Withdrawal({
            staker: address(this),
            delegatedTo: operator,
            withdrawer: withdrawer,
            nonce: nonce,
            startBlock: uint32(block.number),
            strategies: strategies,
            shares: shares
        });

        delegationManager.queueWithdrawals(params);
    }
}
