from brownie import Sigma, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/b2-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=b2-mainnet -I`


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

    print("Deployed Sigma proxy address: ", sigma_proxy)  # 0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a
    print("")
    print("Deployed Sigma implementation address: ", sigma_impl)  # 0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3

    # ---------- Set holders of native BTC, which have 18 decimals. ----------
    native_btc = "0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF"
    native_btc_pools = [
        (native_btc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(native_btc, native_btc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(native_btc) == native_btc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 1

    # Check supply of native BTC
    vault_transparent = Contract.from_abi("Vault", vault, Vault.abi)
    assert sigma_transparent.totalSupply(native_btc) == vault_transparent.balance()

    # ---------- Set holders of WBTC, which have 8 decimals. ----------
    wbtc = "0x4200000000000000000000000000000000000006"
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