from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/zeta-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=zeta-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x8Cc6D6135C7088fdb3eBFB39B11e7CB2F9853915"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0x6d1063c33bab9252e1bda1a39517cbc5f316ef0f7f1c36b854345e291d501242
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x3ae13b58d0c888a926fba03b42b007ad5f5fdbe75aa6bac5a6b3941144578814
    assert not sigma_transparent.hasRole(default_admin_role, owner)
