from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/bsc-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=bsc-main -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x8891C147041390efA5177F0a77d12cbDc4c9c533
