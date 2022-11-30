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
    
    # eth:dai
    pool = "0xc2e9f25be6257c210d7adf0d4cd6e3e881ba25f8"
    # dai:oracle
    token0Oracle = "0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9"
    # eth:oracle
    token1Oracle = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"

    oracle = Oracle.deploy(token0Oracle, token1Oracle, pool, {"from": acct})

    # print(oracle.getTokenPrice("0x60594a405d53811d3BC4766596EFD80fd545A270", False))
    #print("Price:", oracle.getPrice(7177))
    #print("Price:", oracle.getPrice(375246))
    print("(_getToken0Price(), _getToken1Price(), _getPoolPrice(), _getAnchorPrice())")
    print(oracle.getPrice(375246))
    #print("Price:", oracle.getPrice(1023286666))
