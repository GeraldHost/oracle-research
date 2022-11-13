import argparse
from ape import networks


def main():
    parser = argparse.ArgumentParser(
        prog="Oracle Research",
        description="Oracle research project (v2, v3, curveLP, BPT, SUSHI)",
    )

    parser.add_argument("oracle")
    args = parser.parse_args()

    context = networks.parse_network_choice("ethereum:mainnet-fork:hardhat")
    context.disconnect_all()
    context.__enter__()
    if networks.active_provider:
        print(networks.active_provider.is_connected)

    print(args.oracle)


if __name__ == "__main__":
    main()
