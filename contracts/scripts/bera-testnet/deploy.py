from brownie import WBTC, uniBTC, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3

from scripts.testnet.configs import recipients, caps

# Execution Command Format:
# `brownie run scripts/bera-testnet/deploy.py main "deployer" "owner" --network=bera-test -I`


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

    # Deploy WBTC
    wbtc = WBTC.deploy({'from': owner})

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

    # Set token caps
    tokens = [wbtc,  # mocked WBTC address
             "0x286F1C3f0323dB9c91D1E8f45c8DF2d065AB5fae"]  # official WBTC address

    for token in tokens:
        vault_transparent.setCap(token, caps[0], {'from':owner})
        assert vault_transparent.caps(token) == caps[0]

    # Mint mocked tokens
    for recipient in recipients:
        wbtc.mint(recipient, caps[0], {'from': owner})
        assert wbtc.balanceOf(recipient) == caps[0]


    print("Deployed ProxyAdmin address: ", proxyAdmin)  # 0xC0c9E78BfC3996E8b68D872b29340816495D7e89
    print("Deployed WBTC address: ", wbtc)  #   0xcBf3e6Ad1eeD0f3F81fCc2Ae76A0dB16C4e747B0
    print("Deployed uniBTC proxy address: ", uniBTC_proxy)  # 0x16221CaD160b441db008eF6DA2d3d89a32A05859
    print("Deployed Vault proxy address: ", vault_proxy)    # 0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823

    print("")

    print("Deployed uniBTC implementation address: ", uniBTC_impl)  # 0x57518941854F879f80fA1ABF2366f54339DE8436
    print("Deployed Vault implementation address: ", vault_impl)    # 0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894





