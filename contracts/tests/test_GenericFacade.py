import brownie
from brownie import accounts


def test_adminWithdraw(fn_isolation, contracts, owner, alice, bob):
    uni_btc, vault, wbtc, generic_facade = contracts[0], contracts[9], contracts[5], contracts[13]

    amt =  1e10

    # Configuration
    vault.setCap(wbtc, amt*10, {'from': owner})
    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), generic_facade, {'from': owner})

    # User mints WBTC
    wbtc.mint(alice, amt, {'from': owner})
    assert wbtc.balanceOf(alice) == amt

    # User deposits WBTC
    wbtc.approve(vault, amt, {'from': alice})
    assert wbtc.allowance(alice, vault) == amt

    vault.mint(wbtc, amt, {'from': alice})
    assert wbtc.balanceOf(vault) == amt
    assert wbtc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(alice) == amt

    # Vault withdrawn WBTC
    tx = generic_facade.adminWithdraw(wbtc, amt, bob, {'from': owner})
    assert 'Withdrawed' in tx.events
    assert wbtc.balanceOf(vault) == 0
    assert wbtc.balanceOf(alice) == 0
    assert wbtc.balanceOf(bob) == amt
    assert uni_btc.balanceOf(alice) == amt

def test_adminWithdraw_native_btc(fn_isolation, contracts, owner, alice, bob):
    uni_btc, vault, generic_facade = contracts[0], contracts[9], contracts[13]

    native_btc = vault.NATIVE_BTC()
    exchange_base = vault.EXCHANGE_RATE_BASE()
    amt =  2*1e18

    # Configuration
    vault.setCap(native_btc, amt*10, {'from': owner})
    vault.grantRole(vault.DEFAULT_ADMIN_ROLE(), generic_facade, {'from': owner})

    # User deposits native BTC
    balance_before = alice.balance()
    vault.mint({'from': alice, 'value': amt})
    assert alice.balance() == balance_before - amt
    assert uni_btc.balanceOf(alice) == amt / exchange_base
    assert vault.balance() == amt

    # Vault withdrawn native BTC
    balance_before = bob.balance()
    tx = generic_facade.adminWithdraw(amt, bob, {'from': owner})
    assert 'Withdrawed' in tx.events
    assert bob.balance() == balance_before + amt
    assert uni_btc.balanceOf(alice) == amt / exchange_base
    assert vault.balance() == 0
