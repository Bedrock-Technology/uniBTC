from brownie import Sigma, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/merlin-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=merlin-mainnet -I`


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

    print("Deployed Sigma proxy address: ", sigma_proxy)  #
    print("")
    print("Deployed Sigma implementation address: ", sigma_impl)  #


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

    # --------- Set holders of MBTC, which have 18 decimals. ---------
    mbtc = "0xB880fd278198bd590252621d4CD071b1842E9Bcd"
    mbtc_pools = [
        (mbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(mbtc, mbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(mbtc) == mbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 2

    # Check supply of MBTC
    MBTC = deps.ERC20.at(mbtc)
    assert sigma_transparent.totalSupply(mbtc) == MBTC.balanceOf(vault)

    # ---------- Set holders of WBTC, which have 8 decimals. ----------
    wbtc = "0xF6D226f9Dc15d9bB51182815b320D3fBE324e1bA"
    wbtc_pools = [
        (wbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(wbtc, wbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(wbtc) == wbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 3

    # Check supply of WBTC
    WBTC = deps.ERC20.at(wbtc)
    assert sigma_transparent.totalSupply(wbtc) == WBTC.balanceOf(vault)
