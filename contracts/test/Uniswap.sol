// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV2Mock {
    // To store liquidity info for each token pair
    struct LiquidityInfo {
        uint256 liquidityTokens; // Total liquidity tokens
        address tokenA;
        address tokenB;
        uint256 reserveA;
        uint256 reserveB;
    }

    mapping(address => mapping(address => LiquidityInfo)) public liquidityPools;

    // Add liquidity to the pool for a token pair with specified reserves
    function addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB) public {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        LiquidityInfo storage pool = liquidityPools[tokenA][tokenB];
        if (pool.liquidityTokens == 0) {
            // Initialize pool if it's the first liquidity added
            pool.tokenA = tokenA;
            pool.tokenB = tokenB;
        }

        pool.reserveA += amountA;
        pool.reserveB += amountB;

        // Calculate liquidity tokens to mint
        uint256 liquidityMinted = sqrt(amountA * amountB);
        pool.liquidityTokens += liquidityMinted;

        // In real scenario, we would mint liquidity tokens to the LP (liquidity provider)
        // For mock, we just track the amount in the struct
    }

    // Simple utility function to calculate square root
    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Get reserves for a token pair
    function getReserves(address tokenA, address tokenB) public view returns (uint256 reserveA, uint256 reserveB) {
        LiquidityInfo storage pool = liquidityPools[tokenA][tokenB];
        return (pool.reserveA, pool.reserveB);
    }
}