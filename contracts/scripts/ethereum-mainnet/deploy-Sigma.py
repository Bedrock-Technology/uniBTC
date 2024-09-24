from brownie import Sigma, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/ethereum-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=eth-mainnet -I`


def main(deployer="deployer", owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deployed core contracts
    proxy_admin = "0x029E4FbDAa31DE075dD74B2238222A08233978f6"
    vault = "0x047d41f2544b7f63a8e991af2068a363d210d6da"

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


    # --------- Set holders of FBTC, which have 8 decimals. ---------
    fbtc = "0xc96de26018a54d51c097160568752c4e3bd6c364"
    locked_fbtc = "0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c"
    fbtc_pools = [
        (fbtc, (vault,)),
        (locked_fbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(fbtc, fbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(fbtc) == fbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 1

    # Check supply of FBTC
    FBTC = deps.ERC20.at(fbtc)
    LockedFBTC = deps.ERC20.at(locked_fbtc)
    assert sigma_transparent.totalSupply(fbtc) == FBTC.balanceOf(vault) + LockedFBTC.balanceOf(vault)

    # ---------- Set holders of WBTC, which have 8 decimals. ---------
    wbtc = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
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

    # ---------- Set holders of cbBTC, which have 8 decimals. ----------
    cbbtc = "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"
    cbbtc_pools = [
        (cbbtc, (vault,))
    ]
    tx = sigma_transparent.setTokenHolders(cbbtc, cbbtc_pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma_transparent.getTokenHolders(cbbtc) == cbbtc_pools
    assert len(sigma_transparent.ListLeadingTokens()) == 3

    # Check supply of cbBTC
    cbBTC = deps.ERC20.at(cbbtc)
    assert sigma_transparent.totalSupply(cbbtc) == cbBTC.balanceOf(vault)





