// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// USDC/ETH: 0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640
// DAI/ETH: 0x60594a405d53811d3BC4766596EFD80fd545A270

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);
}

library FixedPoint96 {
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

contract UniswapV3Oracle {
    uint256 public constant anchorPeriod = 30 minutes;
    uint256 internal constant SCALE = 1e18;

    function getPrice(address pool, bool zeroToOne) external {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        return priceFromTick(zeroToOne, SCALE, tickCumulatives);
    }

    function priceFromTick(bool zeroToOne, uint256 scale, int56[] memory tickCumulatives) public returns (uint256) {
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
