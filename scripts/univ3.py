from brownie import UniswapV3Oracle, Oracle, accounts
from brownie.network import priority_fee


# USDC_ETH = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640"
# DAI_ETH = "0x60594a405d53811d3BC4766596EFD80fd545A270"

"""
uint256 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick)

(uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
    sqrtRatioX96,
    TickMath.getSqrtRatioAtTick(tickLower),
    TickMath.getSqrtRatioAtTick(tickUpper),
    liquidity
);

pid = 371781
print(oracle.getAmounts(pid))
print(oracle.getTokens(pid))

print(
    "ETH in USDC:",
    oracle.getTokenPrice("0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", False),
)
"""


def main():
    priority_fee("2 gwei")
    acct = accounts.load("anvil")
    # oracle = UniswapV3Oracle.deploy({"from": acct})
    oracle = Oracle.deploy({"from": acct})

    # print(oracle.getTokenPrice("0x60594a405d53811d3BC4766596EFD80fd545A270", False))
    print("Price:", oracle.getPrice(374724))
