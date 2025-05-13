import brownie
import json
from brownie import *
from pathlib import Path

# Command to run test: `brownie test tests/test_curve.py --network=mainnet-fork`
def test_CurveSwapProxy(deps):
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    router = "0x16C6521Dff6baB339122a0FE25a9116693265353"
    srcToken = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    dstToken = "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"
    pool = "0x839d6bDeDFF886404A6d7a788ef241e4e28F4802"
    owner = accounts.at('0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3', {'force':True})
    swapName = "srcSwapdst"
    src_swap_dst_contract = CurveSwapProxy.deploy(router,pool, srcToken, dstToken,{'from': owner})
    print("deploying src_swap_dst_contract contract",src_swap_dst_contract)
    assert src_swap_dst_contract.owner() == owner
    
    srcTokenOwner = accounts.at('0x70FBb965302D50D1783a2337Cb115B30Ae9C4638', {'force':True})
    srcToken_erc20 = interface.IERC20(srcToken)
    dstToken_erc20 = interface.IERC20(dstToken)
    srcToken_erc20.transfer(src_swap_dst_contract,2*10**8,{'from': srcTokenOwner})
    vault_src_balance = srcToken_erc20.balanceOf(src_swap_dst_contract)
    vault_dst_balance = dstToken_erc20.balanceOf(src_swap_dst_contract) 
    print("Balance of srcToken in vault",vault_src_balance,"balance of dstToken in vault",vault_dst_balance)   
    
    pool_path = [srcToken,dstToken]
    amountIn = 1*10**8
    amountOut = 98*10**6
    tx = src_swap_dst_contract.swapToken(amountIn,amountOut, {'from': owner})
    assert "SwapSuccessAmount" in tx.events
    print("Swap success with real amount",tx.events["SwapSuccessAmount"]["amount"])
    amount = tx.events["SwapSuccessAmount"]["amount"]
    revert = False
    print("rerevert,amount",revert,amount)
    check_swap_result(srcToken_erc20,dstToken_erc20,revert,amount,vault_src_balance,vault_dst_balance,src_swap_dst_contract,amountIn)

def test_CurveSwapProxyEOA(deps):  
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    with open('/Users/eben/rockx-project/rockx-contract/hanson/uniBTC/contracts/tests/curv.json') as abi_file:
        abi = json.load(abi_file)
    router = "0x16C6521Dff6baB339122a0FE25a9116693265353"
    srcToken = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599"
    dstToken = "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf"
    pool = "0x839d6bDeDFF886404A6d7a788ef241e4e28F4802"
    # Load contract using ABI
    curvecontract = Contract.from_abi("ExchangeContract", router, abi)
    #curvecontract = Contract.from_explorer(router)
    zero_addr = "0x0000000000000000000000000000000000000000"
    route = [srcToken, pool, dstToken,zero_addr,zero_addr,zero_addr,zero_addr,zero_addr,zero_addr,zero_addr,zero_addr]  # Replace with actual addresses
    swap_params = [[0,1,1,10,2], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0]]
    amount = 100000000  # The amount you want to swap
    min_dy = 95000000   # The minimum acceptable amount after swap
    pools = [pool,zero_addr,zero_addr,zero_addr,zero_addr]
    srcTokenOwner = accounts.at('0x70FBb965302D50D1783a2337Cb115B30Ae9C4638', {'force':True})
    amoutOut = curvecontract.get_dy(route, swap_params, amount, pools)
    print("amoutOut",amoutOut)
    # Execute the function and send transaction
    srcToken_erc20 = interface.IERC20(srcToken)
    srcToken_erc20.approve(router, amount, {'from': srcTokenOwner})
    tx = curvecontract.exchange(route, swap_params, amount, min_dy,pools, {'from': srcTokenOwner})
    

  
def custom_slippage(src_swap_dst_contract,amountIn,amountOut,owner):
    try:
        tx = src_swap_dst_contract.swapToken(amountIn,amountOut, {'from': owner})
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