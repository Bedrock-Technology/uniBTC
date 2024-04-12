from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    WBTC = deps.ERC20.at("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599")

    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')

    # deploy token
    uniBTC_impl = uniBTC.deploy({'from': deployer})
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(uniBTC_impl, deployer, b'', {'from': deployer})

    # deploy vault
    vault_impl = Vault.deploy({'from': deployer})
    vault_proxy = TransparentUpgradeableProxy.deploy(vault_impl, deployer, b'', {'from': deployer})

    # initialize vault
    transparent_vault = Contract.from_abi("vault",vault_proxy.address, Vault.abi)
    transparent_vault.initialize(owner, WBTC, uniBTC_proxy, {'from': owner})

    # initialize token
    transparent_uniBTC = Contract.from_abi("uniBTC",uniBTC_proxy.address, uniBTC.abi)
    transparent_uniBTC.initialize(owner, vault_proxy, {'from': owner})

    btcOwner = accounts.at('0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8', {'force':True})
    print("btcOwner:", btcOwner)
