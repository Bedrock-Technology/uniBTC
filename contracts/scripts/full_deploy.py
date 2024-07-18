from brownie import *
from pathlib import Path

import time
import pytest


# Execution Command Format:
# `brownie run scripts/full_deploy.py main "False" --network=eth-mainnet`

def main(isNativeBTC="False"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    TimelockController = deps.TimelockController
    ProxyAdmin = deps.ProxyAdmin

    WBTC = deps.ERC20.at("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599")

    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')
    multisig = "0xAeE017052DF6Ac002647229D58B786E380B9721A"
    btcWhaleAccount = "0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8"
    nullAddress = "0x0000000000000000000000000000000000000000"


    is_native_btc = True
    if isNativeBTC != "True":
        is_native_btc = False

    # deploy proxy admin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # deploy token
    uniBTC_impl = uniBTC.deploy({'from': deployer})
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(uniBTC_impl, proxyAdmin, b'', {'from': deployer})

    # deploy vault
    vault_impl = Vault.deploy({'from': deployer})
    vault_proxy = TransparentUpgradeableProxy.deploy(vault_impl, proxyAdmin, b'', {'from': deployer})

    # initialize vault
    transparent_vault = Contract.from_abi("Vault", vault_proxy.address, Vault.abi)
    transparent_vault.initialize(owner, uniBTC_proxy, {'from': owner})

    # initialize token
    transparent_uniBTC = Contract.from_abi("uniBTC",uniBTC_proxy.address, uniBTC.abi)
    transparent_uniBTC.initialize(owner, vault_proxy, is_native_btc, {'from': owner})

    assert transparent_vault.isNativeBTC() == is_native_btc

"""
    # deploy timelock and set proposer to a gnosis multisig wallet
    timelock = TimelockController.deploy(86400, [multisig], [nullAddress], nullAddress, {'from': deployer})

    # set owner of proxyadmin to timelock
    proxyAdmin.transferOwnership(timelock, {'from': owner})

    # grant owner of vault and uniBTC to timelock
    transparent_vault.grantRole(transparent_vault.DEFAULT_ADMIN_ROLE(), timelock, {'from': owner})
    transparent_uniBTC.grantRole(transparent_uniBTC.DEFAULT_ADMIN_ROLE(), timelock, {'from': owner})

    btcOwner = accounts.at(btcWhaleAccount, {'force':True})
    print("btcOwner:", btcOwner)
    print("proxyAdmin:", proxyAdmin)
    print("vault_proxy:", vault_proxy)
    print("uniBTC_proxy:", uniBTC_proxy)
"""
