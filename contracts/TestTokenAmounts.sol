// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

contract TestTokenAmounts {
    function test(uint256 tick, uint256 tickLower, uint256 tickUpper, uint256 liquidity)
        external
        view
        returns (uint256, uint256)
    {
        uint256 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
        return LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96, TickMath.getSqrtRatioAtTick(tickLower), TickMath.getSqrtRatioAtTick(tickUpper), liquidity
        );
    }
}
