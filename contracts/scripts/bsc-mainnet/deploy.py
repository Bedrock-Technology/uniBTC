from brownie import uniBTC, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/bsc-mainnet/deploy.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=bsc-main -I`


def main(deployer="deployer", owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")
    pauser_role = w3.keccak(text='PAUSER_ROLE')
    minter_role = w3.keccak(text='MINTER_ROLE')

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deploy ProxyAdmin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # Deploy uniBTC
    uniBTC_impl = uniBTC.deploy({'from': deployer})
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(uniBTC_impl, proxyAdmin, b'', {'from': deployer})

    # Deploy Vault
    vault_impl = Vault.deploy({'from': deployer})
    vault_proxy = TransparentUpgradeableProxy.deploy(vault_impl, proxyAdmin, b'', {'from': deployer})

    # Initialize Vault
    vault_transparent = Contract.from_abi("Vault", vault_proxy, Vault.abi)
    vault_transparent.initialize(owner, uniBTC_proxy, {'from': owner})
    assert vault_transparent.hasRole(default_admin_role, owner)
    assert vault_transparent.hasRole(pauser_role, owner)
    assert vault_transparent.uniBTC() == uniBTC_proxy

    # Initialize uniBTC
    uniBTC_transparent = Contract.from_abi("uniBTC", uniBTC_proxy, uniBTC.abi)
    uniBTC_transparent.initialize(owner, vault_proxy, {'from': owner})
    assert uniBTC_transparent.hasRole(default_admin_role, owner)
    assert uniBTC_transparent.hasRole(minter_role, vault_proxy)

    # Set FBTC cap
    fbtc = "0xC96dE26018A54D51c097160568752c4E3BD6C364"
    cap = 5000 * 1e8
    vault_transparent.setCap(fbtc, cap, {'from':owner})
    assert vault_transparent.caps(fbtc) == cap

    # Set BTCB cap
    btcb = "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c"
    cap = 5000 * 1e18
    vault_transparent.setCap(btcb, cap, {'from':owner})
    assert vault_transparent.caps(btcb) == cap


    print("Deployed ProxyAdmin address: ", proxyAdmin)  # 0xb3f925B430C60bA467F7729975D5151c8DE26698
    print("Deployed uniBTC proxy address: ", uniBTC_proxy)  # 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
    print("Deployed Vault proxy address: ", vault_proxy)    # 0x84E5C854A7fF9F49c888d69DECa578D406C26800

    print("")

    print("Deployed uniBTC implementation address: ", uniBTC_impl)  # 0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3
    print("Deployed Vault implementation address: ", vault_impl)    # 0x08cB45f7FC43C25BbE830DacFe57D72CbC46775d





