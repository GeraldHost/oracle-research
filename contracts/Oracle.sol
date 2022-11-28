// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {FixedPoint96} from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {PositionValue} from "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";
import {LiquidityAmounts} from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}

/**

amount0    amount1
liquid0    liquid1

example:   1ETH = 1200DAI
amounts:   1, 1200
liquid:    1000, 1000
vamounts:  2, 2400

x * 1000 / 2000 = 1
x = 1 / (1000 / 2000)
x = 2 

2000x * 1000 = 1 * 2000

1 * 2000 / 1000 = 2000x


1 / (32/156)
**/

contract Oracle {
    using PositionValue for INonfungiblePositionManager;

    /// +-------------------------------------------------------------------------
    /// | Storage
    /// +-------------------------------------------------------------------------

    /// @dev The Uniswap NFT contract
    INonfungiblePositionManager internal positionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// +-------------------------------------------------------------------------
    /// | Core
    /// +-------------------------------------------------------------------------

    /// @dev Get USD price of position
    function getPrice(uint256 positionId) external view returns (uint256[] memory) {
        address pool = _poolFromPositionId(positionId);

        (uint160 sqrtRatioX96, int24 tick, , , , , ) = IUniswapV3Pool(pool).slot0();

        (uint256 amount0, uint256 amount1) = positionManager.principal(positionId, sqrtRatioX96);

        uint256[] memory ret = new uint256[](10);

        {
            // Price of USDC in ETH
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);
            uint256 twapX96 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);
            ret[0] = FullMath.mulDiv(1e6, twapX96, FixedPoint96.Q96);
        }

        {
            // Price of ETH in USDC
            uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(-tick);
            uint256 twapX96 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);
            ret[1] = FullMath.mulDiv(1e18, twapX96, FixedPoint96.Q96);
        }

        {
            // amounts 
            ret[2] = amount0;
            ret[3] = amount1;
        }

        {
            // v amounts 
            ret[4] = amount1 * ret[1] / 1e18;
            ret[5] = ret[4] + amount0;
        }


        return ret;
    }

    /// +-------------------------------------------------------------------------
    /// | Internals
    /// +-------------------------------------------------------------------------

    /// @dev Get virtual amount of tokens if priced in the single
    ///      asset that has the CL oracle price
    function _getVirtualToken0Amount(
        uint160 sqrtRatioX96,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint128 liquidity
    ) internal view returns (uint256) {
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        uint128 liq0 = LiquidityAmounts.getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);

        return (amount0 * liquidity) / liq0;
    }

    /// @dev Get USD price of token
    function _getTokenPrice(address token) internal view returns (uint256) {}

    /// @dev Get the pool address from position ID
    /// @param positionId The position ID
    /// @return The pool address
    function _poolFromPositionId(uint256 positionId) internal view returns (address) {
        (, , address token0, address token1, uint24 fee, , , , , , , ) = positionManager.positions(positionId);
        return
            PoolAddress.computeAddress(
                positionManager.factory(),
                PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee})
            );
    }
}
