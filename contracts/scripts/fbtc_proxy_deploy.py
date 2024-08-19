from brownie import FBTCProxy, accounts

# Execution Command Format:
# `brownie run scripts/fbtc_proxy_deploy.py main "owner" "ethereum" --network=eth-mainnet`

contracts = {
    "ethereum": {
        "vault": "0x047D41F2544B7F63A8e991aF2068a363d210d6Da",          # https://etherscan.io/address/0x047D41F2544B7F63A8e991aF2068a363d210d6Da
        "locked_fbtc": "0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c",    # https://etherscan.io/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c
    },
    "mantle": {
        "vault": "0xF9775085d726E782E83585033B58606f7731AB18",          # https://explorer.mantle.xyz/address/0xF9775085d726E782E83585033B58606f7731AB18
        "locked_fbtc": "0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c",    # https://explorer.mantle.xyz/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c
    },
}


def main(owner="owner", network="ethereum"):
    owner = accounts.load(owner)

    fbtc_proxy = FBTCProxy.deploy(contracts[network]['vault'], contracts[network]['locked_fbtc'], {'from': owner})

    assert fbtc_proxy.owner() == owner

    print("Deployed FBTCProxy address: ", fbtc_proxy)

    # Deployed FBTCProxy addresses:
    # Ethereum: 0x56c3024eB229Ca0570479644c78Af9D53472B3e4               # https://etherscan.io/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4
    # Mantle:   0x56c3024eB229Ca0570479644c78Af9D53472B3e4               # https://explorer.mantle.xyz/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4




