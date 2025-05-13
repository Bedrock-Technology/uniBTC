import brownie
from brownie import *
from pathlib import Path

def main():
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    ProxyAdmin = deps.ProxyAdmin
   
    deployer = accounts.at('0x3eea50ba10952E5e0dFAa50EcFCc5AB19aD591Ef', {'force':True})
    owner = accounts.at('0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32', {'force':True})
    delay_redeem_router_proxy = TransparentUpgradeableProxy.at("0xBB45B3a09BFfC15747D1a331775Fa408e587f38d")
    transparent_proxy = Contract.from_abi("TransparentUpgradeableProxy",delay_redeem_router_proxy, TransparentUpgradeableProxy.abi)
    proxy_admin = ProxyAdmin.at("0x029E4FbDAa31DE075dD74B2238222A08233978f6")
    '''
    selector = web3.keccak(text="changeAdmin(address)")[0:4]  
    new_admin_bytes = bytes.fromhex(proxy_admin.address[2:].rjust(64, "0"))
    calldata = selector + new_admin_bytes
    tx = deployer.transfer(delay_redeem_router_proxy.address, data=calldata)
    assert tx.status == 1, "Transaction failed!"
    assert proxy_admin.getProxyAdmin("0xBB45B3a09BFfC15747D1a331775Fa408e587f38d")==proxy_admin.address, "changeAdmin failed"
    '''
    
    '''
    delay_redeem_router_proxy = TransparentUpgradeableProxy.at("0xBB45B3a09BFfC15747D1a331775Fa408e587f38d")
    new_admin = "0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32"
    selector = web3.keccak(text="changeAdmin(address)")[0:4]  
    new_admin_bytes = bytes.fromhex(new_admin[2:].rjust(64, "0"))
    calldata = selector + new_admin_bytes
    tx = deployer.transfer(delay_redeem_router_proxy.address, data=calldata)
    assert tx.status == 1, "Transaction failed!"
    
    selectorAdmin = web3.keccak(text="admin()")[:4]
    raw_admin_bytes = web3.eth.call({"from": owner.address,"to": delay_redeem_router_proxy.address, "data": selectorAdmin})
    admin_address = web3.to_checksum_address("0x" + raw_admin_bytes.hex()[-40:])
    print(f"✅ Proxy Admin address: {admin_address}")
    assert admin_address == new_admin, "changeAdmin failed"
    '''
    
    
    
    

    
    