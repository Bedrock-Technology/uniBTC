import pytest
from web3 import Web3
from pathlib import Path
from brownie import FBTC, WBTC, WBTC18, XBTC, LockedFBTC, FBTCFacade, GenericFacade, Vault, uniBTC, Peer, MessageBus, accounts, Contract, project, config, network

# Web3 client
@pytest.fixture(scope="session", autouse=True)
def w3():
    return Web3(Web3.HTTPProvider('http://localhost:8545'))

# Roles
@pytest.fixture(scope="session", autouse=True)
def roles(w3):
    pauser_role = w3.keccak(text='PAUSER_ROLE')  # index = 0
    minter_role = w3.keccak(text='MINTER_ROLE')  # index = 1
    manager_role = w3.keccak(text='MANAGER_ROLE')  # index = 2
    default_admin_role = w3.to_bytes(hexstr='0x00')  # index = 3
    return [pauser_role, minter_role, manager_role, default_admin_role]

# Predefined Accounts
@pytest.fixture(scope="session", autouse=True)
def owner():
    return accounts[0]

@pytest.fixture(scope="session", autouse=True)
def deployer():
    return accounts[1]

@pytest.fixture(scope="session", autouse=True)
def alice():
    return accounts[2]

@pytest.fixture(scope="session", autouse=True)
def bob():
    return accounts[3]

@pytest.fixture(scope="session", autouse=True)
def executor():
    return accounts[3]

@pytest.fixture(scope="session", autouse=True)
def zero_address():
    return accounts.at("0x0000000000000000000000000000000000000000", True)

@pytest.fixture(scope="session", autouse=True)
def chain_id(w3):
    return w3.eth.chain_id

@pytest.fixture(scope="session", autouse=True)
def proxy():
    # Reference: https://docs.openzeppelin.com/contracts/4.x/api/proxy#TransparentUpgradeableProxy
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    return deps.TransparentUpgradeableProxy

# Contracts
@pytest.fixture()
def contracts(w3, proxy, chain_id, roles, owner, deployer):
    # Deploy contracts
    message_bus_sender = MessageBus.deploy({'from': owner})
    message_bus_receiver = MessageBus.deploy({'from': owner})
    fbtc = FBTC.deploy({'from': owner})
    wbtc = WBTC.deploy({'from': owner})
    wbtc18 = WBTC18.deploy({'from': owner})
    xbtc = XBTC.deploy({'from': owner})

    uni_btc = uniBTC.deploy({'from': deployer})
    uni_btc_proxy = proxy.deploy(uni_btc, deployer, b'', {'from': deployer})
    uni_btc_transparent = Contract.from_abi("uniBTC", uni_btc_proxy.address, uniBTC.abi)

    vault_eth = Vault.deploy({'from': deployer})
    vault_eth_proxy = proxy.deploy(vault_eth, deployer, b'', {'from': deployer})
    vault_eth_transparent = Contract.from_abi("Vault", vault_eth_proxy.address, Vault.abi)

    vault_btc = Vault.deploy({'from': deployer})
    vault_btc_proxy = proxy.deploy(vault_btc, deployer, b'', {'from': deployer})
    vault_btc_transparent = Contract.from_abi("Vault", vault_btc_proxy.address, Vault.abi)

    peer_sender = Peer.deploy(message_bus_sender, uni_btc_transparent, {'from': owner})
    peer_receiver = Peer.deploy(message_bus_receiver, uni_btc_transparent, {'from': owner})
    peers = [peer_sender, peer_receiver]

    locked_fbtc = LockedFBTC.deploy({'from': deployer})
    locked_fbtc_proxy = proxy.deploy(locked_fbtc, deployer, b'', {'from': deployer})
    locked_fbtc_transparent = Contract.from_abi("LockedFBTC", locked_fbtc_proxy.address, LockedFBTC.abi)

    fbtc_facade = FBTCFacade.deploy({'from': deployer})
    fbtc_facade_proxy = proxy.deploy(fbtc_facade, deployer, b'', {'from': deployer})
    fbtc_facade_transparent = Contract.from_abi("FBTCFacade", fbtc_facade_proxy.address, FBTCFacade.abi)

    generic_facade = GenericFacade.deploy({'from': deployer})
    generic_facade_proxy = proxy.deploy(generic_facade, deployer, b'', {'from': deployer})
    generic_facade_transparent = Contract.from_abi("GenericFacade", generic_facade_proxy.address, GenericFacade.abi)

    vaults = [vault_eth_transparent, vault_btc_transparent]

    # Configure contracts
    uni_btc_transparent.initialize(owner, owner, {'from': owner})
    for peer in peers:
        uni_btc_transparent.grantRole(roles[1], peer, {'from': owner})
        peer.configurePeers([chain_id, chain_id + 1], [peer_sender, peer_receiver], {'from': owner})

    vault_eth_transparent.initialize(owner, uni_btc_transparent, False, {'from': owner})
    vault_btc_transparent.initialize(owner, uni_btc_transparent, True, {'from': owner})
    for vault in vaults:
        uni_btc_transparent.grantRole(roles[1], vault, {'from': owner})

    locked_fbtc_transparent.initialize(fbtc, owner, owner, vault_btc_transparent, {'from': owner})
    fbtc_facade_transparent.initialize(vault_btc_transparent, locked_fbtc_transparent, {'from': owner})
    generic_facade_transparent.initialize(vault_btc_transparent, {'from': owner})

    return [uni_btc_transparent,        # index = 0
            peer_sender,                # index = 1
            peer_receiver,              # index = 2
            message_bus_sender,         # index = 3
            message_bus_receiver,       # index = 4
            wbtc,                       # index = 5
            vault_eth_transparent,      # index = 6
            fbtc,                       # index = 7
            xbtc,                       # index = 8
            vault_btc_transparent,      # index = 9
            wbtc18,                     # index = 10
            fbtc_facade_transparent,    # index = 11
            locked_fbtc_transparent,    # index = 12
            generic_facade_transparent] # index = 13
