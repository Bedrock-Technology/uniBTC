from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/bob-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=bob-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
