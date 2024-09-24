from brownie import Sigma, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/mantle-mainnet/deploy-Sigma.py main "uniBTCMainnetDeployer" "uniBTCMainnetAdmin" --network=mantle-mainnet -I`


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





