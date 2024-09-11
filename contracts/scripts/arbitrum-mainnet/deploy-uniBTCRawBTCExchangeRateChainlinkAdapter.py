from brownie import uniBTCRawBTCExchangeRateChainlinkAdapter, accounts, Contract, project, config

# Execution Command Format:
# `brownie run scripts/arbitrum-mainnet/deploy-uniBTCRawBTCExchangeRateChainlinkAdapter.py main "uniBTCMainnetAdmin" --network=arbitrum-main -I`


def main(owner="owner"):
    owner = accounts.load(owner)

    uniBTCRate_address = "0xBE43aE6E89c2c74B49cfAB956a9E36a35B5fdE06"

    # Deploy contracts
    adapter = uniBTCRawBTCExchangeRateChainlinkAdapter.deploy(uniBTCRate_address, {'from': owner})

    # Check status
    assert adapter.decimals() == 8
    assert adapter.description() == "uniBTC/BTC exchange rate"
    assert adapter.uniBTCRate() == uniBTCRate_address

    _, rate, _, _, _ = adapter.latestRoundData()
    assert rate == 1e8

    print("Deployed uniBTCRawBTCExchangeRateChainlinkAdapter address: ", adapter)

    # Deployed uniBTCRawBTCExchangeRateChainlinkAdapter address: 0x4DFfCaf5d0B3B83a31405443bF5A4D6a3F9903F5



