from brownie import uniBTC, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/bob-mainnet/deploy.py main "deployer" "owner" --network=bob-mainnet -I`


def main(deployer="deployer", owner="owner"):
    # Reference: https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy
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

    # Set WBTC cap
    wbtc = "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3"
    cap = 5000 * 1e8
    vault_transparent.setCap(wbtc, cap, {'from':owner})
    assert vault_transparent.caps(wbtc) == cap


    print("Deployed ProxyAdmin address: ", proxyAdmin)  # 0x56c3024eB229Ca0570479644c78Af9D53472B3e4
    print("Deployed uniBTC proxy address: ", uniBTC_proxy)  # 0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894
    print("Deployed Vault proxy address: ", vault_proxy)    # 0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf

    print("")

    print("Deployed uniBTC implementation address: ", uniBTC_impl)  # 0x16221CaD160b441db008eF6DA2d3d89a32A05859
    print("Deployed Vault implementation address: ", vault_impl)    # 0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823





