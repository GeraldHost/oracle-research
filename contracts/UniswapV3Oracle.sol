// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <0.8.0;

import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {PositionValue} from "@uniswap/v3-periphery/contracts/libraries/PositionValue.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

library FixedPoint96 {
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

contract UniswapV3Oracle {
    using PositionValue for INonfungiblePositionManager;

    uint256 internal constant SCALE = 1e18;
    uint32 public constant anchorPeriod = 30 minutes;
    INonfungiblePositionManager internal NFT = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function getTokens(uint256 positionId) external view returns (address, address) {
        (,, address token0, address token1,,,,,,,,) = NFT.positions(positionId);
        return (token0, token1);
    }

    function getAmounts(uint256 positionId) external view returns (uint256, uint256) {
        (,, address token0, address token1, uint24 fee,,,,,,,) = NFT.positions(positionId);
        address pool =
            PoolAddress.computeAddress(NFT.factory(), PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee}));

        (uint160 sqrtRatioX96,,,,,,) = IUniswapV3Pool(pool).slot0();
        return NFT.total(positionId, sqrtRatioX96);
    }

    function getPrice(address pool, bool zeroToOne) external view returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        return _getPriceFromTick(zeroToOne, SCALE, tickCumulatives);
    }

    function _getPriceFromTick(bool zeroToOne, uint256 scale, int56[] memory tickCumulatives)
        internal
        view
        returns (uint256)
    {
        int56 anchorPeriodI = int56(uint56(anchorPeriod));
        int56 timeWeightedAverageTickS56 = (tickCumulatives[1] - tickCumulatives[0]) / anchorPeriodI;

        int24 timeWeightedAverageTick = int24(timeWeightedAverageTickS56);

        if (!zeroToOne) {
            timeWeightedAverageTick = -timeWeightedAverageTick;
        }

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        uint256 twapX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);

        return FullMath.mulDiv(scale, twapX96, FixedPoint96.Q96);
    }
}
