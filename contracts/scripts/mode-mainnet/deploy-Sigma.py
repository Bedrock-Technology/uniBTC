from brownie import Sigma, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/mode-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=mode-main -I`


def main(deployer="deployer", owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deployed core contracts
    proxy_admin = "0xb3f925B430C60bA467F7729975D5151c8DE26698"
    vault = "0x84E5C854A7fF9F49c888d69DECa578D406C26800"

    # Deploy and initialize Sigma
    sigma_impl = Sigma.deploy({'from': deployer})
    initialize_data = sigma_impl.initialize.encode_input(owner)
    sigma_proxy = TransparentUpgradeableProxy.deploy(sigma_impl, proxy_admin, initialize_data, {'from': deployer})

    # Check initial status
    sigma_transparent = Contract.from_abi("Sigma", sigma_proxy, Sigma.abi)
    assert sigma_transparent.hasRole(default_admin_role, owner)

    # --------- Set holders of MBTC, which have 18 decimals. ---------
    mbtc = "0x59889b7021243dB5B1e065385F918316cD90D46c"
    mbtc_pools = [
        (mbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(mbtc, mbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(mbtc) == mbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 1

    # Check supply of MBTC
    MBTC = deps.ERC20.at(mbtc)
    assert sigma_transparent.totalSupply(mbtc) == MBTC.balanceOf(vault)

    # ---------- Set holders of WBTC, which have 8 decimals. ----------
    wbtc = "0xcDd475325D6F564d27247D1DddBb0DAc6fA0a5CF"
    wbtc_pools = [
        (wbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(wbtc, wbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(wbtc) == wbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 2

    # Check supply of WBTC
    WBTC = deps.ERC20.at(wbtc)
    assert sigma_transparent.totalSupply(wbtc) == WBTC.balanceOf(vault)

    print("Deployed Sigma proxy address: ", sigma_proxy)  # 0x8Cc6D6135C7088fdb3eBFB39B11e7CB2F9853915
    print("")
    print("Deployed Sigma implementation address: ", sigma_impl)  # 0x1F6C2e81F09174D076aA19AFd7C9c67D0e257B5a
