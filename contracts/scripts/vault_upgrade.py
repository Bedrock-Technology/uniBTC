from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    TimelockController = deps.TimelockController
    ProxyAdmin = deps.ProxyAdmin

    WBTC = deps.ERC20.at("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599")

    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')
    multisig = "0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3"
    btcWhaleAccount = "0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8"
    nullAddress = "0x0000000000000000000000000000000000000000"
    vault_proxy = TransparentUpgradeableProxy.at("0x047D41F2544B7F63A8e991aF2068a363d210d6Da")
    proxyAdmin = ProxyAdmin.at("0x029E4FbDAa31DE075dD74B2238222A08233978f6")
    fbtc = "0xC96dE26018A54D51c097160568752c4E3BD6C364"

    # deploy vault
    vault_impl = Vault.deploy({'from': deployer})
    calldata = Vault[-1].initializeV2.encode_input()
    print("calldata:", calldata)
    proxyAdmin.upgradeAndCall(vault_proxy, vault_impl, calldata, {'from': multisig})

    transparent_vault = Contract.from_abi("vault",vault_proxy.address, Vault.abi)
    transparent_vault.setCap(fbtc, 1e8 * 5000, {'from':multisig})
