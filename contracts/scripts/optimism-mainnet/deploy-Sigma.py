from brownie import Sigma, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/optimism-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=optimism-main -I`


def main(deployer="deployer", owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deployed core contracts
    proxy_admin = "0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19"
    vault = "0xF9775085d726E782E83585033B58606f7731AB18"

    # Deploy and initialize Sigma
    sigma_impl = Sigma.deploy({'from': deployer})
    initialize_data = sigma_impl.initialize.encode_input(owner)
    sigma_proxy = TransparentUpgradeableProxy.deploy(sigma_impl, proxy_admin, initialize_data, {'from': deployer})

    # Check initial status
    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy, Sigma.abi)
    assert sigma_transparent.hasRole(default_admin_role, owner)

    print("Deployed Sigma proxy address: ", sigma_proxy)  # 0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3
    print("")
    print("Deployed Sigma implementation address: ", sigma_impl)  # 0x12073748B427D2BB7064c3dF120ee04448AA29a0


    # ---------- Set holders of WBTC, which have 8 decimals. ---------
    wbtc = "0x68f180fcCe6836688e9084f035309E29Bf0A2095"
    wbtc_pools = [
        (wbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(wbtc, wbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(wbtc) == wbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 1

    # Check supply of WBTC
    WBTC = deps.ERC20.at(wbtc)
    assert sigma_transparent.totalSupply(wbtc) == WBTC.balanceOf(vault)




