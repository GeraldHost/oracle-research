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

    function decimals() external view returns (uint256);
}

contract Oracle {
    using PositionValue for INonfungiblePositionManager;

    /// +-------------------------------------------------------------------------
    /// | Storage
    /// +-------------------------------------------------------------------------

    /// @dev The Uniswap NFT contract
    INonfungiblePositionManager internal constant positionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// @dev token0 chainlink USD price feed
    address public immutable token0Oracle;

    /// @dev token1 chainlink USD price feed
    address public immutable token1Oracle;

    /// @dev price anchor period for getting the TWAP
    uint32 public constant anchorPeriod = 30 minutes;

    /// @dev WAD 10 ** 18
    uint256 public constant WAD = 1e18;

    /// @dev Uniswap V3 pool
    address public immutable pool;

    /// +-------------------------------------------------------------------------
    /// | Constructor
    /// +-------------------------------------------------------------------------

    constructor(address _token0Oracle, address _token1Oracle, address _pool) {
        token0Oracle = _token0Oracle;
        token1Oracle = _token1Oracle;
        pool = _pool;
    }

    /// +-------------------------------------------------------------------------
    /// | Core
    /// +-------------------------------------------------------------------------

    function getPrice(uint256 positionId) external view returns (uint256) {
        require(_poolFromPositionId(positionId) == pool, "!pool");

        (uint160 sqrtRatioX96, int24 tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        (uint256 amount0, uint256 amount1) = positionManager.principal(positionId, sqrtRatioX96);

        uint256 token0Price = _getToken0Price();
        uint256 token1Price = _getToken1Price();

        uint256 anchorPrice = _getAnchorPrice();
        // TODO: check anchor

        return ((amount0 * token0Price) / WAD) + ((amount1 * token1Price) / WAD);
    }

    /// +-------------------------------------------------------------------------
    /// | Internals:Chainlink
    /// +-------------------------------------------------------------------------

    function _getToken0Price() internal view returns (uint256) {
        return _getTokenPrice(token0Oracle);
    }

    function _getToken1Price() internal view returns (uint256) {
        return _getTokenPrice(token1Oracle);
    }

    function _getTokenPrice(address oracle) internal view returns (uint256) {
        uint256 decimals = IChainlinkOracle(oracle).decimals();
        uint256 answer = IChainlinkOracle(oracle).latestAnswer();
        return answer * (10 ** (18 - decimals));
    }

    /// +-------------------------------------------------------------------------
    /// | Internals:Anchors
    /// +-------------------------------------------------------------------------

    function _getPoolPrice() internal view returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = anchorPeriod;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        int56 anchorPeriodI = int56(uint56(anchorPeriod));
        int56 timeWeightedAverageTickS56 = (tickCumulatives[1] - tickCumulatives[0]) / anchorPeriodI;
        int24 timeWeightedAverageTick = int24(timeWeightedAverageTickS56);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        uint256 twapX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);

        return FullMath.mulDiv(WAD, twapX96, FixedPoint96.Q96);
    }

    function _getAnchorPrice() internal view returns (uint256) {
        uint256 poolPrice = _getPoolPrice();
        uint256 tokenPrice = _getToken1Price();
        return (poolPrice * tokenPrice) / WAD;
    }

    /// +-------------------------------------------------------------------------
    /// | Internals:Helpers
    /// +-------------------------------------------------------------------------

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
