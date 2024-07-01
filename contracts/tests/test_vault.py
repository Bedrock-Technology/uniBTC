import brownie


def test_mint(fn_isolation, contracts, owner, alice):
    wbtc, vault = contracts[5], contracts[6]

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Mint reverts if the token is paused.
    vault.pauseToken(wbtc, {'from': owner})
    with brownie .reverts("SYS003"):
        vault.mint(0, {'from': alice})

    with brownie .reverts("SYS004"):
        vault.mint(wbtc, 0, {'from': alice})
    vault.unpauseToken(wbtc, {'from': owner})

    # Scenario 2: Mint reverts if the quota is insufficient.
    with brownie .reverts("USR003"):
        vault.mint(1, {'from': alice})

    with brownie .reverts("USR003"):
        vault.mint(wbtc, 1, {'from': alice})

    # Scenario 3: Mint reverts if the allowance is insufficient.
    vault.setCap(wbtc, cap, {'from': owner})

    with brownie .reverts("ERC20: insufficient allowance"):
        vault.mint(1, {'from': alice})

    with brownie .reverts("ERC20: insufficient allowance"):
        vault.mint(wbtc, 1, {'from': alice})

    # Scenario 4: Mint reverts if the balance is insufficient.
    wbtc.approve(vault, cap * 2, {'from': alice})

    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.mint(1, {'from': alice})

    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.mint(wbtc, 1, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 5: Mint tokens successfully with valid inputs.
    wbtc.mint(alice, cap, {'from': owner})
    assert wbtc.balanceOf(alice) == cap

    tx = vault.mint(cap/2, {'from': alice})
    assert "Minted" in tx.events
    assert wbtc.balanceOf(alice) == cap/2
    assert wbtc.balanceOf(vault) == cap/2

    tx = vault.mint(wbtc, cap/2, {'from': alice})
    assert "Minted" in tx.events
    assert wbtc.balanceOf(alice) == 0
    assert wbtc.balanceOf(vault) == cap


def test_redeem(fn_isolation, contracts, owner, alice):
    uni_btc, wbtc, vault = contracts[0], contracts[5], contracts[6]

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Redeem reverts if the token is paused.
    vault.pauseToken(wbtc, {'from': owner})
    with brownie .reverts("SYS003"):
        vault.redeem(0, {'from': alice})

    with brownie .reverts("SYS004"):
        vault.redeem(wbtc, 0, {'from': alice})

    vault.unpauseToken(wbtc, {'from': owner})

    # Scenario 2: Redeem reverts if the given token is irredeemable.
    with brownie .reverts("SYS011"):
        vault.redeem(0, {'from': alice})

    with brownie .reverts("SYS012"):
        vault.redeem(wbtc, 0, {'from': alice})

    for _ in range(2):
        tx = vault.enableRedemption({'from': owner})
        assert "RedemptionEnabled" in tx.events
        assert vault.redeemable()

    # Scenario 3: Redeem reverts if the Vault's balance is insufficient.
    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.redeem(cap, {'from': alice})

    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        vault.redeem(wbtc, cap, {'from': alice})

    vault.setCap(wbtc, cap, {'from': owner})
    wbtc.mint(alice, cap, {'from': owner})
    wbtc.approve(vault, cap, {'from': alice})
    vault.mint(cap, {'from': alice})

    # Scenario 4: Redeem reverts if the uniBTC allowance is insufficient.
    with brownie .reverts("ERC20: insufficient allowance"):
        vault.redeem(cap, {'from': alice})

    with brownie .reverts("ERC20: insufficient allowance"):
        vault.redeem(wbtc, cap, {'from': alice})

    uni_btc.approve(vault, cap, {'from': alice})

    # Scenario 5: Redeem reverts if the user's uniBTC balance is insufficient.
    uni_btc.approve(owner, cap, {'from': alice})
    uni_btc.burnFrom(alice, cap, {'from': owner})

    with brownie .reverts("ERC20: burn amount exceeds balance"):
        vault.redeem(cap, {'from': alice})

    with brownie .reverts("ERC20: burn amount exceeds balance"):
        vault.redeem(wbtc, cap, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 5: Redeem tokens successfully with valid inputs.
    uni_btc.mint(alice, cap, {'from': owner})
    assert uni_btc.balanceOf(alice) == cap

    tx = vault.redeem(cap/2, {'from': alice})
    assert "Redeemed" in tx.events
    assert uni_btc.balanceOf(alice) == cap/2
    assert wbtc.balanceOf(alice) == cap/2
    assert wbtc.balanceOf(vault) == cap/2

    tx = vault.redeem(wbtc, cap/2, {'from': alice})
    assert "Redeemed" in tx.events
    assert uni_btc.balanceOf(alice) == 0
    assert wbtc.balanceOf(alice) == cap
    assert wbtc.balanceOf(vault) == 0

    for _ in range(2):
        tx = vault.disableRedemption({'from': owner})
        assert "RedemptionDisabled" in tx.events
        assert not vault.redeemable()


def test_setCap(fn_isolation, contracts, owner, alice, zero_address):
    wbtc, vault = contracts[5], contracts[6]

    cap = 10e8

    # ---Revert Path Testing---

    # Scenario 1: Only DEFAULT_ADMIN_ROLE is permitted to call setCap function
    with brownie .reverts():
        vault.setCap(wbtc, 0, {'from': alice})

    # Scenario 2: Setting a cap for the zero address is not permitted
    with brownie .reverts("SYS005"):
        vault.setCap(zero_address, 0, {'from': owner})

    # Scenario 3: The decimals of the given token must be equal to 8
    # Note: Skip codes here for conciseness.

    # ---Happy Path Testing---

    # Scenario 4: Set cap successfully with valid inputs.
    vault.setCap(wbtc, cap, {'from': owner})
    assert vault.caps(wbtc) == cap


def test_adminWithdraw(fn_isolation, contracts, owner, alice, bob, zero_address):
    wbtc, vault = contracts[5], contracts[6]

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
    vault.mint(cap, {'from': alice})
    tx = vault.adminWithdraw(wbtc, cap, bob, {'from': owner})
    assert "Withdrawed" in tx.events
    assert wbtc.balanceOf(vault) == 0
    assert wbtc.balanceOf(bob) == cap
