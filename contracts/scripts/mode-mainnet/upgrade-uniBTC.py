from brownie import uniBTC, accounts, Contract, project, config
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/mode-mainnet/upgrade-uniBTC.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=mode-main -I`

def main(deployer="deployer", default_admin="default_admin", ):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    ProxyAdmin = deps.ProxyAdmin

    deployer = accounts.load(deployer)
    default_admin = accounts.load(default_admin)

    vault_proxy_address = "0x84E5C854A7fF9F49c888d69DECa578D406C26800"

    # Deployed contracts
    proxy_admin = ProxyAdmin.at("0xb3f925B430C60bA467F7729975D5151c8DE26698")
    uni_btc = uniBTC.at("0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a")

    # Check permissions before upgrade
    assert uni_btc.hasRole(uni_btc.DEFAULT_ADMIN_ROLE(), default_admin)
    assert  uni_btc.hasRole(uni_btc.MINTER_ROLE(), vault_proxy_address)

    # Upgrade uniBTC
    frozen_users = []   # TODO: Add frozen users

    uniBTC_impl = uniBTC.deploy({'from': deployer})
    reinitialize_data = uniBTC_impl.initialize.encode_input(default_admin, vault_proxy_address, frozen_users)
    proxy_admin.upgradeAndCall(uni_btc.address, uniBTC_impl.address, reinitialize_data, {'from': default_admin})

    # Check contract status after upgrade
    assert uni_btc.hasRole(uni_btc.DEFAULT_ADMIN_ROLE(), default_admin)
    assert uni_btc.hasRole(uni_btc.MINTER_ROLE(), vault_proxy_address)

    assert uni_btc.decimals() == 8
    assert uni_btc.symbol() == "uniBTC"
    assert uni_btc.name() == "uniBTC"

    assert uni_btc.freezeToRecipient() == "0x899c284A89E113056a72dC9ade5b60E80DD3c94f"
    for user in frozen_users:
        assert uni_btc.frozenUsers(user)

    print("Deployed uniBTC implementation: ", uniBTC_impl)  #

