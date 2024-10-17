from brownie import directBTC, DirectBTCMinter, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/directbtc-mainnet/deploy_b2.py main "mainnet-deployer" "mainnet-owner" --network=b2-fork -I`

def main(deployer="mainnet-deployer", owner="mainnet-owner"):

    # make sure to set the correct ProxyAdmin and uniBtcVault address
    proxyAdmin = '0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19'
    uniBtcVault = '0xF9775085d726E782E83585033B58606f7731AB18'

    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.toBytes(hexstr="0x00")

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deploy directBTC
    directBTC_impl = directBTC.deploy({'from': deployer})
    directBTC_proxy = TransparentUpgradeableProxy.deploy(directBTC_impl, proxyAdmin, b'', {'from': deployer})

    # Deploy minter
    minter_impl = DirectBTCMinter.deploy({'from': deployer})
    minter_proxy = TransparentUpgradeableProxy.deploy(minter_impl, proxyAdmin, b'', {'from': deployer})

    # vault proxy
    vault_proxy = Contract.from_abi("Vault", uniBtcVault, Vault.abi)

    # directBTCMinter roles
    approver_role = w3.keccak(text='APPROVER_ROLE')
    l1minter_role = w3.keccak(text='L1_MINTER_ROLE')
    # init minter
    minter_transparent = Contract.from_abi("DirectBTCMinter", minter_proxy, DirectBTCMinter.abi)
    minter_transparent.initialize(owner, directBTC_proxy, uniBtcVault, vault_proxy.uniBTC(), {'from': owner})
    assert minter_transparent.hasRole(default_admin_role, owner)
    assert minter_transparent.hasRole(l1minter_role, owner)
    assert minter_transparent.hasRole(approver_role, owner)
    assert minter_transparent.directBTC() == directBTC_proxy

    # directBTC roles
    minter_role = w3.keccak(text='MINTER_ROLE')
    # init directBTC
    transparent_directBTC = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)
    transparent_directBTC.initialize(owner, minter_proxy, {'from': owner})
    assert transparent_directBTC.hasRole(default_admin_role, owner)
    assert transparent_directBTC.hasRole(minter_role, minter_proxy)

    print("| Contract (B2)                | Address                                    |")
    print("|------------------------------|--------------------------------------------|")
    print("| ProxyAdmin                   |", proxyAdmin, "|")
    print("| uniBtcVault                  |", uniBtcVault, "|")
    print("|------------------------------|--------------------------------------------|")
    print("| directBTC proxy              |", directBTC_proxy, "|")
    print("| directBTC imple              |", directBTC_impl, "|")
    print("|------------------------------|--------------------------------------------|")
    print("| DirectBTCMinter proxy        |", minter_proxy, "|")
    print("| DirectBTCMinter imple        |", minter_impl, "|")
    print("|------------------------------|--------------------------------------------|")


