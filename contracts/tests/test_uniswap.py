import brownie
from web3 import Web3
from brownie import *
from pathlib import Path

# Command to run test: `brownie test tests/test_uniswapv2.py --network=mainnet-fork`
def test_OneInchSwapProxy(deps):
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    router = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
    pool = "0x9dbe5dFfAEB4Ac2e0ac14F8B4e08b3bc55De5232"
    vault = "0x047D41F2544B7F63A8e991aF2068a363d210d6Da"
    owner = accounts.at('0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3', {'force':True})
    srcToken = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    dstToken = "0xC96dE26018A54D51c097160568752c4E3BD6C364"
    src_swap_dst_contract = SwapProxy.deploy(vault, srcToken, dstToken,{'from': owner})
    print("deploying src_swap_dst_contract contract",src_swap_dst_contract)
    assert src_swap_dst_contract.owner() == owner
    
    srcToken_erc20 = interface.IERC20(srcToken)
    dstToken_erc20 = interface.IERC20(dstToken)
    vault_src_balance = srcToken_erc20.balanceOf(vault)
    vault_dst_balance = dstToken_erc20.balanceOf(vault) 
    print("Balance of srcToken in vault",vault_src_balance,"balance of dstToken in vault",vault_dst_balance)   
    
    errProtocol = generate_bytes32_from_hash("OneInch")
    with brownie.reverts("USR021"):
        src_swap_dst_contract.addRouter(router, errProtocol, {'from': owner});
    src_swap_dst_contract.addRouter(router, src_swap_dst_contract.UNISWAP_V3_PROTOCOL(), {'from': owner});
    with brownie.reverts("USR020"):
        src_swap_dst_contract.addRouter(router, src_swap_dst_contract.UNISWAP_V3_PROTOCOL(), {'from': owner});  
    with brownie.reverts("USR021"):
        src_swap_dst_contract.addPool(pool, errProtocol, {'from': owner});     
    src_swap_dst_contract.addPool(pool, src_swap_dst_contract.UNISWAP_V3_PROTOCOL(), {'from': owner}); 
    src_swap_dst_contract.addPool(pool, src_swap_dst_contract.UNISWAP_V3_PROTOCOL(), {'from': owner});    
    amountIn = 1*10**8
    amountOut = 99*10**7
    revert,amount = custom_slippage(src_swap_dst_contract,amountIn,amountOut,pool,owner) 
    print("rerevert,amount",revert,amount)
    check_swap_result(srcToken_erc20,dstToken_erc20,revert,amount,vault_src_balance,vault_dst_balance,owner,amountIn)

def generate_bytes32_from_hash(data):
    return Web3.keccak(text=data)    
  
def custom_slippage(src_swap_dst_contract,amountIn,amountOut,pool,owner):
    try:
        tx = src_swap_dst_contract.swapToken(amountIn,amountOut,pool, {'from': owner})
        assert "SwapSuccessAmount" in tx.events
        print("Swap success with real amount",tx.events["SwapSuccessAmount"]["amount"])
        return False,tx.events["SwapSuccessAmount"]["amount"]
    except brownie.exceptions.VirtualMachineError as e:   
        return True,0 
    
def check_swap_result(srcToken_erc20,dstToken_erc20,revert,amount,vault_src_balance,vault_dst_balance,vault,src_value):
    vault_src_now_balance = srcToken_erc20.balanceOf(vault)
    vault_dst_now_balance = dstToken_erc20.balanceOf(vault)
    print("Balance of srcToken in vault after swapping",vault_src_now_balance,"balance of dstToken in vault after swapping",vault_dst_now_balance)
    assert src_value < 0
    if revert == True:
        assert vault_src_now_balance == vault_src_balance
        assert vault_dst_now_balance == vault_dst_balance
        return
    
    assert vault_src_now_balance+src_value == vault_src_balance
    assert vault_dst_now_balance > vault_dst_balance
    dstToken_increse = vault_dst_now_balance - vault_dst_balance
    assert dstToken_increse < amount        