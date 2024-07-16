from brownie import uniBTC, Vault, Peer, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3

from scripts.testnet.configs import contracts

# Execution Command Format:
# `brownie run scripts/testnet/deploy_with_peer.py main "deployer" "owner" "avax-test" "False" --network=avax-test`


def main(deployer="deployer", owner="owner", network="avax-test", isNativeBTC="False"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    proxy = deps.TransparentUpgradeableProxy
    proxyAdmin = deps.ProxyAdmin

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    minter_role = w3.keccak(text='MINTER_ROLE')

    message_bus = contracts[network]["message_bus"]

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    is_native_btc = True
    if isNativeBTC != "True":
        is_native_btc = False

    # Deploy contracts
    proxy_admin = proxyAdmin.deploy({'from': owner})

    uni_btc = uniBTC.deploy({'from': deployer})
    uni_btc_proxy = proxy.deploy(uni_btc, proxy_admin, b'', {'from': deployer})
    uni_btc_transparent = Contract.from_abi("uniBTC", uni_btc_proxy.address, uniBTC.abi)

    vault = Vault.deploy({'from': deployer})
    vault_proxy = proxy.deploy(vault, proxy_admin, b'', {'from': deployer})
    vault_transparent = Contract.from_abi("Vault", vault_proxy.address, Vault.abi)

    peer = Peer.deploy(message_bus, uni_btc_transparent, {'from': owner})

    # Initialize contracts
    uni_btc_transparent.initialize(owner, owner, {'from': owner})
    vault_transparent.initialize(owner, uni_btc_transparent, is_native_btc, {'from': owner})

    # Grant MINTER_ROLE
    minters = [vault_transparent, peer]
    for minter in minters:
        uni_btc_transparent.grantRole(minter_role, minter, {'from': owner})

    # Check status
    assert vault_transparent.isNativeBTC() == is_native_btc

    assert vault_transparent.uniBTC() == uni_btc_transparent

    assert peer.messageBus() == message_bus
    assert peer.uniBTC() == uni_btc_transparent

    assert uni_btc_transparent.hasRole(minter_role, vault_transparent)
    assert uni_btc_transparent.hasRole(minter_role, peer)

    print("Deployed ProxyAdmin address: ", proxy_admin)
    print("Deployed Peer address: ", peer)
    print("Deployed uniBTC proxy address: ", uni_btc_transparent)
    print("Deployed Vault proxy address: ", vault_transparent)

    print("")

    print("Deployed uniBTC address: ", uni_btc)
    print("Deployed Vault address: ", vault)

    # Deployed contracts on avax-test
    # Deployed ProxyAdmin address:  0x8746649B65eA03A22e559Eb03059018baEDFBA9e
    # Deployed Peer address:  0xe7431fc992a54fAA435125Ca94E00B4a8c89095c
    # Deployed uniBTC proxy address:  0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f
    # Deployed Vault proxy address:  0x85792f60633DBCF7c2414675bcC0a790B1b65CbB
    #
    # Deployed uniBTC address:  0x54B045860E49711eABDa160eBd5db8be1fC85A55
    # Deployed Vault address:  0x802d4900209b2292bF7f07ecAE187f836040A709

    # Deployed contracts on bsc-test
    # Deployed ProxyAdmin address:  0x49D6844cbcef64952E6793677eeaBae324f895aD
    # Deployed Peer address:  0xd59677a6eFe9151c0131E8cF174C8BBCEB536005
    # Deployed uniBTC proxy address:  0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f
    # Deployed Vault proxy address:  0x85792f60633DBCF7c2414675bcC0a790B1b65CbB
    #
    # Deployed uniBTC address:  0x54B045860E49711eABDa160eBd5db8be1fC85A55
    # Deployed Vault address:  0x802d4900209b2292bF7f07ecAE187f836040A709

    # Deployed contracts on ftm-test
    # Deployed ProxyAdmin address:  0x8746649B65eA03A22e559Eb03059018baEDFBA9e
    # Deployed Peer address:  0xe7431fc992a54fAA435125Ca94E00B4a8c89095c
    # Deployed uniBTC proxy address:  0x802d4900209b2292bF7f07ecAE187f836040A709
    # Deployed Vault proxy address:  0x06c186Ff3a0dA2ce668E5B703015f3134F4a88Ad
    #
    # Deployed uniBTC address:  0x2c914Ba874D94090Ba0E6F56790bb8Eb6D4C7e5f
    # Deployed Vault address:  0x85792f60633DBCF7c2414675bcC0a790B1b65CbB





