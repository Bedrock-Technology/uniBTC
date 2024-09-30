from brownie import Sigma, accounts, Contract, project, config
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/mode-mainnet/authorize_sigma.py main "uniBTCMainnetAdmin" --network=mode-main -I`


def main(owner="owner"):
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    owner = accounts.load(owner)
    new_owner = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    sigma_proxy_address = "0x8Cc6D6135C7088fdb3eBFB39B11e7CB2F9853915"

    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy_address, Sigma.abi)


    # -------------------- Sigma --------------------
    # Transfer default admin role
    sigma_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: 0xe640ccb05edfd51d89078d85efc624bf487a834d1df5ef7b5346cb3d14b94848
    assert sigma_transparent.hasRole(default_admin_role, new_owner)
    sigma_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: 0x5d3e3ce4e58d74a44e012e9990852ffe8ec7b87382699e13dfb18b5fc6d9944d
    assert not sigma_transparent.hasRole(default_admin_role, owner)
