from brownie import TestTokenAmounts, accounts
from brownie.network import priority_fee
from math import floor

# pid: 372817


def main():
    priority_fee("2 gwei")
    acct = accounts.load("anvil")
    c = TestTokenAmounts.deploy({"from": acct})

    # ETH:USDC
    # tick = 205691
    # tick_lower = 205010
    # tick_upper = 208210
    # liquidity = 1498300094996842

    # ETH:DAI
    tick = -70659
    tick_lower = -77580
    tick_upper = -63720
    liquidity = 99692181756611950

    for _ in range(10):
        print("")
        print("tick:", tick)

        amounts = c.amounts(tick, tick_lower, tick_upper, liquidity)
        print("amounts:", amounts[0], amounts[1])

        price = c.price(-tick)
        print("price:", floor(price/1e18))

        tick += 1000
