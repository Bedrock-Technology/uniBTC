from brownie import *
from pathlib import Path

import time
import pytest

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    owner = accounts.load('testnet-deployer')
    deployer = accounts.load('testnet-deployer')

    coboBTC_impl = coboBTC.deploy({'from': deployer})
    coboBTC_proxy = TransparentUpgradeableProxy.deploy(coboBTC_impl, deployer, b'', {'from': deployer})

    transparent_coboBTC = Contract.from_abi("coboBTC",coboBTC_proxy.address, coboBTC.abi)
    transparent_coboBTC.initialize(owner, owner, {'from': owner})
    
    