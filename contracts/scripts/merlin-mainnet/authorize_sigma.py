from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/merlin-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=merlin-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)

    gas_limit = '2000000'
    gas_price = '100000000'

    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner, 'gas_limit': gas_limit, 'gas_price': gas_price})     # Tx: 0x8d87432f1bdd4c8c9df92c3d87ad918f7bb33cf4b5c02dc458bc632e07c0fc59
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner, 'gas_limit': gas_limit, 'gas_price': gas_price})      # Tx: 0xf43492487d64127e8584eff74ed168eb4910cbb3892729917041366123974891
    assert not sigma_transparent.hasRole(default_admin_role, owner)
