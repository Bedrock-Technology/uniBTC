from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    owner = accounts.load('mainnet-owner')
    deployer = accounts.load('mainnet-deployer')

    #uniBTC_impl = uniBTC.deploy({'from': deployer})
    uniBTC_impl ="0x552b0C6688FCaE5cF0164F27Fd129b882a42fA05"
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(uniBTC_impl, deployer, b'', {'from': deployer})

    transparent_uniBTC = Contract.from_abi("uniBTC",uniBTC_proxy.address, uniBTC.abi)
    transparent_uniBTC.initialize(owner, owner, [], {'from': owner})
