from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/ethereum-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=eth-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x702696b2aA47fD1D4feAAF03CE273009Dc47D901
