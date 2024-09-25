from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/merlin-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=merlin-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    gas_limit = '2000000'
    gas_price = '100000000'

    vault_impl = Vault.deploy({'from': deployer, 'gas_limit': gas_limit, 'gas_price': gas_price})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x08cB45f7FC43C25BbE830DacFe57D72CbC46775d
