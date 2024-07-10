from brownie import AirDropper, accounts, Contract, project, config

# Execution Command Format:
# `brownie run scripts/testnet/deploy_airdropper.py main "owner" --network=holesky-rpc-public`


def main(owner="owner"):
    owner = accounts.load(owner)

    # Deploy contracts
    air_dropper = AirDropper.deploy({'from': owner})

    print("Deployed AirDropper address: ", air_dropper)

    # Deployed contract on holesky-test: 0xd59677a6eFe9151c0131E8cF174C8BBCEB536005

    # Deployed contract on avax-test:

    # Deployed contract on bsc-test:

    # Deployed contract on ftm-test:
