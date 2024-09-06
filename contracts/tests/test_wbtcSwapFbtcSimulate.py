import brownie
import pytest
from brownie import *

TEST_LIST = ["default_slippage", "custom_slippage"]
# NOTE: This test designed to run on the fork Ethereum network
# Command to run test: `brownie test tests/test_wbtcSwapFbtcSimulate.py --network=mainnet-fork --case=default_slippage`
# Command to run test: `brownie test tests/test_wbtcSwapFbtcSimulate.py --network=mainnet-fork --case=custom_slippage`
def test_swapWBTCToFBTC(deps,request):
    test_case = request.config.getoption("case")
    assert test_case in TEST_LIST
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    owner = accounts.at('0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3', {'force':True})
    vault = "0x047d41f2544b7f63a8e991af2068a363d210d6da"
    router = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45"
    pool = "0x9dbe5dFfAEB4Ac2e0ac14F8B4e08b3bc55De5232"
    
    #deploy swap wbtc contract and check prameters correctly
    wbtc_swap_fbtc_contract = WBTCSwapFBTCProxy.deploy(vault,router,pool, {'from': owner})
    print("deploying wbtc_swap_fbtc_contract contract",wbtc_swap_fbtc_contract)
    assert wbtc_swap_fbtc_contract.owner() == owner
    assert wbtc_swap_fbtc_contract.BEDROCK_VAULT() == vault
    assert wbtc_swap_fbtc_contract.UNISWAP_V3_ROUTER_02() ==  router
    assert wbtc_swap_fbtc_contract.UNISWAP_WBTC_FBTC_POOL() == pool
    
    wbtc = wbtc_swap_fbtc_contract.WBTC()
    fbtc = wbtc_swap_fbtc_contract.FBTC()
    print("WBTC address",wbtc,"FBTC address",fbtc)
    
    #grand swap wbtc contract to vault operator role and record the vault balances before swapping
    vault_proxy = TransparentUpgradeableProxy.at("0x047d41f2544b7f63a8e991af2068a363d210d6da")
    vault = Contract.from_abi("Vault",vault_proxy, Vault.abi)
    vault.grantRole(vault.OPERATOR_ROLE(), wbtc_swap_fbtc_contract, {'from': owner})
    wbtc_erc20 = interface.IERC20(wbtc)
    fbtc_erc20 = interface.IERC20(fbtc)
    vault_wbtc_balance = wbtc_erc20.balanceOf(vault)
    vault_fbtc_balance = fbtc_erc20.balanceOf(vault)
    print("Balance of WBTC in vault",vault_wbtc_balance,"balance of FBTC in vault",vault_fbtc_balance)
    
    #swap wbtc to fbtc
    depth = wbtc_swap_fbtc_contract.getUniswapWbtcForFbtcDepth()
    print("pool wbtc depth is",depth[0],"fbtc depth is",depth[1])
    
    wbtc_value = 100000000
    slippage = 0

    #test different swap function
    test_case = TEST_LIST[1]
    revert = False
    if test_case == TEST_LIST[0] :
        slippage = 100
        revert = custom_slippage(wbtc_swap_fbtc_contract,wbtc_value,slippage,owner)
    else:
        slippage = wbtc_swap_fbtc_contract.SLIPPAGE_DEFAULT()
        revert = default_slippage(wbtc_swap_fbtc_contract,wbtc_value,owner)
    
    vault_wbtc_now_balance = wbtc_erc20.balanceOf(vault)
    vault_fbtc_now_balance = fbtc_erc20.balanceOf(vault)
    print("Balance of WBTC in vault after swapping",vault_wbtc_now_balance,"balance of FBTC in vault after swapping",vault_fbtc_now_balance)
    if revert == True:
        assert vault_fbtc_now_balance == vault_fbtc_balance
        assert vault_wbtc_now_balance == vault_wbtc_balance
        return
    
    assert vault_wbtc_now_balance+wbtc_value == vault_wbtc_balance
    assert vault_fbtc_now_balance > vault_fbtc_balance
    
    fbtc_increse = vault_fbtc_now_balance - vault_fbtc_balance
    realRatio = fbtc_increse / wbtc_value
    slippageRatio = slippage/wbtc_swap_fbtc_contract.SLIPPAGE_RANGE()
    print("real ratio",realRatio,"slippage ratio",slippageRatio)
    assert realRatio >= 1-slippageRatio
    

    
def custom_slippage(wbtc_swap_fbtc_contract,wbtc_value,slippage,owner):
    try:
        tx = wbtc_swap_fbtc_contract.swapWBTCForFBTC(wbtc_value, slippage, {'from': owner})
        return False
    except brownie.exceptions.VirtualMachineError as e:   
        print("Swap failed with slippage",slippage)
        return True
   
def default_slippage(wbtc_swap_fbtc_contract,wbtc_value,owner):
    try:
        tx = wbtc_swap_fbtc_contract.swapWBTCForFBTC(wbtc_value, {'from': owner})
        return False
    except brownie.exceptions.VirtualMachineError as e:
        print("Swap failed with default slippage") 
        return True
    
