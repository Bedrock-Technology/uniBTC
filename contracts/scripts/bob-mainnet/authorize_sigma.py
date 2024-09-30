from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/bob-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=bob-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0x0c7be1891d28f5ebd6eac04789a6f394beae25ab951734651ed3db62fad11324
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x57e37557ed2b2d806a239737575d4c46da59c0b5d176dfad8c931a592fb9581b
    assert not sigma_transparent.hasRole(default_admin_role, owner)
