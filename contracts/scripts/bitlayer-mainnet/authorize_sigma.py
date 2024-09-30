from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/bitlayer-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=bitlayer-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xe6754009cdcb1de9fb04eeae46cbac0e4a8a48e457a7dfcd3079ec2ab58c6835
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x43904195de547d3f29ef9c9b88851a3d583a039cd0c20b7e8337778ba5e814a0
    assert not sigma_transparent.hasRole(default_admin_role, owner)
