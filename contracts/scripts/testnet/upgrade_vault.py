from brownie import Vault, accounts, Contract, project, config
from pathlib import Path

from scripts.testnet.configs import contracts

# Execution Command Format:
# `brownie run scripts/testnet/upgrade_vault.py main "deployer" "owner" "avax-test" --network=avax-test`


def main(deployer="deployer", owner="owner", network="avax-test"):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    proxy_admin = ProxyAdmin.at(contracts[network]["proxy_admin"])
    vault_proxy = TransparentUpgradeableProxy.at(contracts[network]["vault"])

    vault_impl = Vault.deploy({'from': deployer})
    proxy_admin.upgrade(vault_proxy, vault_impl, {'from': owner})

    assert proxy_admin.getProxyImplementation(vault_proxy) == vault_impl

    print("Deployed Vault ProxyAdmin: ", proxy_admin)
    print("Deployed Vault Proxy: ", vault_proxy)
    print("Deployed Vault implementation: ", vault_impl)

    # Deployed Vault implementation on avax-test: 0x409dF0Ee22F057A88c1F98743c2e42D0c45DaDda

    # Deployed Vault implementation on bsc-test: 0x409dF0Ee22F057A88c1F98743c2e42D0c45DaDda

    # Deployed Vault implementation on ftm-test: 0x9cb04A403c6691AdEE14cE43D19aF1fE96C5ab91




