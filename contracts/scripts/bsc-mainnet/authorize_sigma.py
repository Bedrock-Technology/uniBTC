from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/bsc-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=bsc-main -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x8Cc6D6135C7088fdb3eBFB39B11e7CB2F9853915"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xa16c2a5fcc7b0541b679b8fc3a8f16fea76816282c8520e9df7d7ce4400b1e99
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x7dc6fda5673fa5390e3fbc03e6157562f638d5ece49ac5d7b681a8edb1a7b4f5
    assert not sigma_transparent.hasRole(default_admin_role, owner)
