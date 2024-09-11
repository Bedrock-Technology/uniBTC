from brownie import uniBTCRate, accounts, Contract, project, config

# Execution Command Format:
# `brownie run scripts/arbitrum-mainnet/deploy-uniBTCRate.py main "uniBTCMainnetAdmin" --network=arbitrum-main -I`


def main(owner="owner"):
    owner = accounts.load(owner)

    # Deploy contracts
    uni_btc_rate = uniBTCRate.deploy({'from': owner})

    # Check status
    assert uni_btc_rate.getRate() == 1e8

    print("Deployed uniBTCRate address: ", uni_btc_rate)

    # Deployed uniBTCRate address:  0xBE43aE6E89c2c74B49cfAB956a9E36a35B5fdE06



