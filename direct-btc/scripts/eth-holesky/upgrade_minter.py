from brownie import DirectBTCMinter, accounts, Contract, project, config
from pathlib import Path

# from scripts.testnet.configs import contracts

# Execution Command Format:
# `brownie run scripts/testnet/upgrade_minter.py main "deployer" "owner" "avax-test" --network=avax-test`


def main(deployer="testnet-deployer", owner="testnet-owner", network="holesky-fork"):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)
    proxy_admin_addr = '0xC0c9E78BfC3996E8b68D872b29340816495D7e89'
    minterAddr = '0x8D5AeFCC9a2BA96784775f930FD64F2b35750Ab5'
    proxy_admin = ProxyAdmin.at(proxy_admin_addr)
    minter_proxy = TransparentUpgradeableProxy.at(minterAddr)

    new_minter_impl = DirectBTCMinter.deploy({'from': deployer})
    # vault_impl = "0x3ffce70735626B13B5F36863665520628E895ECC"
    proxy_admin.upgrade(minter_proxy, new_minter_impl, {'from': owner})

    assert proxy_admin.getProxyImplementation(minter_proxy) == new_minter_impl

    print("ProxyAdmin: ", proxy_admin)
    print("DirectBTCMinter proxy: ", minter_proxy)
    print("Deployed new impl: ", new_minter_impl)

