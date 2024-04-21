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
    IEigenLayerContracts eigenLayerContracts;

    using EnumerableMap for EnumerableMap.AddressToUintMap;
    
    uint256 private _totalDepositedTokens;
    EnumerableMap.AddressToUintMap private _stakedTokensPortfolio; // Map that represents current stake porfolio: MymyOperatorAddress:AssetTokensStaked

    constructor(
        IERC20Metadata _underlyingAsset,
        HoldingsManager _holdingsManager,
        IEigenLayerContracts _eigenLayerContracts
    )
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked(_underlyingAsset.symbol(), "Shares"))
        )
    {
        holdingsManager = _holdingsManager;
        eigenLayerContracts = _eigenLayerContracts;
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

    function _stake(MyOperator myOperator, uint256 amount) private {
        ERC20 asset = ERC20(asset());
        // TODO: this is not safe/non-revertable, but this is quick hack to make this work for a demo
        // because msg.sender here is a Staker user, but we need an approval of the current smart-contract address
        // to use asset.approve() and asset.transferFrom()
        asset.transferFrom(address(this), address(myOperator), amount);
        myOperator.stake(asset, amount, eigenLayerContracts);
    }

    function _unstake(MyOperator operator, uint256 amount) private {
        operator.unstake(ERC20(asset()), amount, eigenLayerContracts);
    }

    function _redistribute() private {
        (MyOperator[] memory operators, uint256[] memory targetStakesBps) = holdingsManager.getAllOperatorStakes();

        // Iterate through the portfolio to adjust or remove stakes
        for (uint i = 0; i < _stakedTokensPortfolio.length(); i++) {
            (address myOperatorAddress, uint256 currentStake) = _stakedTokensPortfolio.at(i);

            address operatorAddress = MyOperator(myOperatorAddress).operator();
            uint256 targetStake = _calculateTargetStake(operatorAddress);

            if (targetStake > currentStake) {
                uint256 amountToStake = targetStake - currentStake;
                _stake(MyOperator(myOperatorAddress), amountToStake);
                _stakedTokensPortfolio.set(myOperatorAddress, targetStake);  // Update the portfolio map to reflect the new stake
            } else if (currentStake > targetStake) {
                uint256 amountToUnStake = currentStake - targetStake;
                _unstake(MyOperator(myOperatorAddress), amountToUnStake);
                if (targetStake == 0) {
                    _stakedTokensPortfolio.remove(myOperatorAddress);  // Remove operator from portfolio if no longer needed
                } else {
                    _stakedTokensPortfolio.set(myOperatorAddress, targetStake);  // Update the portfolio
                }
            }
        }

        // Handle any new operators not already in the portfolio
        for (uint j = 0; j < operators.length; j++) {
            MyOperator myOperator = operators[j];
            
            uint256 targetStake = totalDeposited() * targetStakesBps[j] / 10000;
            if (!_stakedTokensPortfolio.contains(address(myOperator)) && targetStake > 0) {
                _stake(myOperator, targetStake);
                _stakedTokensPortfolio.set(address(myOperator), targetStake);  // Add new operator to the portfolio
            }
        }
    }

    function _calculateTargetStake(address operatorAddress) private view returns (uint256) {
        if (holdingsManager.existsOperator(operatorAddress)) {
            return totalDeposited() * holdingsManager.getOperatorStake(operatorAddress) / 10000;
        }
        return 0;  // Return 0 if the operator is not found in the target distribution
    }
}
