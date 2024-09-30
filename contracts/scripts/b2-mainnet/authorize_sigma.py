from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/b2-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=b2-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0x7adb1d0aa8919cc3499c3225ed8ee7c4edde6c9fe1fe941d4ddb6301abbf29fb
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x99c24ac1fe238ea53fec3a0cab9058f524ee6180c0a4a04f5268543c45bdc733
    assert not sigma_transparent.hasRole(default_admin_role, owner)
