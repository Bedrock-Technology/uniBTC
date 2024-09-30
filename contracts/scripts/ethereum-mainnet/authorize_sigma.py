from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/ethereum-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=eth-mainnet -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xe1680b9313ce303bfefd54147f43bf146ba081bb7387ad4f4505897a493277f1
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x73e62c23b1a8849128e73bc700fc36fc4322ee8b1469735ac466a3ac47a7e0b7
    assert not sigma_transparent.hasRole(default_admin_role, owner)
