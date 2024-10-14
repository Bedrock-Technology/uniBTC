from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')

    uniBTCRate_impl = uniBTCRate.deploy({'from': deployer})
    uniBTCRate_proxy = TransparentUpgradeableProxy.deploy(uniBTCRate_impl, deployer, b'', {'from': deployer})

    transparent_uniBTCRate = Contract.from_abi("uniBTC",uniBTCRate_proxy.address, uniBTCRate.abi)
    transparent_uniBTCRate.initialize(owner, {'from': owner})
