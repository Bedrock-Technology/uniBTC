from brownie import FBTC, accounts, Contract, project, config

# Execution Command Format:
# `brownie run scripts/testnet/deploy_fbtc.py main "owner" --network=holesky-rpc-public`


def main(owner="owner"):
    owner = accounts.load(owner)

    # Deploy contracts
    fbtc = FBTC.deploy({'from': owner})

    # Check status
    assert fbtc.mintableGroup(owner)
    assert fbtc.decimals() == 8

    print("Deployed FBTC address: ", fbtc)

    # Deployed contract on holesky-test: 0x5C367C804ce9F00464Cba3199d6Fb646E8287146

    # Deployed contract on avax-test: 0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B

    # Deployed contract on bsc-test: 0xc87E37848B913f289Aee0E2A9d3Ed94bA98D2A60

    # Deployed contract on ftm-test: 0xEB74BB04aD28b9b7ec1f2fd1812e7242170C6d1B
