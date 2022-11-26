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

interface IOracle {
    function latestAnswer() external view returns (uint256);
}

/// @author GeraldHost
/// @title UniswapV3Oracle
/// @dev Uniswap V3 oracle to get the price of the underlying tokens and the position
contract UniswapV3Oracle {
    using PositionValue for INonfungiblePositionManager;

    /// +-------------------------------------------------------------------------
    /// | Storage
    /// +-------------------------------------------------------------------------

    /// @dev scale constant
    uint256 internal constant SCALE = 1e18;

    /// @dev price anchor period for getting the TWAP
    uint32 public constant anchorPeriod = 30 minutes;

    /// @dev The Uniswap NFT contract
    INonfungiblePositionManager internal NFT = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// @dev ETH:USD chain link data feed
    IOracle public ethOracle = IOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /// @dev WETH
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// +-------------------------------------------------------------------------
    /// | Core functions
    /// +-------------------------------------------------------------------------

    /// @dev Get token addresses for this position
    /// @param positionId The uniswap position ID
    /// @return The two token addresses for token0 and token1
    function getTokens(uint256 positionId) external view returns (address, address) {
        (, , address token0, address token1, , , , , , , , ) = NFT.positions(positionId);
        return (token0, token1);
    }

    /// @dev Get token amounts for this position
    /// @param positionId The uniswap position ID
    /// @return The two amounts for token0 and token1
    function getAmounts(uint256 positionId) public view returns (uint256, uint256) {
        address pool = _poolFromPositionId(positionId);
        (uint160 sqrtRatioX96, , , , , , ) = IUniswapV3Pool(pool).slot0();
        return NFT.total(positionId, sqrtRatioX96);
    }

    /// @dev Get the price of one of the pool tokens
    /// @param pool The uniswap v3 pool address
    /// @param zeroToOne The token to get the price for (zeroToOne=true if in token1)
    function getTokenPrice(address pool, bool zeroToOne) external view returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);
        return _getPriceFromTick(zeroToOne, SCALE, tickCumulatives);
    }

    /// @dev Get the price of the position
    /// @param positionId The uniswap position ID
    /// @return The price of the position
    function getPrice(uint256 positionId) external view returns (uint256) {
        (, , , , , int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = NFT.positions(positionId);

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        // uint256 priceToken1 = ....
        (, uint256 amount1) = getAmounts(positionId);
        uint128 liquidityForAmount1 = LiquidityAmounts.getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);

        // return (priceToken1 * amount1 / uint256(liquidityForAmount1)) * uint256(liquidity)

        return uint256(liquidity);
    }

    /// +-------------------------------------------------------------------------
    /// | Internal functions
    /// +-------------------------------------------------------------------------

    /// @dev Get the price from a tick
    /// @param zeroToOne The token to get the price for (zeroToOne=true if in token1)
    /// @param scale Scale e.g 1e18 (1e6 for USDC)
    /// @param tickCumulatives Cumulative ticks
    function _getPriceFromTick(
        bool zeroToOne,
        uint256 scale,
        int56[] memory tickCumulatives
    ) internal view returns (uint256) {
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

    /// @dev Get the pool address from position ID
    /// @param positionId The position ID
    /// @return The pool address
    function _poolFromPositionId(uint256 positionId) internal view returns (address) {
        (, , address token0, address token1, uint24 fee, , , , , , , ) = NFT.positions(positionId);
        return
            PoolAddress.computeAddress(NFT.factory(), PoolAddress.PoolKey({token0: token0, token1: token1, fee: fee}));
    }
}
