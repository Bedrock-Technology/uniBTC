from brownie import uniBTCRawBTCExchangeRateChainlinkAdapter, accounts, Contract, project, config

# Execution Command Format:
# `brownie run scripts/optimism-mainnet/deploy-uniBTCRawBTCExchangeRateChainlinkAdapter.py main "uniBTCMainnetAdmin" --network=optimism-main -I`


def main(owner="owner"):
    owner = accounts.load(owner)

    uniBTCRate_address = "0x56c3024eB229Ca0570479644c78Af9D53472B3e4"

    # Deploy contracts
    adapter = uniBTCRawBTCExchangeRateChainlinkAdapter.deploy(uniBTCRate_address, {'from': owner})

    # Check status
    assert adapter.decimals() == 8
    assert adapter.description() == "uniBTC/BTC exchange rate"
    assert adapter.uniBTCRate() == uniBTCRate_address

    _, rate, _, _, _ = adapter.latestRoundData()
    assert rate == 1e8

    print("Deployed uniBTCRawBTCExchangeRateChainlinkAdapter address: ", adapter)

    # Deployed uniBTCRawBTCExchangeRateChainlinkAdapter address: 0xb3f925B430C60bA467F7729975D5151c8DE26698



