from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/mantle-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=mantle-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xb7b3b739537d8f68b8ca9e256738c3335dbb053215fa71e17fd80131ab60b6f9
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x96a9cdba7fd2cef53f7c02e7cf894ffb040c8f6e0f7743752f663eb3ea1d1da5
    assert not sigma_transparent.hasRole(default_admin_role, owner)
