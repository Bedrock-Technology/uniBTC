import brownie
from brownie import accounts


def test_mint_native(fn_isolation, contracts, owner, alice):
    uni_btc, vault = contracts[0], contracts[6]

    bob = accounts.at("0xbFdDf5e269C74157b157c7DaC5E416d44afB790d", True)

    rate_base = vault.EXCHANGE_RATE_BASE()
    native_btc = vault.NATIVE_BTC()
    assert native_btc == "0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF"

    insufficient_amt = 1e8
    cap = 10e18

    alice.transfer(bob, cap/2)

    # ---Revert Path Testing---

    # Scenario 1: Mint reverts if the token is paused.
    vault.pauseToken(native_btc, {'from': owner})
    with brownie .reverts("SYS002"):
        vault.mint({'from': alice, 'value': cap})
    vault.unpauseToken(native_btc, {'from': owner})

    # Scenario 2: Mint reverts if the amount is insufficient.
    with brownie .reverts("USR010"):
        vault.mint({'from': alice, 'value': insufficient_amt})

    # Scenario 3: Mint reverts if the quota is insufficient.
    assert vault.caps(native_btc) < cap
    with brownie .reverts("USR003"):
        vault.mint({'from': alice, 'value': cap})

    # Scenario 4: Mint reverts if the balance is insufficient.
    vault.setCap(native_btc, cap, {'from': owner})
    assert vault.caps(native_btc) == cap
    vault_balance_before = vault.balance()
    assert vault_balance_before == 0
    # "ValueError: insufficient funds for gas * price + value"
    # vault.mint({'from': bob, 'value': cap})

    # ---Happy Path Testing---

    # Scenario 5: Mint tokens successfully with valid inputs.
    alice_balance_before = alice.balance()
    assert uni_btc.balanceOf(alice) == 0
    tx = vault.mint({'from': alice, 'value': cap})
    assert "Minted" in tx.events
    assert vault.balance() == vault_balance_before + cap
    assert uni_btc.balanceOf(alice) == cap/rate_base
    assert alice_balance_before >= alice.balance() + cap


def test_mint(fn_isolation, contracts, owner, alice):
    wbtc, vault = contracts[5], contracts[6]

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Mint reverts if the token is paused.
    vault.pauseToken(wbtc, {'from': owner})
    with brownie .reverts("SYS002"):
        vault.mint(wbtc, 0, {'from': alice})
    vault.unpauseToken(wbtc, {'from': owner})

    # Scenario 2: Mint reverts if the quota is insufficient.
    with brownie .reverts("USR003"):
        vault.mint(wbtc, 1, {'from': alice})

    # Scenario 3: Mint reverts if the allowance is insufficient.
    vault.setCap(wbtc, cap, {'from': owner})

    with brownie .reverts("ERC20: insufficient allowance"):
        vault.mint(wbtc, 1, {'from': alice})

    # Scenario 4: Mint reverts if the balance is insufficient.
    wbtc.approve(vault, cap * 2, {'from': alice})

    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.mint(wbtc, 1, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 5: Mint tokens successfully with valid inputs.
    wbtc.mint(alice, cap, {'from': owner})
    assert wbtc.balanceOf(alice) == cap

    tx = vault.mint(wbtc, cap, {'from': alice})
    assert "Minted" in tx.events
    assert wbtc.balanceOf(alice) == 0
    assert wbtc.balanceOf(vault) == cap


def test_setCap(fn_isolation, contracts, owner, alice, zero_address):
    fbtc, wbtc, wbtc18, xbtc, vault = contracts[7], contracts[5], contracts[11], contracts[8], contracts[6]

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Only DEFAULT_ADMIN_ROLE is permitted to call setCap function
    with brownie .reverts():
        vault.setCap(wbtc, 0, {'from': alice})

    # Scenario 2: Setting a cap for the zero address is not permitted
    with brownie .reverts("SYS003"):
        vault.setCap(zero_address, 0, {'from': owner})

    # Scenario 3: The decimals of the given token must be equal to 8 or 18
    assert xbtc.decimals() == 12
    with brownie .reverts("SYS004"):
        vault.setCap(xbtc, 0, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 4: Successfully set cap for native BTC with 18 decimals
    native_btc = vault.NATIVE_BTC()
    vault.setCap(native_btc, cap, {'from': owner})
    assert vault.NATIVE_BTC_DECIMALS() == 18
    assert vault.caps(native_btc) == cap

    # Scenario 5: Successfully set cap for wrapped BTC with 8 decimals
    assert wbtc.decimals() == 8
    vault.setCap(wbtc, cap, {'from': owner})
    assert vault.caps(wbtc) == cap

    # Scenario 6: Successfully set cap for wrapped BTC with 18 decimals
    assert wbtc18.decimals() == 18
    vault.setCap(wbtc18, cap, {'from': owner})
    assert vault.caps(wbtc18) == cap