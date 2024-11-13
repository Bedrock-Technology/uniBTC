import brownie
from brownie import *
from pathlib import Path


# Command to run test: `brownie test tests/test_delayRedeemRouterSimulate.py
def test_claimFromRedeemRouter(deps):
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    deployer = accounts[0]
    owner = accounts[1]
    user = accounts[2]

    native_token = "0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF"
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

    # mint 1000 WBTC to owner
    transparent_wbtc.mint(owner, 1000 * 10**18, {"from": deployer})
    print("owner wbtc balance", transparent_wbtc.balanceOf(owner))

    # mint 1000 FBTC to owner
    transparent_fbtc.mint(owner, 1000 * 10**8, {"from": deployer})
    print("owner fbtc balance", transparent_fbtc.balanceOf(owner))

    # mint 1000 uniBTC to user
    user_uniBTC = 1000 * 10**8
    transparent_uniBTC.mint(user, user_uniBTC, {"from": owner})
    print("user uniBTC balance", transparent_uniBTC.balanceOf(user))

    # simulate redeem case
    # call redeem router createDelayedRedeem directly
    fbtc_claim_uni = 8 * 10**8
    wbtc_claim_uni = 10 * 10**8
    native_claim_uni = 5 * 10**8
    with brownie.reverts("USR009"):
        transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni, {"from": user}
        )

    transparent_delay_redeem_router.addAccountsToWhitelist([user], {"from": owner})
    with brownie.reverts("SYS003"):
        transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni, {"from": user}
        )

    tx = transparent_delay_redeem_router.setRedeemQuotaPerSecond(
        [fbtc_contract, wbtc_contract, native_token],
        [fbtc_speed, wbtc_speed, native_speed],
        {"from": owner},
    )
    assert "RedeemQuotaPerSecondSet" in tx.events
    assert tx.events["RedeemQuotaPerSecondSet"][0]["token"] == fbtc_contract
    assert tx.events["RedeemQuotaPerSecondSet"][0]["previousQuota"] == 0
    assert tx.events["RedeemQuotaPerSecondSet"][0]["newQuota"] == fbtc_speed
    assert tx.events["RedeemQuotaPerSecondSet"][1]["token"] == wbtc_contract
    assert tx.events["RedeemQuotaPerSecondSet"][1]["previousQuota"] == 0
    assert tx.events["RedeemQuotaPerSecondSet"][1]["newQuota"] == wbtc_speed
    assert tx.events["RedeemQuotaPerSecondSet"][2]["token"] == native_token
    assert tx.events["RedeemQuotaPerSecondSet"][2]["previousQuota"] == 0
    assert tx.events["RedeemQuotaPerSecondSet"][2]["newQuota"] == native_speed

    tx = transparent_delay_redeem_router.setMaxFreeQuotasForTokens(
        [fbtc_contract, wbtc_contract, native_token],
        [fbtc_max_free, wbtc_max_free, native_max_free],
        {"from": owner},
    )
    assert "MaxFreeQuotasSet" in tx.events
    assert tx.events["MaxFreeQuotasSet"][0]["token"] == fbtc_contract
    assert tx.events["MaxFreeQuotasSet"][0]["previousQuota"] == 0
    assert tx.events["MaxFreeQuotasSet"][0]["newQuota"] == fbtc_max_free
    assert tx.events["MaxFreeQuotasSet"][1]["token"] == wbtc_contract
    assert tx.events["MaxFreeQuotasSet"][1]["previousQuota"] == 0
    assert tx.events["MaxFreeQuotasSet"][1]["newQuota"] == wbtc_max_free
    assert tx.events["MaxFreeQuotasSet"][2]["token"] == native_token
    assert tx.events["MaxFreeQuotasSet"][2]["previousQuota"] == 0
    assert tx.events["MaxFreeQuotasSet"][2]["newQuota"] == native_max_free

    transparent_delay_redeem_router.addTokensToBtclist(
        [fbtc_contract, wbtc_contract, native_token], {"from": owner}
    )
    transparent_delay_redeem_router.removeTokensFromBtclist(
        [fbtc_contract, wbtc_contract, native_token], {"from": owner}
    )
    transparent_delay_redeem_router.addTokensToBtclist(
        [fbtc_contract, wbtc_contract, native_token], {"from": owner}
    )

    transparent_delay_redeem_router.pauseTokens(
        [fbtc_contract], {"from": owner}
    )
    with brownie.reverts("SYS003"):
        transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni, {"from": user}
        )
    transparent_delay_redeem_router.unpauseTokens(
        [fbtc_contract], {"from": owner}
    )
    with brownie.reverts("USR010"):
        transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni, {"from": user}
        )

    half_day_travel = int(one_day_travel / 2)
    chain.sleep(half_day_travel)
    chain.mine()
    with brownie.reverts("USR010"):
        transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni, {"from": user}
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
    transparent_vault.allowTarget(
        [uniBTC_proxy, wbtc_contract, fbtc_contract, delay_redeem_router_proxy],
        {"from": owner},
    )

    transparent_uniBTC.approve(
        delay_redeem_router_proxy, fbtc_claim_uni, {"from": user}
    )
    assert (
        transparent_uniBTC.allowance(user, delay_redeem_router_proxy) == fbtc_claim_uni
    )
    chain.sleep(one_day_travel * 7)
    chain.mine()
    with brownie.reverts("USR010"):
        tx = transparent_delay_redeem_router.createDelayedRedeem(
            fbtc_contract, fbtc_claim_uni * 3, {"from": user}
        )

    tx = transparent_delay_redeem_router.createDelayedRedeem(
        fbtc_contract, fbtc_claim_uni, {"from": user}
    )
    # check some status
    assert (
        transparent_delay_redeem_router.redeemFeeRate()
        == transparent_delay_redeem_router.DEFAULT_REDEEM_FEE_RATE()
    )
    user_real_fbtc_claim_uni = (
        fbtc_claim_uni
        * (
            transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
            - transparent_delay_redeem_router.redeemFeeRate()
        )
        / transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
    )
    print("user_real_fbtc_claim_uni", user_real_fbtc_claim_uni)
    assert "DelayedRedeemCreated" in tx.events
    assert tx.events["DelayedRedeemCreated"]["recipient"] == user
    assert tx.events["DelayedRedeemCreated"]["token"] == fbtc_contract
    assert tx.events["DelayedRedeemCreated"]["amount"] == user_real_fbtc_claim_uni
    assert tx.events["DelayedRedeemCreated"]["index"] == 0
    assert (
        tx.events["DelayedRedeemCreated"]["redeemFee"]
        == fbtc_claim_uni - user_real_fbtc_claim_uni
    )
    assert transparent_uniBTC.balanceOf(user) == user_uniBTC - fbtc_claim_uni
    assert transparent_uniBTC.balanceOf(delay_redeem_router_proxy) == fbtc_claim_uni
    assert transparent_delay_redeem_router.userRedeemsLength(user) == 1
    print(
        "tokenDebts fbtc_contract",
        transparent_delay_redeem_router.tokenDebts(fbtc_contract),
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0]
        == user_real_fbtc_claim_uni
    )
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 0) == False

    transparent_delay_redeem_router.claimDelayedRedeems({"from": user})
    assert (
        transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0]
        == user_real_fbtc_claim_uni
    )

    manageFee = fbtc_claim_uni - user_real_fbtc_claim_uni
    print("manageFee", manageFee)
    assert transparent_delay_redeem_router.managementFee() == manageFee

    # time travel to 7 days later
    seven_days_travel = seven_day_time_duration + 60 * 60
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 0) == True

    tx = transparent_delay_redeem_router.setRedeemQuotaPerSecond(
        [wbtc_contract],
        [wbtc_speed],
        {"from": owner},
    )

    transparent_uniBTC.approve(
        delay_redeem_router_proxy, wbtc_claim_uni, {"from": user}
    )
    assert (
        transparent_uniBTC.allowance(user, delay_redeem_router_proxy) == wbtc_claim_uni
    )

    tx = transparent_delay_redeem_router.setRedeemFeeRate(100, {"from": owner})
    assert "RedeemFeeRateSet" in tx.events
    assert tx.events["RedeemFeeRateSet"]["previousFeeRate"] == 200
    assert tx.events["RedeemFeeRateSet"]["newFeeRate"] == 100
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
    assert "DelayedRedeemCreated" in tx.events
    assert tx.events["DelayedRedeemCreated"]["recipient"] == user
    assert tx.events["DelayedRedeemCreated"]["token"] == wbtc_contract
    assert tx.events["DelayedRedeemCreated"]["amount"] == user_real_wbtc_claim_uni
    assert tx.events["DelayedRedeemCreated"]["index"] == 1
    assert tx.events["DelayedRedeemCreated"]["redeemFee"] == wbtc_claim_uni - user_real_wbtc_claim_uni
    assert (
        transparent_uniBTC.balanceOf(user)
        == user_uniBTC - fbtc_claim_uni - wbtc_claim_uni
    )
    assert (
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy)
        == fbtc_claim_uni + wbtc_claim_uni
    )
    assert transparent_delay_redeem_router.userRedeemsLength(user) == 2
    assert (
        transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0]
        == user_real_fbtc_claim_uni
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(wbtc_contract)[0]
        == user_real_wbtc_claim_uni
    )
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 1) == False
    manageFee += wbtc_claim_uni - user_real_wbtc_claim_uni
    print("manageFee now", manageFee)
    assert transparent_delay_redeem_router.managementFee() == manageFee
    print("unibtc balance of accounts[4]", transparent_uniBTC.balanceOf(accounts[4]))
    tx = transparent_delay_redeem_router.withdrawManagementFee(
        manageFee, accounts[4], {"from": owner}
    )
    assert "ManagementFeeWithdrawn" in tx.events
    assert tx.events["ManagementFeeWithdrawn"]["recipient"] == accounts[4]
    assert tx.events["ManagementFeeWithdrawn"]["amount"] == manageFee
    print(
        "unibtc balance of accounts[4] now", transparent_uniBTC.balanceOf(accounts[4])
    )

    # create native token delayed redeem
    transparent_uniBTC.approve(
        delay_redeem_router_proxy, native_claim_uni, {"from": user}
    )
    assert (
        transparent_uniBTC.allowance(user, delay_redeem_router_proxy)
        == native_claim_uni
    )

    user_real_native_claim_uni = (
        native_claim_uni
        * (
            transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
            - transparent_delay_redeem_router.redeemFeeRate()
        )
        / transparent_delay_redeem_router.REDEEM_FEE_RATE_RANGE()
    )
    print("user_real_native_claim_uni", user_real_native_claim_uni)
    tx = transparent_delay_redeem_router.createDelayedRedeem(
        native_token, native_claim_uni, {"from": user}
    )

    # time travel to 7 days later
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user, 1) == True

    vault_fbtc_balance = 20 * 10**8
    vault_wbtc_balance = 20 * 10**18
    vault_native_balance = 200 * 10**18
    fbtc_contract.transfer(vault_proxy, vault_fbtc_balance, {"from": owner})
    wbtc_contract.transfer(vault_proxy, vault_wbtc_balance, {"from": owner})
    print("native owner balance", owner.balance())
    owner.transfer(vault_proxy, vault_native_balance)
    print("fbtc balance", fbtc_contract.balanceOf(vault_proxy))
    print("wbtc balance", wbtc_contract.balanceOf(vault_proxy))
    print("native balance", web3.eth.get_balance(vault_proxy.address))

    # update timestamp
    """
    chain.sleep(2592000)
    chain.mine()
    print("burn unibtc amount",transparent_uniBTC.balanceOf(delay_redeem_router_proxy),"user unibtc value",transparent_uniBTC.balanceOf(user))
    userBeforeUniBTC = transparent_uniBTC.balanceOf(user)
    tx=transparent_delay_redeem_router.claimPrincipals({'from': user})
    print("burn unibtc amount",transparent_uniBTC.balanceOf(delay_redeem_router_proxy),"user unibtc value",transparent_uniBTC.balanceOf(user))
    userAfterUniBTC = transparent_uniBTC.balanceOf(user)
    assert userBeforeUniBTC+ user_real_fbtc_claim_uni + user_real_wbtc_claim_uni + user_real_native_claim_uni == userAfterUniBTC
    """
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "user unibtc value",
        transparent_uniBTC.balanceOf(user),
    )
    userBeforeUniBTC = transparent_uniBTC.balanceOf(user)
    tx = transparent_delay_redeem_router.claimPrincipals({"from": user})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "user unibtc value",
        transparent_uniBTC.balanceOf(user),
    )
    userAfterUniBTC = transparent_uniBTC.balanceOf(user)
    assert userBeforeUniBTC == userAfterUniBTC

    print(
        "user delay redeems by index",
        transparent_delay_redeem_router.userDelayedRedeemByIndex(user, 0),
    )
    print(
        "user delay redeems by index",
        transparent_delay_redeem_router.userDelayedRedeemByIndex(user, 1),
    )
    print(
        "user delay redeems",
        transparent_delay_redeem_router.getUserDelayedRedeems(user),
    )
    print("burn unibtc amount", transparent_uniBTC.balanceOf(delay_redeem_router_proxy))
    native_origin = user.balance()
    transparent_delay_redeem_router.addAccountsToBlacklist([user], {"from": owner})
    with brownie.reverts("USR009"):
        transparent_delay_redeem_router.claimDelayedRedeems({"from": user})
    transparent_delay_redeem_router.removeAccountsFromBlacklist([user], {"from": owner})

    transparent_delay_redeem_router.pauseTokens(
        [fbtc_contract], {"from": owner}
    )
    with brownie.reverts("SYS003"):
        tx = transparent_delay_redeem_router.claimDelayedRedeems({"from": user})
    transparent_delay_redeem_router.unpauseTokens(
        [fbtc_contract], {"from": owner}
    )
    tx = transparent_delay_redeem_router.claimDelayedRedeems({"from": user})
    assert "DelayedRedeemsClaimed" in tx.events
    assert "DelayedRedeemsCompleted" in tx.events
    assert tx.events["DelayedRedeemsClaimed"][0]["recipient"] == user
    assert (
        tx.events["DelayedRedeemsClaimed"][0]["amountClaimed"]
        == user_real_fbtc_claim_uni
    )
    assert tx.events["DelayedRedeemsClaimed"][0]["token"] == fbtc_contract
    assert tx.events["DelayedRedeemsClaimed"][1]["recipient"] == user
    assert (
        tx.events["DelayedRedeemsClaimed"][1]["amountClaimed"]
        == user_real_wbtc_claim_uni
        * transparent_delay_redeem_router.EXCHANGE_RATE_BASE()
    )
    assert tx.events["DelayedRedeemsClaimed"][1]["token"] == wbtc_contract
    assert (
        tx.events["DelayedRedeemsCompleted"]["amountBurned"]
        == user_real_fbtc_claim_uni
        + user_real_wbtc_claim_uni
        + user_real_native_claim_uni
    )
    assert tx.events["DelayedRedeemsCompleted"]["delayedRedeemsCompleted"] == 3
    assert (
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy)
        == transparent_delay_redeem_router.managementFee()
    )
    assert (
        wbtc_contract.balanceOf(user)
        == user_real_wbtc_claim_uni
        * transparent_delay_redeem_router.EXCHANGE_RATE_BASE()
    )
    assert fbtc_contract.balanceOf(user) == user_real_fbtc_claim_uni
    assert (
        user.balance()
        == native_origin
        + user_real_native_claim_uni
        * transparent_delay_redeem_router.EXCHANGE_RATE_BASE()
    )
    assert (
        web3.eth.get_balance(vault_proxy.address)
        == vault_native_balance
        - user_real_native_claim_uni
        * transparent_delay_redeem_router.EXCHANGE_RATE_BASE()
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(fbtc_contract)[1]
        == user_real_fbtc_claim_uni
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(wbtc_contract)[1]
        == user_real_wbtc_claim_uni
    )
    assert (
        transparent_delay_redeem_router.tokenDebts(native_token)[1]
        == user_real_native_claim_uni
    )
    # check the debt status
    assert len(transparent_delay_redeem_router.getUserDelayedRedeems(user)) == 0

    # double check the claim logic
    transparent_uniBTC.mint(delay_redeem_router_proxy, user_uniBTC, {"from": owner})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "wbtc_contract value",
        wbtc_contract.balanceOf(user),
        "fbtc_contract value",
        fbtc_contract.balanceOf(user),
        "native balance",
        user.balance(),
    )
    tx = transparent_delay_redeem_router.claimDelayedRedeems(0, {"from": user})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "wbtc_contract value",
        wbtc_contract.balanceOf(user),
        "fbtc_contract value",
        fbtc_contract.balanceOf(user),
        "native balance",
        user.balance(),
    )
    tx = transparent_delay_redeem_router.claimDelayedRedeems(1, {"from": user})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "wbtc_contract value",
        wbtc_contract.balanceOf(user),
        "fbtc_contract value",
        fbtc_contract.balanceOf(user),
        "native balance",
        user.balance(),
    )
    tx = transparent_delay_redeem_router.claimDelayedRedeems({"from": user})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "wbtc_contract value",
        wbtc_contract.balanceOf(user),
        "fbtc_contract value",
        fbtc_contract.balanceOf(user),
        "native balance",
        user.balance(),
    )
    # update timestamp
    chain.sleep(2592000)
    chain.mine()
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "user unibtc value",
        transparent_uniBTC.balanceOf(user),
    )
    userBeforeUniBTC = transparent_uniBTC.balanceOf(user)
    tx = transparent_delay_redeem_router.claimPrincipals({"from": user})
    print(
        "burn unibtc amount",
        transparent_uniBTC.balanceOf(delay_redeem_router_proxy),
        "user unibtc value",
        transparent_uniBTC.balanceOf(user),
    )
    userAfterUniBTC = transparent_uniBTC.balanceOf(user)
    assert userBeforeUniBTC == userAfterUniBTC
