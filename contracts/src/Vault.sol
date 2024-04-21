// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "eigenlayer-contracts/src/contracts/interfaces/IStrategy.sol";

import "./EigenLayerContracts.sol";
import "./HoldingsManager.sol";
import "./MyOperator.sol";


struct OperatorAllocation {
    address staker;
    address operator;
    uint256 deposited;
    uint256 rewards;
}

contract Vault is ERC4626 {
    // Assuming HoldingsManager is defined elsewhere in your project
    HoldingsManager public holdingsManager;
    IEigenLayerContracts public contractsStore;


    using EnumerableMap for EnumerableMap.AddressToUintMap;

    uint256 private _totalDepositedTokens;
    EnumerableMap.AddressToUintMap private _stakedTokensPortfolio; // Map that represents current stake porfolio: MyOperatorAddress:AssetTokensStaked

    event OutOfAssets(uint256 required, uint256 available);

    constructor(
        IERC20Metadata _underlyingAsset,
        HoldingsManager _holdingsManager,
        IEigenLayerContracts _contractsStore
    )
        ERC4626(_underlyingAsset)
        ERC20(
            string(abi.encodePacked("Vault for ", _underlyingAsset.name())),
            string(abi.encodePacked(_underlyingAsset.symbol(), "Shares"))
        )
    {
        holdingsManager = _holdingsManager;
        contractsStore = _contractsStore;
    }

    function availableForTradeAssets() public view returns (uint256) {
        return ERC20(asset()).balanceOf(address(this));
    }

    function totalAssets() public view override returns (uint256) {
        return _totalDepositedTokens;
    }

    function withdraw(
        uint256 /* assets */,
        address /* receiver */,
        address /* owner */
    ) public pure override returns (uint256) {
        revert("withdraw function is not supported");
    }

    function redeem(
        uint256 /* shares */,
        address /* receiver */,
        address /* owner */
    ) public pure override returns (uint256) {
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

    function getPortfolio() public view returns (OperatorAllocation[] memory) {
        uint256 length = _stakedTokensPortfolio.length();

        OperatorAllocation[] memory allocations = new OperatorAllocation[](
            length
        );
        for (uint i = 0; i < length; i++) {
            (address staker, uint256 deposited) = _stakedTokensPortfolio.at(i);
            address operator = MyOperator(staker).operator();
            uint256 rewards = MyOperator(staker).getRewards(
                deposited
            );
            allocations[i] = OperatorAllocation({
                staker: staker,
                operator: operator,
                deposited: deposited,
                rewards: rewards
            });
        }

        return allocations;
    }

    function _stake(MyOperator myOperator, uint256 amount) private {
        ERC20 asset = ERC20(asset());
        asset.approve(address(myOperator), amount);
        myOperator.stake(asset, amount);
    }

    function _unstake(MyOperator operator, uint256 amount) private {
        operator.unstake(ERC20(asset()), amount);
    }

    function _redistribute() private {
        (
            MyOperator[] memory operators,
            uint256[] memory operatorsWeights
        ) = holdingsManager.getOperatorsWeights();

        uint256 availableForTrade = availableForTradeAssets();

        // Iterate through the portfolio to adjust or remove stakes
        for (uint i = 0; i < _stakedTokensPortfolio.length(); i++) {
            (
                address myOperatorAddress,
                uint256 currentStake
            ) = _stakedTokensPortfolio.at(i);

            address operatorAddress = MyOperator(myOperatorAddress).operator();
            uint256 targetStake = _calculateTargetStake(
                operatorAddress,
                availableForTrade
            );

            if (targetStake > currentStake) {
                uint256 amountToStake = targetStake - currentStake;
                if (availableForTradeAssets() > amountToStake) {
                    _stake(MyOperator(myOperatorAddress), amountToStake);
                    _stakedTokensPortfolio.set(myOperatorAddress, targetStake); // Update the portfolio map to reflect the new stake
                } else {
                    emit OutOfAssets(amountToStake, availableForTradeAssets());
                    break;
                }
            } else if (currentStake > targetStake) {
                //TODO: ⚠️ unstaking is not immediate action
                continue;
                /*
                uint256 amountToUnStake = currentStake - targetStake;
                _unstake(MyOperator(myOperatorAddress), amountToUnStake);
                if (targetStake == 0) {
                    _stakedTokensPortfolio.remove(myOperatorAddress); // Remove operator from portfolio if no longer needed
                } else {
                    _stakedTokensPortfolio.set(myOperatorAddress, targetStake); // Update the portfolio
                }
                */
            }
        }

        // Handle any new operators not already in the portfolio
        for (uint j = 0; j < operators.length; j++) {
            MyOperator myOperator = operators[j];

            uint256 targetStake = (availableForTrade * operatorsWeights[j]) /
                10000;
            if (
                !_stakedTokensPortfolio.contains(address(myOperator)) &&
                targetStake > 0
            ) {
                if (availableForTradeAssets() > targetStake) {
                    emit OutOfAssets(targetStake, availableForTradeAssets());
                    break;
                }

                _stake(myOperator, targetStake);
                _stakedTokensPortfolio.set(address(myOperator), targetStake); // Add new operator to the portfolio
            }
        }
    }

    function _calculateTargetStake(
        address operatorAddress,
        uint256 availableForTrade
    ) private view returns (uint256) {
        if (holdingsManager.existsOperator(operatorAddress)) {
            return (availableForTrade * holdingsManager.getOperatorWeight(operatorAddress)) / 10000;
        }
        return 0; // Return 0 if the operator is not found in the target distribution
    }

    /**
        One of the key functions that harvest rewards, swap back them to liqud-staked tokens and reinvest (re-restake) into EigenLayer operators
     */
    function claimAndReinvest() external returns (uint256) {
        OperatorInfo[] memory operators = holdingsManager.getOperatorsInfo();
        uint256 reinvested = 0;

        // iterate over operators and harvest rewards
        for (uint i = 0; i  < operators.length; i++) {
            OperatorInfo memory operator = operators[i];
            MyOperator staker = MyOperator(operator.staker);
            
            uint256 rewardsAvailable = staker.rewardAvailable();
            // ✅ harvest reward tokens from the StakerOperator contract
            staker.rewardsClaim(address(this), rewardsAvailable);

            // ✅ swap rewards token to the liqudity token and restake it again!
            ERC20 rewardsToken = staker.rewardsAsset();
            reinvested += contractsStore.exchange().swap(address(this), address(this), staker.rewardsAsset(), ERC20(asset()), rewardsToken.balanceOf(address(this)));
        }

        _redistribute();
        return reinvested;
    }


}
