from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/arbitrum-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=arbitrum-main -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x8Cc6D6135C7088fdb3eBFB39B11e7CB2F9853915"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xe16e9e880fda65c21120b4c6c090551df12f5cdf216513753c946b17a53a980b
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x98f1c3fe5b783e637cd509e91fc425ca446f7c106a4e046b23f2cd2995acca6c
    assert not sigma_transparent.hasRole(default_admin_role, owner)
