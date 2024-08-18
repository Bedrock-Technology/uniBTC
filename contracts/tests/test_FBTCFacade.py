import random
import brownie
from brownie import accounts


def test_mintLockedFbtcRequest(fn_isolation, contracts, owner, alice):
    uni_btc, vault, fbtc, fbtc_facade, locked_fbtc = contracts[0], contracts[9], contracts[7], contracts[11], contracts[12]

    amt =  1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), fbtc_facade, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': owner})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_facade.mintLockedFbtcRequest(amt, {'from': owner})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0


def test_redeemFbtcRequest(fn_isolation, contracts, owner, alice):
    uni_btc, vault, fbtc, fbtc_facade, locked_fbtc = contracts[0], contracts[9], contracts[7], contracts[11], contracts[12]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), fbtc_facade, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': owner})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_facade.mintLockedFbtcRequest(amt, {'from': owner})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_facade.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': owner})
    assert 'RedeemFbtcRequest' in tx.events


def test_confirmRedeemFbtc(fn_isolation, contracts, owner, alice):
    uni_btc, vault, fbtc, fbtc_facade, locked_fbtc = contracts[0], contracts[9], contracts[7], contracts[11], contracts[12]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), fbtc_facade, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': owner})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_facade.mintLockedFbtcRequest(amt, {'from': owner})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_facade.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': owner})
    assert 'RedeemFbtcRequest' in tx.events

    # Confirm redeem request
    tx = fbtc_facade.confirmRedeemFbtc(real_amt, {'from': owner})
    assert 'ConfirmRedeemFbtc' in tx.events
    assert locked_fbtc.balanceOf(vault) == 0
    assert fbtc.balanceOf(vault) == real_amt

def test_burn(fn_isolation, contracts, owner, alice):
    uni_btc, vault, fbtc, fbtc_facade, locked_fbtc = contracts[0], contracts[9], contracts[7], contracts[11], contracts[12]

    amt = 1e10
    fee = locked_fbtc.fee()
    real_amt = amt - fee

    # Configuration
    vault.setCap(fbtc, amt*10, {'from': owner})

    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), fbtc_facade, {'from': owner})

    # User mints FBTC
    fbtc.mint(alice, amt, {'from': owner})
    assert fbtc.balanceOf(alice) == amt

    # User deposits FBTC
    fbtc.approve(vault, amt, {'from': alice})
    assert fbtc.allowance(alice, vault) == amt

    vault.mint(fbtc, amt, {'from': alice})
    assert fbtc.balanceOf(vault) == amt
    assert fbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault mints LockedFBTC
    tx = fbtc_facade.mintLockedFbtcRequest(amt, {'from': owner})
    assert 'MintLockedFbtcRequest' in tx.events
    assert locked_fbtc.balanceOf(vault) == real_amt
    assert fbtc.balanceOf(vault) == 0

    # Send redeem request
    fake_tx_id = '0x' + ''.join(random.choices('0123456789abcdef', k=64))
    tx = fbtc_facade.redeemFbtcRequest(real_amt, fake_tx_id, 0, {'from': owner})
    assert 'RedeemFbtcRequest' in tx.events

#     # Confirm redeem request
#     tx = fbtc_facade.confirmRedeemFbtc(real_amt, {'from': owner})
#     assert 'ConfirmRedeemFbtc' in tx.events
#     assert locked_fbtc.balanceOf(vault) == 0
#     assert fbtc.balanceOf(vault) == real_amt

    # Burn request
    tx = fbtc_facade.burn(real_amt, {'from': owner})
    assert locked_fbtc.balanceOf(vault) == 0