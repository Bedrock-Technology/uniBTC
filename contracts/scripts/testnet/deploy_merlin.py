from brownie import mBTC, uniBTC, Vault, Peer, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3

from scripts.testnet.configs import contracts, recipients, caps

# Execution Command Format:
# `brownie run scripts/testnet/deploy_merlin.py main "deployer" "owner" "bitlayer-test" --network=merlin-testnet`


def main(deployer="deployer", owner="owner", network="merlin-test"):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    proxy = deps.TransparentUpgradeableProxy
    proxyAdmin = deps.ProxyAdmin

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    minter_role = w3.keccak(text='MINTER_ROLE')

    # message_bus = contracts[network]["message_bus"]

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deploy contracts
    proxy_admin = proxyAdmin.deploy({'from': owner})

    mbtc = mBTC.deploy({'from': owner})

    uni_btc = uniBTC.deploy({'from': deployer})
    uni_btc_proxy = proxy.deploy(uni_btc, proxy_admin, b'', {'from': deployer})
    uni_btc_transparent = Contract.from_abi("uniBTC", uni_btc_proxy.address, uniBTC.abi)

    vault = Vault.deploy({'from': deployer})
    vault_proxy = proxy.deploy(vault, proxy_admin, b'', {'from': deployer})
    vault_transparent = Contract.from_abi("Vault", vault_proxy.address, Vault.abi)

    # peer = Peer.deploy(message_bus, uni_btc_transparent, {'from': owner})

    # Initialize contracts
    uni_btc_transparent.initialize(owner, owner, {'from': owner})
    vault_transparent.initialize(owner, uni_btc_transparent, True, {'from': owner})

    # Grant MINTER_ROLE
    minters = [vault_transparent]  # [vault_transparent, peer]
    for minter in minters:
        uni_btc_transparent.grantRole(minter_role, minter, {'from': owner})

    # Set caps
    native_btc = vault_transparent.NATIVE_BTC()
    vault_transparent.setCap(native_btc, caps[1], {'from': owner})
    vault_transparent.setCap(mbtc, caps[1], {'from': owner})

    # Mint tokens
    tokens = [mbtc]
    amt = caps[0]
    for tk in tokens:
        if tk.decimals() == 18:
            amt = caps[1]

        for recipient in recipients:
            tk.mint(recipient, amt, {'from': owner})

    # Check status
    assert mbtc.mintableGroup(owner)

    assert mbtc.decimals() == 18

    assert vault_transparent.caps(native_btc) == caps[1]
    assert vault_transparent.caps(mbtc) == caps[1]

    assert vault_transparent.uniBTC() == uni_btc_transparent

    # assert peer.messageBus() == message_bus
    # assert peer.uniBTC() == uni_btc_transparent

    assert uni_btc_transparent.hasRole(minter_role, vault_transparent)
    # assert uni_btc_transparent.hasRole(minter_role, peer)

    print("Deployed ProxyAdmin address: ", proxy_admin)
    print("Deployed mBTC address: ", mbtc)
    # print("Deployed Peer address: ", peer)
    print("Deployed uniBTC proxy address: ", uni_btc_transparent)
    print("Deployed Vault proxy address: ", vault_transparent)

    print("")

    print("Deployed uniBTC address: ", uni_btc)
    print("Deployed Vault address: ", vault)

    # Deployed contracts on merlin-test
    # Deployed ProxyAdmin address:  0x56c3024eB229Ca0570479644c78Af9D53472B3e4
    # Deployed mBTC address:  0xC0c9E78BfC3996E8b68D872b29340816495D7e89
    # Deployed Peer address:
    # Deployed uniBTC proxy address:  0x16221CaD160b441db008eF6DA2d3d89a32A05859
    # Deployed Vault proxy address:  0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823
    #
    # Deployed uniBTC address:  0x57518941854F879f80fA1ABF2366f54339DE8436
    # Deployed Vault address:  0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894




