import brownie
from brownie import accounts


def test_mint_native(fn_isolation, contracts, owner, alice):
    uni_btc, vault = contracts[0], contracts[9]

    assert vault.isNativeBTC()

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
    wbtc, vault = contracts[5], contracts[9]

    assert vault.isNativeBTC()

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


def test_redeem_native(fn_isolation, contracts, owner, alice):
    uni_btc, vault = contracts[0], contracts[9]

    assert vault.isNativeBTC()

    rate_base = vault.EXCHANGE_RATE_BASE()
    native_btc = vault.NATIVE_BTC()

    insufficient_amt = 1e8
    cap = 10e18

    # ---Revert Path Testing---
    # Scenario 1: Redeem reverts if the given token is irredeemable.
    with brownie .reverts("SYS009"):
        vault.redeem(0, {'from': alice})

    tx = vault.toggleRedemption({'from': owner})
    assert "RedemptionOn" in tx.events
    assert vault.redeemable()

    # Scenario 2: Redeem reverts if the amount is insufficient
    with brownie .reverts("USR010"):
        vault.redeem(insufficient_amt, {'from': alice})

    # Scenario 3: Redeem reverts if the uniBTC allowance is insufficient.
    with brownie .reverts("ERC20: insufficient allowance"):
        vault.redeem(cap, {'from': alice})

    uni_btc.approve(vault, cap, {'from': alice})

    # Scenario 4: Redeem reverts if the user's uniBTC balance is insufficient.
    uni_btc.approve(owner, cap/rate_base, {'from': alice})
    with brownie .reverts("ERC20: burn amount exceeds balance"):
        vault.redeem(cap, {'from': alice})

    # Scenario 5: Redeem reverts if the Vault balance is insufficient.
    uni_btc.mint(alice, cap/rate_base, {'from': owner})
    assert vault.balance() == 0
    with brownie .reverts("Address: insufficient balance"):
        vault.redeem(cap, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 6: Redeem tokens successfully with valid inputs.
    vault.setCap(native_btc, cap, {'from': owner})
    assert vault.caps(native_btc) == cap

    uni_btc.approve(owner, cap, {'from': alice})
    uni_btc.burnFrom(alice, cap/rate_base, {'from': owner})
    assert uni_btc.balanceOf(alice) == 0

    alice_balance_before = alice.balance()
    vault_balance_before = vault.balance()
    tx = vault.mint({'from': alice, 'value': cap})
    assert "Minted" in tx.events
    assert vault.balance() == vault_balance_before + cap
    assert uni_btc.balanceOf(alice) == cap/rate_base
    assert alice_balance_before >= alice.balance() + cap

    vault_balance_before = vault.balance()
    tx = vault.redeem(cap, {'from': alice})
    assert "Redeemed" in tx.events
    assert uni_btc.balanceOf(alice) == 0
    assert vault.balance() == vault_balance_before - cap

    tx = vault.toggleRedemption({'from': owner})
    assert "RedemptionOff" in tx.events
    assert not vault.redeemable()


def test_redeem(fn_isolation, contracts, owner, alice):
    uni_btc, wbtc, vault = contracts[0], contracts[5], contracts[9]

    assert vault.isNativeBTC()

    cap = 10e8

    # ---Revert Path Testing---
    # Scenario 1: Redeem reverts if the given token is irredeemable.
    with brownie .reverts("SYS009"):
        vault.redeem(wbtc, 0, {'from': alice})

    tx = vault.toggleRedemption({'from': owner})
    assert "RedemptionOn" in tx.events
    assert vault.redeemable()

    # Scenario 2: Redeem reverts if the Vault's balance is insufficient.
    with brownie .reverts("ERC20: insufficient allowance"):
        vault.redeem(wbtc, cap, {'from': alice})

    uni_btc.mint(alice, cap, {'from': owner})
    uni_btc.approve(vault, cap, {'from': alice})

    # Scenario 3: Redeem reverts if the uniBTC allowance is insufficient.
    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.redeem(wbtc, cap, {'from': alice})

    uni_btc.approve(vault, cap, {'from': alice})

    # Scenario 4: Redeem reverts if the user's uniBTC balance is insufficient.
    uni_btc.approve(owner, cap, {'from': alice})
    uni_btc.burnFrom(alice, cap, {'from': owner})

    with brownie .reverts("ERC20: burn amount exceeds balance"):
        vault.redeem(wbtc, cap, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 5: Redeem tokens successfully with valid inputs.
    wbtc.mint(alice, cap, {'from': owner})
    wbtc.approve(vault, cap, {'from': alice})
    assert wbtc.balanceOf(alice) == cap

    vault.setCap(wbtc, cap, {'from': owner})
    vault.mint(wbtc, cap, {'from': alice})

    tx = vault.redeem(wbtc, cap, {'from': alice})
    assert "Redeemed" in tx.events
    assert uni_btc.balanceOf(alice) == 0
    assert wbtc.balanceOf(alice) == cap
    assert wbtc.balanceOf(vault) == 0

    tx = vault.toggleRedemption({'from': owner})
    assert "RedemptionOff" in tx.events
    assert not vault.redeemable()


def test_setCap(fn_isolation, contracts, owner, alice, zero_address):
    wbtc18, wbtc, xbtc, vault = contracts[10], contracts[5], contracts[8], contracts[9]

    assert vault.isNativeBTC()

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


def test_adminWithdraw_native(fn_isolation, contracts, owner, alice, bob, zero_address):
    wbtc, vault = contracts[5], contracts[9]

    assert vault.isNativeBTC()

    bob = accounts.at("0xbFdDf5e269C74157b157c7DaC5E416d44afB790d", True)

    rate_base = vault.EXCHANGE_RATE_BASE()
    native_btc = vault.NATIVE_BTC()
    cap = 10e18

    # ---Revert Path Testing---

    # Scenario 1: Only DEFAULT_ADMIN_ROLE is permitted to call adminWithdraw function
    with brownie.reverts():
        vault.adminWithdraw(0, alice, {'from': alice})

    # Scenario 2: Withdrawal fails if insufficient balance.
    with brownie.reverts("Address: insufficient balance"):
        vault.adminWithdraw(cap, alice, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: Withdraw tokens successfully with valid inputs.
    vault.setCap(native_btc, cap, {'from': owner})
    vault.mint({'from': alice, 'value': cap})
    tx = vault.adminWithdraw(cap, bob, {'from': owner})
    assert "Withdrawed" in tx.events
    assert bob.balance() == cap
    assert vault.balance() == 0


def test_adminWithdraw(fn_isolation, contracts, owner, alice, bob, zero_address):
    wbtc, vault = contracts[5], contracts[9]

    assert vault.isNativeBTC()

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Only DEFAULT_ADMIN_ROLE is permitted to call adminWithdraw function
    with brownie .reverts():
        vault.adminWithdraw(wbtc, 0, alice, {'from': alice})

    # Scenario 2: Withdrawal to the zero address is not permitted.
    with brownie .reverts("ERC20: transfer to the zero address"):
        vault.adminWithdraw(wbtc, 0, zero_address, {'from': owner})

    # Scenario 3: Withdrawal fails if insufficient balance.
    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.adminWithdraw(wbtc, cap, alice, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 4: Withdraw tokens successfully with valid inputs.
    vault.setCap(wbtc, cap, {'from': owner})
    wbtc.mint(alice, cap, {'from': owner})
    wbtc.approve(vault, cap, {'from': alice})
    vault.mint(wbtc, cap, {'from': alice})
    tx = vault.adminWithdraw(wbtc, cap, bob, {'from': owner})
    assert "Withdrawed" in tx.events
    assert wbtc.balanceOf(vault) == 0
    assert wbtc.balanceOf(bob) == cap
