from brownie import UniswapV3Oracle, accounts
from brownie.network import priority_fee


def main():
    priority_fee("2 gwei")
    acct = accounts.load("anvil")
    oracle = UniswapV3Oracle.deploy({"from": acct})

    # USDC_ETH = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640"
    # DAI_ETH = "0x60594a405d53811d3BC4766596EFD80fd545A270"
    print("univ3")

    print(
        "ETH in USDC:",
        oracle.getPrice("0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640", False),
    )
    print(
        "ETH in DAI:",
        oracle.getPrice("0x60594a405d53811d3BC4766596EFD80fd545A270", False),
    )
