import brownie
from brownie import *
from pathlib import Path

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
   
    deployer = accounts.load("rockx-eben")
    #deploy DelayRedeemRouter contract
    delay_redeem_router_contract = DelayRedeemRouter.deploy(
            {'from': deployer} 
            )
    print("delay_redeem_router contract",delay_redeem_router_contract)
    redeem_owner = "0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32"
    uniBTC_proxy = "0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568"
    vault_proxy = "0x047D41F2544B7F63A8e991aF2068a363d210d6Da"
    #8 days time duration
    redeem_time_duration = 691200
    day_cap = 0
    data = DelayRedeemRouter[-1].initialize.encode_input(redeem_owner,uniBTC_proxy,vault_proxy,redeem_time_duration,True,day_cap)
    delay_redeem_router_proxy = TransparentUpgradeableProxy.deploy(delay_redeem_router_contract, deployer, data, {'from': deployer})
    print("delay_redeem_router proxy",delay_redeem_router_proxy)
    
    transparent_delay_redeem_router = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_proxy, DelayRedeemRouter.abi)