from brownie import Vault, accounts

# Execution Command Format:
# `brownie run scripts/zeta-mainnet/deploy-Vault.py main "uniBTCMainnetDeployer" --network=zeta-mainnet -I`

def main(deployer="deployer"):
    deployer = accounts.load(deployer)

    vault_impl = Vault.deploy({'from': deployer})

    print(" Deployed Vault implementation address: ", vault_impl)   # 0xFa8C3e48D8Ad82B3EaF640163310927e85f41e5F
