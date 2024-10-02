from brownie.exceptions import VirtualMachineError
from brownie import Sigma, accounts, Contract, project, config
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/merlin-mainnet/upgrade-Sigma.py --network=merlin-mainnet -I`

# NOTE: This script has been tested on the forked network.

def main(deployer="mainnet-deployer", proxy_admin_owner="mainnet-owner"):
    deps = project.load(Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin

    # The following two lines of code for forked network testing
#     deployer = accounts.at(accounts[0], True)
#     proxy_admin_owner = accounts.at("0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB", True)

    deployer = accounts.load(deployer)
    proxy_admin_owner = accounts.load(proxy_admin_owner)

    sigma_default_admin = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # ========== Pre-Upgrade Check ==========
    proxy_admin = ProxyAdmin.at("0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19")
    sigma_proxy = TransparentUpgradeableProxy.at("0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a")
    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy.address, Sigma.abi)

    assert proxy_admin.owner() == proxy_admin_owner.address
    assert proxy_admin.getProxyAdmin(sigma_proxy) == proxy_admin.address
    assert sigma_transparent.hasRole(sigma_transparent.DEFAULT_ADMIN_ROLE(), sigma_default_admin)
    print("✅ [1/4] Pre-upgrade check done.")

    # ========== Upgrade Sigma ==========
    sigma_impl = Sigma.deploy({'from': deployer})
    print("✅ [2/4] Sigma implementation deployed: ", sigma_impl)

    proxy_admin.upgrade(sigma_proxy.address, sigma_impl, {'from': proxy_admin_owner})
    assert proxy_admin.getProxyImplementation(sigma_proxy) == sigma_impl
    print("✅ [3/4] Sigma proxy upgraded.")

    # ========== Post-Upgrade Check ==========
    # Scenario 1 [revert]: 'totalSupply' should revert if the given leading token not registered yet
    # USR018: NO_POOLS_FOR_LEADING_TOKEN
    fake_unregistered_leading_token = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"
    try:
        sigma_transparent.totalSupply(fake_unregistered_leading_token)
    except VirtualMachineError as e:
        if "USR018" in str(e):
            print("'totalSupply' reverted as expected with 'USR018' error")
        else:
            print(f"❌ 'totalSupply' reverted with an unexpected error: {str(e)}")
    else:
        print("'❌ totalSupply' did not revert as expected")

    # Scenario 2 [success]: 'totalSupply' should return normally for already registered leading tokens
    leading_tokens = [
        "0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF",    # BTC
        "0xB880fd278198bd590252621d4CD071b1842E9Bcd"     # M-BTC
    ]
    for leading_token in leading_tokens:
        assert len(sigma_transparent.getTokenHolders(leading_token)) > 0
        assert sigma_transparent.totalSupply(leading_token) >= 0

    print("✅ [4/4] Post-upgrade check done.")




