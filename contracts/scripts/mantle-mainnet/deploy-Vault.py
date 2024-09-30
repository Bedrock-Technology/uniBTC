from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/mantle-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=mantle-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0x84E5C854A7fF9F49c888d69DECa578D406C26800
