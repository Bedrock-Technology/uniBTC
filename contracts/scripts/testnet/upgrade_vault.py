from brownie import Vault, accounts, Contract, project, config
from pathlib import Path

from scripts.testnet.configs import contracts

# Execution Command Format:
# `brownie run scripts/testnet/upgrade_vault.py main "deployer" "owner" "avax-test" "False" --network=avax-test`


def main(deployer="deployer", owner="owner", network="avax-test", isNativeBTC="False"):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    is_native_btc = True
    if isNativeBTC != "True":
        is_native_btc = False

    proxy_admin = ProxyAdmin.at(contracts[network]["proxy_admin"])
    vault_proxy = TransparentUpgradeableProxy.at(contracts[network]["vault"])

    vault_impl = Vault.deploy({'from': deployer})
    proxy_admin.upgrade(vault_proxy, vault_impl, {'from': owner})

    assert proxy_admin.getProxyImplementation(vault_proxy) == vault_impl

    vault_transparent = Contract.from_abi("Vault", vault_proxy.address, Vault.abi)
    vault_transparent.setIsNativeBTC(is_native_btc, {'from': owner})
    assert vault_transparent.isNativeBTC() == is_native_btc

    print("Deployed Vault ProxyAdmin: ", proxy_admin)
    print("Deployed Vault Proxy: ", vault_proxy)
    print("Deployed Vault implementation: ", vault_impl)

    # TODO: To be upgraded
    # Deployed Vault implementation on holesky-test: 0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf

    # Deployed Vault implementation on avax-test: 0x9cb04A403c6691AdEE14cE43D19aF1fE96C5ab91

    # Deployed Vault implementation on bsc-test: 0x9cb04A403c6691AdEE14cE43D19aF1fE96C5ab91

    # Deployed Vault implementation on ftm-test: 0x3ffce70735626B13B5F36863665520628E895ECC




