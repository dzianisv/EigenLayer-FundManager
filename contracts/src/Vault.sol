// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import {IEigenLayerContracts} from "./EigenLayerContracts.sol";
import "./HoldingsManager.sol";
import "./MyOperator.sol";


contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager holdingsManager;
    ERC20 underlyingToken;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    
    uint256 private _totalDepositedTokens;
    EnumerableMap.AddressToUintMap private _stakedTokensPortfolio; // Map that represents current stake porfolio: MyOperatorAddress:AssetTokensStaked

    constructor(
        IERC20Metadata _underlyingAsset,
        HoldingsManager _holdingsManager
    )
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked(_underlyingAsset.symbol(), "Shares"))
        )
    {
        holdingsManager = _holdingsManager;
        underlyingToken = ERC20(address(_underlyingAsset));
    }

    function totalDeposited() public view returns (uint256) {
        return _totalDepositedTokens;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
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
        _redistribute();
        return deposited;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256) {
        return super.mint(shares, receiver);
    }

    function _stake(MyOperator operator, uint256 amount) private {
        operator.delegate();
        underlyingToken.approve(address(operator), amount);
        SafeERC20.safeTransfer(underlyingToken, address(operator), amount);
        operator.stake(amount);
    }

    function _unstake(MyOperator operator, uint256 amount) private {
        operator.unstake(amount);
    }

    function _redistribute() private {
        (address[] memory operators, uint256[] memory targetStakesBps) = holdingsManager.getAllOperatorStakes();
        uint256 totalAssets = this.totalAssets();  // Total assets managed by the vault

        // Iterate through the portfolio to adjust or remove stakes
        for (uint i = 0; i < _stakedTokensPortfolio.length(); i++) {
            (address operator, uint256 currentStake) = _stakedTokensPortfolio.at(i);
            MyOperator myOperator = MyOperator(operator);
            uint256 targetStake = _calculateTargetStake(operator, totalAssets);

            if (targetStake > currentStake) {
                uint256 amountToStake = targetStake - currentStake;
                _stake(myOperator, amountToStake);
                _stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio map to reflect the new stake
            } else if (currentStake > targetStake) {
                uint256 amountToUnStake = currentStake - targetStake;
                _unstake(myOperator, amountToUnStake);
                if (targetStake == 0) {
                    _stakedTokensPortfolio.remove(operator);  // Remove operator from portfolio if no longer needed
                } else {
                    _stakedTokensPortfolio.set(operator, targetStake);  // Update the portfolio
                }
            }
        }

        // Handle any new operators not already in the portfolio
        for (uint j = 0; j < operators.length; j++) {
            address operator = operators[j];
            MyOperator myOperator = MyOperator(operator);
            uint256 targetStake = totalAssets * targetStakesBps[j] / 10000;
            if (!_stakedTokensPortfolio.contains(operator) && targetStake > 0) {
                _stake(myOperator, targetStake);
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
}
