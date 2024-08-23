import brownie
from brownie import interface, accounts, Vault, MBTCProxy, Contract


# NOTE: This test designed to run on the fork Merlin network
# Command to run test: `brownie test tests/test_MBTCProxy.py --network=merlin-mainnet-fork`
def test_swapMBTCToBTC(fn_isolation, deps, deployer):
    # Upgrade Vault
    ProxyAdmin = deps.ProxyAdmin
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    multisig = accounts.at("0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB", True)
    owner = accounts.at("0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB", True)

    vault_proxy = TransparentUpgradeableProxy.at("0xF9775085d726E782E83585033B58606f7731AB18")
    proxyAdmin = ProxyAdmin.at("0x0A3f2582FF649Fcaf67D03483a8ED1A82745Ea19")

    vault_impl = Vault.deploy({'from': deployer})
    proxyAdmin.upgrade(vault_proxy, vault_impl, {'from': multisig})

    vault = Contract.from_abi("Vault",vault_proxy, Vault.abi)

    # Deploy MBTCProxy
    m_btc = interface.IERC20("0xB880fd278198bd590252621d4CD071b1842E9Bcd")
    m_token_swap = interface.IMTokenSwap("0x72A817715f174a32303e8C33cDCd25E0dACfE60b")
    btc_layer2_bridge = interface.IBTCLayer2Bridge("0x28AD6b7dfD79153659cb44C2155cf7C0e1CeEccC")

    m_btc_proxy = MBTCProxy.deploy(vault, m_btc, m_token_swap, {'from': owner})

    assert m_btc_proxy.owner() == owner

    assert m_btc_proxy.vault() == vault
    assert m_btc_proxy.mBTC() == m_btc
    assert m_btc_proxy.mTokenSwap() == m_token_swap
    assert m_btc_proxy.btcLayer2Bridge() ==   btc_layer2_bridge

    bridge_fee = m_btc_proxy.getBridgeFee()
    assert bridge_fee == 100000000000000

    vault.grantRole(vault.OPERATOR_ROLE(), m_btc_proxy, {'from': owner})
    assert vault.hasRole(vault.OPERATOR_ROLE(), m_btc_proxy)

    # Swap M-BTC to BTC
    m_btc_balance_before = m_btc.balanceOf(vault)
    amount = bridge_fee * 2
    dest_btc_addr = "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2"
    tx = m_btc_proxy.swapMBTCToBTC(amount, dest_btc_addr, {'from': owner})
    assert 'SwapBtc' in tx.events   # Emitted by MTokenSwap.swapMBtc function
    assert 'UnlockNativeToken' in tx.events   # Emitted by BTCLayer2Bridge.unlockNativeToken function
    assert 'LockNativeTokenWithBridgeFee' in tx.events   # Emitted by BTCLayer2Bridge.lockNativeToken function
    assert m_btc.balanceOf(vault) == m_btc_balance_before - amount


