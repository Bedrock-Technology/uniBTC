from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/b2-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=b2-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x08cB45f7FC43C25BbE830DacFe57D72CbC46775d
