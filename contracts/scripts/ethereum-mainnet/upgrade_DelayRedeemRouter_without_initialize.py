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
    delay_redeem_router_proxy = TransparentUpgradeableProxy.at("0xBB45B3a09BFfC15747D1a331775Fa408e587f38d")
    
     # ABI encode the call to `upgradeTo` using the function selector
    upgrade_to_selector = web3.keccak(text="upgradeTo(address)").hex()[:10]  # This gives the first 4 bytes (function selector)
    
    # Encode the full calldata: function selector + new logic address
    calldata = upgrade_to_selector + delay_redeem_router_contract.address[2:].rjust(64, '0')  # Remove the '0x' prefix from the address

    # Send the transaction from the admin account, triggering the fallback to call `upgradeTo`
    tx = deployer.transfer(delay_redeem_router_proxy.address, data=calldata)
    print(f"Transaction sent: {tx.txid}")

    # Verify the upgrade by checking the current implementation address
    #bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1) = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
    implementation_slot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
    implementation_address = web3.to_hex(web3.eth.get_storage_at(delay_redeem_router_proxy.address, implementation_slot))[26:]
    print(f"New implementation address: {implementation_address}")

    # Ensure the implementation address matches the new logic contract
    assert implementation_address.lower() == delay_redeem_router_contract.address[2:].lower()
    transparent_delay_redeem_router = Contract.from_abi("DelayRedeemRouter",delay_redeem_router_proxy, DelayRedeemRouter.abi)