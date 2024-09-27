import random
import brownie
from brownie import accounts


def test_mintLockedFbtcRequest(fn_isolation, contracts, owner, alice, executor):
    uni_btc, vault, fbtc, fbtc_proxy, locked_fbtc = contracts[0], contracts[6], contracts[7], contracts[9], contracts[10]

    amt =  1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.OPERATOR_ROLE(), fbtc_proxy, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': executor})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_proxy.mintLockedFbtcRequest(amt, {'from': executor})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0


def test_redeemFbtcRequest(fn_isolation, contracts, owner, alice, executor):
    uni_btc, vault, fbtc, fbtc_proxy, locked_fbtc = contracts[0], contracts[6], contracts[7], contracts[9], contracts[10]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.OPERATOR_ROLE(), fbtc_proxy, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': executor})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_proxy.mintLockedFbtcRequest(amt, {'from': executor})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_proxy.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': executor})
    assert 'RedeemFbtcRequest' in tx.events


def test_confirmRedeemFbtc(fn_isolation, contracts, owner, alice, executor):
    uni_btc, vault, fbtc, fbtc_proxy, locked_fbtc = contracts[0], contracts[6], contracts[7], contracts[9], contracts[10]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.OPERATOR_ROLE(), fbtc_proxy, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': executor})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_proxy.mintLockedFbtcRequest(amt, {'from': executor})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_proxy.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': executor})
    assert 'RedeemFbtcRequest' in tx.events

    # Confirm redeem request
    tx = fbtc_proxy.confirmRedeemFbtc(real_amt, {'from': executor})
    assert 'ConfirmRedeemFbtc' in tx.events
    assert locked_fbtc.balanceOf(vault) == 0
    assert fbtc.balanceOf(vault) == real_amt

def test_burn(fn_isolation, contracts, owner, alice, executor):
    uni_btc, vault, fbtc, fbtc_proxy, locked_fbtc = contracts[0], contracts[6], contracts[7], contracts[9], contracts[10]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.OPERATOR_ROLE(), fbtc_proxy, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': executor})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_proxy.mintLockedFbtcRequest(amt, {'from': executor})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_proxy.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': executor})
    assert 'RedeemFbtcRequest' in tx.events

#     # Confirm redeem request
#     tx = fbtc_proxy.confirmRedeemFbtc(real_amt, {'from': executor})
#     assert 'ConfirmRedeemFbtc' in tx.events
#     assert locked_fbtc.balanceOf(vault) == 0
#     assert fbtc.balanceOf(vault) == real_amt

    # Burn request
    tx = fbtc_proxy.burn(real_amt, {'from': executor})
    assert locked_fbtc.balanceOf(vault) == 0