import brownie
from brownie import *
from pathlib import Path

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    proxyAdmin = deps.ProxyAdmin
    
    deployer = accounts[0]
    owner = accounts[1] 
    user = accounts[2]
    print("deploying",deployer,owner,user)
    admin_contract = proxyAdmin.deploy({'from': deployer})
    print("admin",admin_contract)
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
    impl_redeem = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_contract, DelayRedeemRouter.abi)
    print("impl_redeem------------1",impl_redeem.redeemStartedTimestamp())
    #7 days time duration
    seven_day_time_duration = 604800
    # update timestamp
    chain.sleep(seven_day_time_duration)
    chain.mine()
    
    day_cap = 40e8
    data = DelayRedeemRouter[-1].initialize.encode_input(owner,uniBTC_proxy,vault_proxy,seven_day_time_duration,True,day_cap)
    delay_redeem_router_proxy = TransparentUpgradeableProxy.deploy(delay_redeem_router_contract, admin_contract, data, {'from': deployer})
    print("delay_redeem_router proxy",delay_redeem_router_proxy)
    
    
    transparent_delay_redeem_router = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_proxy, DelayRedeemRouter.abi)
    print("redeemStartedTimestamp-------------1",transparent_delay_redeem_router.redeemStartedTimestamp())
    #transparent_delay_redeem_router.initialize(owner,uniBTC_proxy,vault_proxy,seven_day_time_duration,True,day_cap,{'from': owner})
    print("transparent_delay_redeem_router-----1",transparent_delay_redeem_router)
    #deploy DelayRedeemRouter contract
    delay_redeem_router_contract_2 = DelayRedeemRouter.deploy(
            {'from': deployer} 
            )
    print("delay_redeem_router contract",delay_redeem_router_contract_2)
    impl_redeem_2 = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_contract_2, DelayRedeemRouter.abi)
    print("impl_redeem------2",impl_redeem_2.redeemStartedTimestamp())
    
    proxy_admin = proxyAdmin.at(admin_contract)
    current_owner = proxy_admin.owner()
    print(f"Current owner: {current_owner}")
    proxy_admin.upgrade(delay_redeem_router_proxy, impl_redeem_2,{'from': deployer})
    print("transparent_delay_redeem_router-----2",transparent_delay_redeem_router)
    print("impl_redeem------2",transparent_delay_redeem_router.redeemStartedTimestamp())
    print("impl_redeem------",transparent_delay_redeem_router.dayCap())