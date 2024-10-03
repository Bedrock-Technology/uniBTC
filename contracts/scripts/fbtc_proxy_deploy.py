from brownie import FBTCProxy, accounts, web3

# Execution Command Format:
# `brownie run scripts/fbtc_proxy_deploy.py main "deployer" "ethereum" --network=eth-mainnet`

contracts = {
    "ethereum": {
        "vault": "0x047D41F2544B7F63A8e991aF2068a363d210d6Da",          # https://etherscan.io/address/0x047D41F2544B7F63A8e991aF2068a363d210d6Da
        "locked_fbtc": "0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c",    # https://etherscan.io/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c
        "admin": "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB",   # 0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32
    },
    "mantle": {
        "vault": "0xF9775085d726E782E83585033B58606f7731AB18",          # https://explorer.mantle.xyz/address/0xF9775085d726E782E83585033B58606f7731AB18
        "locked_fbtc": "0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c",    # https://explorer.mantle.xyz/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c
        "admin": "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB",
    },
    "bsc": {
        "vault": "0x84E5C854A7fF9F49c888d69DECa578D406C26800", 
        "locked_fbtc": "0xEb28877D7e3DbA5bcd4D0a1474C31F8AFb2d6052",    # https://explorer.mantle.xyz/address/0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c
        "admin": "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB",
    },

}


def main(deployer_account="mainnet-deployer", network="bsc"):
    deployer = accounts.load(deployer_account)
    assert contracts[network]['vault'] != ""
    assert contracts[network]['locked_fbtc'] != ""
    assert contracts[network]['admin'] != ""
    
    fbtc_proxy = FBTCProxy.deploy(contracts[network]['vault'], contracts[network]['locked_fbtc'],contracts[network]['admin'], {'from': deployer})

#    default_admin_role = web3.to_bytes(hexstr="0x00")
#    assert fbtc_proxy.hasRole(default_admin_role,contracts[network]['admin']) == True

    print("Deployed FBTCProxy address: ", fbtc_proxy)

    # Deployed FBTCProxy addresses:
    # Ethereum: 0x56c3024eB229Ca0570479644c78Af9D53472B3e4               # https://etherscan.io/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4
    # Mantle:   0x56c3024eB229Ca0570479644c78Af9D53472B3e4               # https://explorer.mantle.xyz/address/0x56c3024eB229Ca0570479644c78Af9D53472B3e4




