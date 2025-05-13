from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/unibtc_holesky_deploy.py main "holesky-deployer" "holesky-owner" --network=Holesky`


def main(deployer="deployer", owner="owner"):
    deps = project.load(
        Path.home() / ".brownie" / "packages" / config["dependencies"][0]
    )
    proxy = deps.TransparentUpgradeableProxy
    proxyAdmin = deps.ProxyAdmin

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deploy contracts
    proxy_admin = proxyAdmin.deploy({"from": owner})

    fbtc = FBTC.deploy({"from": owner})
    wbtc = WBTC.deploy({"from": owner})
    wbtc18 = WBTC18.deploy({"from": owner})

    supplyFeeder = Sigma.deploy({"from": deployer})
    supplyFeeder_proxy = proxy.deploy(
        supplyFeeder, proxy_admin, b"", {"from": deployer}
    )
    supplyFeeder_transparent = Contract.from_abi(
        "sigma", supplyFeeder_proxy.address, Sigma.abi
    )

    uni_btc = uniBTC.deploy({"from": deployer})
    uni_btc_proxy = proxy.deploy(uni_btc, proxy_admin, b"", {"from": deployer})
    uni_btc_transparent = Contract.from_abi("uniBTC", uni_btc_proxy.address, uniBTC.abi)

    vault = VaultWithoutNative.deploy({"from": deployer})
    vault_proxy = proxy.deploy(vault, proxy_admin, b"", {"from": deployer})
    vault_transparent = Contract.from_abi("Vault", vault_proxy.address, Vault.abi)

    # Initialize contracts
    uni_btc_transparent.initialize(owner, owner, [], {"from": owner})
    vault_transparent.initialize(owner, uni_btc_transparent, {"from": owner})
    vault_transparent.setSupplyFeeder(supplyFeeder_proxy, {"from": owner})
    supplyFeeder_transparent.initialize(owner, {"from": owner})

    # Grant MINTER_ROLE
    minters = [vault_transparent]
    for minter in minters:
        uni_btc_transparent.grantRole(
            uni_btc_transparent.MINTER_ROLE(), minter, {"from": owner}
        )

    config_contact = {
        "holesky": {
            "uniBTC_proxy": uni_btc_proxy,
            "vault_proxy": vault_proxy,
            "redeem_owner": owner,
            "redeem_time_duration": 1800,  # 8 days time duration
            "whitelist_enabled": True,
            "contract_deployer": proxy_admin,  # deployer account
        },
    }
    # deploy DelayRedeemRouter contract
    delay_redeem_router_contract = DelayRedeemRouter.deploy({"from": deployer})
    print("delay_redeem_router contract", delay_redeem_router_contract)
    network_cfg = "holesky"
    data = DelayRedeemRouter[-1].initialize.encode_input(
        config_contact[network_cfg]["redeem_owner"],
        config_contact[network_cfg]["uniBTC_proxy"],
        config_contact[network_cfg]["vault_proxy"],
        config_contact[network_cfg]["redeem_time_duration"],
        config_contact[network_cfg]["whitelist_enabled"],
    )
    delay_redeem_router_proxy = proxy.deploy(
        delay_redeem_router_contract,
        config_contact[network_cfg]["contract_deployer"],
        data,
        {"from": deployer},
    )
    print("delay_redeem_router proxy", delay_redeem_router_proxy)
    transparent_delay_redeem_router = Contract.from_abi(
        "DelayRedeemRouter", delay_redeem_router_proxy, DelayRedeemRouter.abi
    )
    # Check status
    assert fbtc.mintableGroup(owner)
    assert wbtc.mintableGroup(owner)
    assert wbtc18.mintableGroup(owner)

    assert fbtc.decimals() == 8
    assert wbtc.decimals() == 8
    assert wbtc18.decimals() == 18

    assert vault_transparent.uniBTC() == uni_btc_transparent
    assert uni_btc_transparent.hasRole(
        uni_btc_transparent.MINTER_ROLE(), vault_transparent
    )
    default_admin_role = transparent_delay_redeem_router.DEFAULT_ADMIN_ROLE()
    assert (
        transparent_delay_redeem_router.hasRole(
            default_admin_role, config_contact[network_cfg]["redeem_owner"]
        )
        == True
    )

    print("Deployed ProxyAdmin address: ", proxy_admin)
    print("Deployed FBTC address: ", fbtc)
    print("Deployed WBTC address: ", wbtc)
    print("Deployed WBTC18 address: ", wbtc18)
    print("Deployed SupplyFeeder address: ", supplyFeeder)
    print("Deployed uniBTC proxy address: ", uni_btc_transparent)
    print("Deployed Vault proxy address: ", vault_transparent)
    print("Deployed DelayRedeemRouter proxy address: ", transparent_delay_redeem_router)
    print("Deployed uniBTC address: ", uni_btc)
    print("Deployed Vault address: ", vault)
    print("Deployed DelayRedeemRouter address", delay_redeem_router_contract)
    print("Deployed SupplyFeeder proxy address", supplyFeeder_proxy)

    '''
    vault_transparent.allowTarget(
        [uni_btc_transparent, wbtc, fbtc, wbtc18, delay_redeem_router_proxy],
        {"from": owner},
    )
    vault_transparent.grantRole(
        vault_transparent.OPERATOR_ROLE(), delay_redeem_router_proxy, {"from": owner}
    )
    vault_transparent.allowToken(
        [wbtc, fbtc, wbtc18],
        {"from": owner},
    )
    vault_transparent.setCap(
        wbtc,
        1000 * 10**8,
        {"from": owner},
    )
    vault_transparent.setCap(
        fbtc,
        1000 * 10**8,
        {"from": owner},
    )
    vault_transparent.setCap(
        wbtc18,
        1000 * 10**18,
        {"from": owner},
    )

    transparent_delay_redeem_router.addToWhitelist(
        ["0x0C99B08F2233b04066fe13A0A1Bf1474416fD77F"],
        {"from": owner},
    )

    transparent_delay_redeem_router.addToBtclist(
        [wbtc, fbtc, wbtc18],
        {"from": owner},
    )
    one_day = 86400
    quota_per_second = 30 * 10**8 / one_day
    quota_max = 10 * 10**8

    transparent_delay_redeem_router.setQuotaRates(
        [wbtc, fbtc, wbtc18],
        [quota_per_second, quota_per_second, quota_per_second],
        {"from": owner},
    )
    transparent_delay_redeem_router.setMaxQuotaForTokens(
        [wbtc, fbtc, wbtc18],
        [quota_max, quota_max, quota_max],
        {"from": owner},
    )

    fbtc.mint(
        "0xe8A335a8502625Fb6c6e900a547694770D764484", 100 * 10**8, {"from": owner}
    )
    wbtc18.mint(
        "0xe8A335a8502625Fb6c6e900a547694770D764484", 100 * 10**18, {"from": owner}
    )
    wbtc.mint(
        "0xe8A335a8502625Fb6c6e900a547694770D764484", 100 * 10**8, {"from": owner}
    )

    pools = [
        (wbtc, [vault_proxy]),
    ]
    supplyFeeder_transparent.setTokenHolders(wbtc, pools, {"from": owner})
    pools = [
        (fbtc, [vault_proxy]),
    ]
    supplyFeeder_transparent.setTokenHolders(fbtc, pools, {"from": owner})
    pools = [
        (wbtc18, [vault_proxy]),
    ]
    supplyFeeder_transparent.setTokenHolders(wbtc18, pools, {"from": owner})
    
    wbtc.mint(
        deployer, 100 * 10**8, {"from": owner}
    )
    wbtc.approve(vault_proxy, 100 * 10**8, {"from": deployer})
    vault_transparent.mint(wbtc, 10 * 10**8, {"from": deployer})
    
    uni_btc_transparent.approve(delay_redeem_router_proxy, 1 * 10**8, {"from": deployer})
    transparent_delay_redeem_router.createDelayedRedeem(wbtc, 1 * 10**8, {"from": deployer})
    transparent_delay_redeem_router.addToWhitelist(
        [deployer],
        {"from": owner},
    )
    transparent_delay_redeem_router.claimDelayedRedeems({"from": deployer})
    transparent_delay_redeem_router.claimPrincipals({"from": deployer})
    transparent_delay_redeem_router.setWhitelistEnabled(False,{"from": owner})
    transparent_delay_redeem_router.setRedeemPrincipalDelay(3600,{"from": owner})
    
    fbtc.setMintable("0x3d80157EC69D933945E33698c6C0B564Fc17AeEb",True,{"from": owner})
    wbtc.setMintable("0x3d80157EC69D933945E33698c6C0B564Fc17AeEb",True,{"from": owner})
    wbtc18.setMintable("0x3d80157EC69D933945E33698c6C0B564Fc17AeEb",True,{"from": owner})
    '''
