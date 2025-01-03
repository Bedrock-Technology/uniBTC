import brownie
from brownie import *
from pathlib import Path


# Command to run test: `brownie test tests/test_claimPrincipalFromRedeemRouter
def test_claimPrincipalFromRedeemRouter(deps):
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    deployer = accounts[0]
    owner = accounts[1]
    user = accounts[2]

    # deploy uniBTC contract
    uniBTC_contract = uniBTC.deploy({"from": deployer})
    print("uniBTC contract", uniBTC_contract)
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(
        uniBTC_contract, deployer, b"", {"from": deployer}
    )
    print("uniBTC proxy", uniBTC_proxy)
    transparent_uniBTC = Contract.from_abi("uniBTC", uniBTC_proxy, uniBTC.abi)
    transparent_uniBTC.initialize(owner, owner, [], {"from": owner})

    # deploy WBTC contract
    wbtc_contract = WBTC18.deploy({"from": deployer})
    print("wbtc contract", wbtc_contract)
    transparent_wbtc = Contract.from_abi("WBTC", wbtc_contract, WBTC18.abi)

    # deploy FBTC contract
    fbtc_contract = FBTC.deploy({"from": deployer})
    print("fbtc contract", fbtc_contract)
    transparent_fbtc = Contract.from_abi("FBTC", fbtc_contract, FBTC.abi)

    # deploy vault contract
    vault_contract = Vault.deploy({"from": deployer})
    print("vault contract", vault_contract)
    vault_proxy = TransparentUpgradeableProxy.deploy(
        vault_contract, deployer, b"", {"from": deployer}
    )
    print("vault proxy", vault_proxy)
    transparent_vault = Contract.from_abi("vault", vault_proxy, Vault.abi)
    transparent_vault.initialize(owner, uniBTC_proxy, {"from": owner})

    # deploy DelayRedeemRouter contract
    delay_redeem_router_contract = DelayRedeemRouter.deploy({"from": deployer})
    print("delay_redeem_router contract", delay_redeem_router_contract)
    delay_redeem_router_proxy = TransparentUpgradeableProxy.deploy(
        delay_redeem_router_contract, deployer, b"", {"from": deployer}
    )
    print("delay_redeem_router proxy", delay_redeem_router_proxy)
    transparent_delay_redeem_router = Contract.from_abi(
        "DelayRedeemRouter", delay_redeem_router_proxy, DelayRedeemRouter.abi
    )
    # 7 days time duration
    seven_day_time_duration = 604800
    transparent_delay_redeem_router.initialize(
        owner,
        uniBTC_proxy,
        vault_proxy,
        seven_day_time_duration,
        True,
        {"from": owner},
    )

    wbtc_day_cap = 10 * 10**8
    fbtc_day_cap = 8 * 10**8
    native_day_cap = 5 * 10**8
    one_day_travel = 86400
    wbtc_speed = wbtc_day_cap / one_day_travel
    fbtc_speed = fbtc_day_cap / one_day_travel
    native_speed = native_day_cap / one_day_travel

    wbtc_max_free = 10 * 10**8
    fbtc_max_free = 8 * 10**8
    native_max_free = 5 * 10**8

    tx = transparent_delay_redeem_router.setQuotaRates(
        [fbtc_contract, wbtc_contract],
        [fbtc_speed, wbtc_speed],
        {"from": owner},
    )

    tx = transparent_delay_redeem_router.setMaxQuotaForTokens(
        [fbtc_contract, wbtc_contract],
        [fbtc_max_free, wbtc_max_free],
        {"from": owner},
    )

    # mint 1000 uniBTC to user
    user_uniBTC = 1000 * 10**8
    transparent_uniBTC.mint(user, user_uniBTC, {"from": owner})
    print("user uniBTC balance", transparent_uniBTC.balanceOf(user))

    # simulate redeem case
    # call redeem router createDelayedRedeem directly
    wbtc_claim_uni = 10 * 10**8
    tx = transparent_delay_redeem_router.addToBtclist(
        [wbtc_contract, fbtc_contract], {"from": owner}
    )
    assert tx.events["BtclistAdded"]["tokens"][0] == wbtc_contract
    assert tx.events["BtclistAdded"]["tokens"][1] == fbtc_contract
    tx = transparent_delay_redeem_router.removeFromBtclist(
        [wbtc_contract, fbtc_contract], {"from": owner}
    )
    assert tx.events["BtclistRemoved"]["tokens"][0] == wbtc_contract
    assert tx.events["BtclistRemoved"]["tokens"][1] == fbtc_contract
    tx = transparent_delay_redeem_router.addToBtclist(
        [wbtc_contract], {"from": owner}
    )

    # only vault can burn uniBTC
    transparent_uniBTC.grantRole(
        transparent_uniBTC.MINTER_ROLE(), transparent_vault, {"from": owner}
    )
    assert transparent_uniBTC.hasRole(
        transparent_uniBTC.MINTER_ROLE(), transparent_vault
    )

    # call vault function need operator role
    transparent_vault.grantRole(
        transparent_vault.OPERATOR_ROLE(), delay_redeem_router_proxy, {"from": owner}
    )
    assert transparent_vault.hasRole(
        transparent_vault.OPERATOR_ROLE(), delay_redeem_router_proxy
    )

    transparent_uniBTC.approve(
        delay_redeem_router_proxy, wbtc_claim_uni, {"from": user}
    )
    assert (
        transparent_uniBTC.allowance(user, delay_redeem_router_proxy) == wbtc_claim_uni
    )

    tx = transparent_delay_redeem_router.addToWhitelist(
        [user, owner], {"from": owner}
    )
    assert tx.events["WhitelistAdded"]["accounts"][0] == user
    assert tx.events["WhitelistAdded"]["accounts"][1] == owner

    chain.sleep(one_day_travel + 100)
    chain.mine()
    user_real_wbtc_claim_uni = (
        wbtc_claim_uni
        * (
            transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
            - transparent_delay_redeem_router.redeemFeeRate()
        )
        / transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
    )
    print("user_real_wbtc_claim_uni", user_real_wbtc_claim_uni)
    tx = transparent_delay_redeem_router.createDelayedRedeem(
        wbtc_contract, wbtc_claim_uni, {"from": user}
    )
    # time travel to 7 days later
    seven_days_travel = seven_day_time_duration + 60 * 60
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 0) == True
    assert (
        transparent_delay_redeem_router.canClaimDelayedRedeemPrincipal(user, 0) == False
    )

    # set redeemPrincipalDelayTimestamp
    invalidTimestamp = 2592000 + 100
    with brownie.reverts("USR012"):
        tx = transparent_delay_redeem_router.setRedeemPrincipalDelay(
            invalidTimestamp, {"from": owner}
        )
    validTimestamp = 2 * 604800
    tx = transparent_delay_redeem_router.setRedeemPrincipalDelay(
        validTimestamp, {"from": owner}
    )
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 0) == True
    assert (
        transparent_delay_redeem_router.canClaimDelayedRedeemPrincipal(user, 0) == False
    )
    assert "RedeemPrincipalDelaySet" in tx.events
    assert (
        tx.events["RedeemPrincipalDelaySet"]["previousDelay"]
        == transparent_delay_redeem_router.MAX_REDEEM_DELAY()
    )
    assert tx.events["RedeemPrincipalDelaySet"]["newDelay"] == validTimestamp

    # time travel to 7 days later
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 0) == True
    assert (
        transparent_delay_redeem_router.canClaimDelayedRedeemPrincipal(user, 0) == True
    )

    print(
        "user delay redeems by index",
        transparent_delay_redeem_router.userDelayedRedeemByIndex(user, 0),
    )
    print(
        "user delay redeems",
        transparent_delay_redeem_router.getUserDelayedRedeems(user),
    )
    print("unibtc amount", transparent_uniBTC.balanceOf(delay_redeem_router_proxy))
    currentUniAmount = transparent_uniBTC.balanceOf(user)
    tx = transparent_delay_redeem_router.addToBlacklist([user], {"from": owner})
    assert tx.events["BlacklistAdded"]["accounts"][0] == user
    with brownie.reverts("USR009"):
        transparent_delay_redeem_router.claimPrincipals({"from": user})
    tx = transparent_delay_redeem_router.removeFromBlacklist(
        [user], {"from": owner}
    )
    assert tx.events["BlacklistRemoved"]["accounts"][0] == user
    tx = transparent_delay_redeem_router.claimPrincipals({"from": user})
    assert "DelayedRedeemsPrincipalClaimed" in tx.events
    assert "DelayedRedeemsPrincipalCompleted" in tx.events
    assert tx.events["DelayedRedeemsPrincipalClaimed"][0]["recipient"] == user
    assert (
        tx.events["DelayedRedeemsPrincipalClaimed"][0]["claimedAmount"]
        == user_real_wbtc_claim_uni
    )
    assert tx.events["DelayedRedeemsPrincipalClaimed"][0]["token"] == wbtc_contract
    assert tx.events["DelayedRedeemsPrincipalCompleted"]["recipient"] == user
    assert (
        tx.events["DelayedRedeemsPrincipalCompleted"]["principalAmount"]
        == user_real_wbtc_claim_uni
    )
    assert tx.events["DelayedRedeemsPrincipalCompleted"]["delayedRedeemsCompleted"] == 1
    assert (
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy)
        == transparent_delay_redeem_router.managementFee()
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(wbtc_contract)[1]
        == user_real_wbtc_claim_uni
    )
    assert len(transparent_delay_redeem_router.getUserDelayedRedeems(user)) == 0
    assert (
        transparent_uniBTC.balanceOf(user)
        == currentUniAmount + user_real_wbtc_claim_uni
    )
