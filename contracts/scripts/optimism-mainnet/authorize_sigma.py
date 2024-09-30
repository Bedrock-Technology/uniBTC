from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/optimism-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=optimism-main -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0x0de6b12352497219a5ed12d5e46eb8fdc9d0ebd2691d34e57d35bb4bec97abc5
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0xfd35811368ee271fdd6daf78c7bff91ff6761ebd9561b01f8b4089d9f1e9400e
    assert not sigma_transparent.hasRole(default_admin_role, owner)
