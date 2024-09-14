import brownie
from brownie import *
from pathlib import Path

# Command to run test: `brownie test tests/test_delayRedeemRouterSimulate.py
def test_claimFromRedeemRouter(deps):
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    
    deployer = accounts[0]
    owner = accounts[1] 
    user = accounts[2]
    # deploy uniBTC contract
    uniBTC_contract = uniBTC.deploy(
            {'from': deployer} 
            )
    print("uniBTC contract",uniBTC_contract)
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(
            uniBTC_contract, deployer, b'',
            {'from': deployer})
    print("uniBTC proxy",uniBTC_proxy)
    transparent_uniBTC = Contract.from_abi("uniBTC",uniBTC_proxy, uniBTC.abi)
    transparent_uniBTC.initialize(owner,owner, {'from': owner})
    
    # deploy WBTC contract    
    wbtc_contract = WBTC.deploy(
            {'from': deployer} 
            )
    print("wbtc contract",wbtc_contract)
    transparent_wbtc = Contract.from_abi("WBTC",wbtc_contract, WBTC.abi)

    #deploy FBTC contract
    fbtc_contract = FBTC.deploy(
            {'from': deployer} 
            )
    print("fbtc contract",fbtc_contract)
    transparent_fbtc = Contract.from_abi("FBTC",fbtc_contract, FBTC.abi)

    #deploy vault contract
    vault_contract = Vault.deploy(
            {'from': deployer} 
            )
    print("vault contract",vault_contract)
    vault_proxy = TransparentUpgradeableProxy.deploy(vault_contract, deployer, b'', {'from': deployer})
    print("vault proxy",vault_proxy)
    transparent_vault = Contract.from_abi("vault",vault_proxy, Vault.abi)
    transparent_vault.initialize(owner, uniBTC_proxy, {'from': owner})
    
    #deploy DelayRedeemRouter contract
    delay_redeem_router_contract = DelayRedeemRouter.deploy(
            {'from': deployer} 
            )
    print("delay_redeem_router contract",delay_redeem_router_contract)
    delay_redeem_router_proxy = TransparentUpgradeableProxy.deploy(delay_redeem_router_contract, deployer, b'', {'from': deployer})
    print("delay_redeem_router proxy",delay_redeem_router_proxy)
    transparent_delay_redeem_router = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_proxy, DelayRedeemRouter.abi)
    #7 days time duration
    seven_day_time_duration = 604800
    day_cap = 40e8
    transparent_delay_redeem_router.initialize(owner,uniBTC_proxy,vault_proxy,seven_day_time_duration,True,day_cap,{'from': owner})
    assert transparent_delay_redeem_router.getAvailableCap() == day_cap
    
    #mint 1000 WBTC to owner
    transparent_wbtc.mint(owner,1000*10**8,{'from': deployer})
    print("owner wbtc balance",transparent_wbtc.balanceOf(owner))
    
    #mint 1000 FBTC to owner
    transparent_fbtc.mint(owner,1000*10**8,{'from': deployer})
    print("owner fbtc balance",transparent_fbtc.balanceOf(owner))
    
    #mint 1000 uniBTC to user
    user_uniBTC = 1000*10**8
    transparent_uniBTC.mint(user,user_uniBTC,{'from': owner})
    print("user uniBTC balance",transparent_uniBTC.balanceOf(user))
    
    #simulate redeem case
    #call redeem router createDelayedRedeem directly
    fbtc_claim = 60*10**8
    wbtc_claim = 10*10**8
    with brownie.reverts("USR009"):
         transparent_delay_redeem_router.createDelayedRedeem(fbtc_contract,fbtc_claim,{'from': user})
   
    transparent_delay_redeem_router.addToWhitelist(user,{'from': owner})
    
    with brownie.reverts("SYS003"):
         transparent_delay_redeem_router.createDelayedRedeem(fbtc_contract,fbtc_claim,{'from': user})
         
    transparent_delay_redeem_router.addToWrapBtcList(fbtc_contract,{'from': owner})
    transparent_delay_redeem_router.addToWrapBtcList(wbtc_contract,{'from': owner})   
    
    with brownie.reverts("USR010"):
         transparent_delay_redeem_router.createDelayedRedeem(fbtc_contract,fbtc_claim,{'from': user})   
    
    fbtc_claim = 10*10**8
    
    #only vault can burn uniBTC
    transparent_uniBTC.grantRole(transparent_uniBTC.MINTER_ROLE(), transparent_vault, {'from': owner}) 
    assert transparent_uniBTC.hasRole(transparent_uniBTC.MINTER_ROLE(), transparent_vault)
    
    #call vault function need operator role
    transparent_vault.grantRole(transparent_vault.OPERATOR_ROLE(), delay_redeem_router_proxy, {'from': owner}) 
    assert transparent_vault.hasRole(transparent_vault.OPERATOR_ROLE(), delay_redeem_router_proxy)
    
    transparent_uniBTC.approve(delay_redeem_router_proxy,fbtc_claim,{'from': user})
    assert transparent_uniBTC.allowance(user, delay_redeem_router_proxy) == fbtc_claim
    tx = transparent_delay_redeem_router.createDelayedRedeem(fbtc_contract,fbtc_claim,{'from': user})   
    
    #check some status 
    assert "DelayedRedeemCreated" in tx.events
    assert tx.events["DelayedRedeemCreated"]["recipient"] == user
    assert tx.events["DelayedRedeemCreated"]["token"] == fbtc_contract
    assert tx.events["DelayedRedeemCreated"]["amount"] == fbtc_claim
    assert tx.events["DelayedRedeemCreated"]["index"] == 0
    assert transparent_uniBTC.balanceOf(user) == user_uniBTC - fbtc_claim
    assert transparent_uniBTC.balanceOf(delay_redeem_router_proxy) == fbtc_claim
    assert transparent_delay_redeem_router.userRedeemsLength(user) == 1
    print("tokenDebts fbtc_contract",transparent_delay_redeem_router.tokenDebts(fbtc_contract))
    assert transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0] == fbtc_claim
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user,0) == False
    assert transparent_delay_redeem_router.getAvailableCap() == day_cap - fbtc_claim
    
    transparent_delay_redeem_router.claimDelayedRedeems({'from': user})
    assert transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0] == fbtc_claim
    
    # time travel to 7 days later
    seven_days_travel = seven_day_time_duration + 60*60
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user,0) == True
    
    assert transparent_delay_redeem_router.getAvailableCap() == 8*day_cap - fbtc_claim
    newday_cap = 1
    transparent_delay_redeem_router.setDayCap(newday_cap,{'from': owner})
    assert transparent_delay_redeem_router.getAvailableCap() == 8*day_cap - fbtc_claim    
    
    transparent_uniBTC.approve(delay_redeem_router_proxy,wbtc_claim,{'from': user})
    assert transparent_uniBTC.allowance(user, delay_redeem_router_proxy) == wbtc_claim
    tx = transparent_delay_redeem_router.createDelayedRedeem(wbtc_contract,wbtc_claim,{'from': user})
    assert "DelayedRedeemCreated" in tx.events
    assert tx.events["DelayedRedeemCreated"]["recipient"] == user
    assert tx.events["DelayedRedeemCreated"]["token"] == wbtc_contract
    assert tx.events["DelayedRedeemCreated"]["amount"] == wbtc_claim
    assert tx.events["DelayedRedeemCreated"]["index"] == 1
    assert transparent_uniBTC.balanceOf(user) == user_uniBTC - fbtc_claim - wbtc_claim
    assert transparent_uniBTC.balanceOf(delay_redeem_router_proxy) == fbtc_claim + wbtc_claim
    assert transparent_delay_redeem_router.userRedeemsLength(user) == 2
    assert transparent_delay_redeem_router.tokenDebts(fbtc_contract)[0] == fbtc_claim
    assert transparent_delay_redeem_router.tokenDebts(wbtc_contract)[0] == wbtc_claim
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user,1) == False
    assert transparent_delay_redeem_router.getAvailableCap() == 8*day_cap - fbtc_claim - wbtc_claim
    # time travel to 7 days later
    # update timestamp
    chain.sleep(seven_days_travel)
    chain.mine()
    assert transparent_delay_redeem_router.getAvailableCap() == 8*day_cap + 7*newday_cap - fbtc_claim - wbtc_claim
    assert transparent_delay_redeem_router.canClaimDelayedRedeem(user,1) == True
    
    router_fbtc_balance = 20*10**8
    router_wbtc_balance = 20*10**8
    fbtc_contract.transfer(delay_redeem_router_proxy,router_fbtc_balance,{'from': owner})
    wbtc_contract.transfer(delay_redeem_router_proxy,router_wbtc_balance,{'from': owner})  
    print("fbtc balance",fbtc_contract.balanceOf(delay_redeem_router_proxy))
    print("wbtc balance",wbtc_contract.balanceOf(delay_redeem_router_proxy))   
    
    print("user delay redeems by index",transparent_delay_redeem_router.userDelayedRedeemByIndex(user,0))
    print("user delay redeems by index",transparent_delay_redeem_router.userDelayedRedeemByIndex(user,1))
    print("user delay redeems",transparent_delay_redeem_router.getUserDelayedRedeems(user))
    print("burn unibtc amount",transparent_uniBTC.balanceOf(delay_redeem_router_proxy))
    tx=transparent_delay_redeem_router.claimDelayedRedeems({'from': user})
    assert "DelayedRedeemsClaimed" in tx.events
    assert "DelayedRedeemsCompleted" in tx.events
    assert tx.events["DelayedRedeemsClaimed"][0]["recipient"] == user
    assert tx.events["DelayedRedeemsClaimed"][0]["amountClaimed"] == fbtc_claim
    assert tx.events["DelayedRedeemsClaimed"][0]["token"] == fbtc_contract
    assert tx.events["DelayedRedeemsClaimed"][1]["recipient"] == user
    assert tx.events["DelayedRedeemsClaimed"][1]["amountClaimed"] == wbtc_claim
    assert tx.events["DelayedRedeemsClaimed"][1]["token"] == wbtc_contract
    assert tx.events["DelayedRedeemsCompleted"]["amountBurned"] == fbtc_claim + wbtc_claim
    assert tx.events["DelayedRedeemsCompleted"]["delayedRedeemsCompleted"] == 2
    assert transparent_uniBTC.balanceOf(delay_redeem_router_proxy) == 0
    assert wbtc_contract.balanceOf(user) == wbtc_claim
    assert fbtc_contract.balanceOf(user) == fbtc_claim
    assert transparent_delay_redeem_router.tokenDebts(fbtc_contract)[1] == wbtc_claim
    assert transparent_delay_redeem_router.tokenDebts(wbtc_contract)[1] == fbtc_claim
    assert len(transparent_delay_redeem_router.getUserDelayedRedeems(user)) == 0