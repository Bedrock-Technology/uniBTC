from brownie import uniBTC, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/bob-mainnet/authorize.py main "owner" --network=bob-mainnet -I`


# The command to run this script: `brownie run scripts/authorize/mainnet.py  --network=iotex-mainnet`


def main(owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    ProxyAdmin = deps.ProxyAdmin

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")
    pauser_role = w3.keccak(text='PAUSER_ROLE')
    minter_role = w3.keccak(text='MINTER_ROLE')

    owner = accounts.load(owner)
    new_owner = "0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32"

    proxyAdmin_address = "0x56c3024eB229Ca0570479644c78Af9D53472B3e4"
    uniBTC_proxy_address = "0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894"
    vault_proxy_address = "0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf"

    proxyAdmin = ProxyAdmin.at(proxyAdmin_address)
    uniBTC_transparent = Contract.from_abi("uniBTC", uniBTC_proxy_address, uniBTC.abi)
    vault_transparent = Contract.from_abi("Vault", vault_proxy_address, Vault.abi)


    # -------------------- uniBTC --------------------
    # Transfer default admin role
    uniBTC_transparent.grantRole(default_admin_role, new_owner, {'from': owner})
    assert uniBTC_transparent.hasRole(default_admin_role, new_owner)
    uniBTC_transparent.renounceRole(default_admin_role, owner, {'from': owner})
    assert not uniBTC_transparent.hasRole(default_admin_role, owner)


    # -------------------- Vault --------------------
    # Transfer pauser role
    vault_transparent.grantRole(pauser_role, new_owner, {'from': owner})
    assert vault_transparent.hasRole(pauser_role, new_owner)
    vault_transparent.renounceRole(pauser_role, owner, {'from': owner})
    assert not vault_transparent.hasRole(pauser_role, owner)

    # Transfer default admin role
    vault_transparent.grantRole(default_admin_role, new_owner, {'from': owner})
    assert vault_transparent.hasRole(default_admin_role, new_owner)
    vault_transparent.renounceRole(default_admin_role, owner, {'from': owner})
    assert not vault_transparent.hasRole(default_admin_role, owner)

    # -------------------- ProxyAdmin --------------------
    # Transfer ownership
    proxyAdmin.transferOwnership(new_owner, {'from': owner})
    assert proxyAdmin.owner() == new_owner