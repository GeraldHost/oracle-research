// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

contract TestTokenAmounts {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    function amounts(
        int24 tick,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256, uint256) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    function price(int24 tick) external view returns (uint256) {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        uint256 twapX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96);
        return FullMath.mulDiv(1e18, twapX96, Q96);
    }
}
