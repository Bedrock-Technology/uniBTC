import brownie


def test_mint(fn_isolation, contracts, owner, alice, bob, zero_address):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Only a minter can call the mint function.
    with brownie.reverts():
        uni_btc.mint(alice, amount, {'from': bob})

    # Scenario 2: Can't mint to the zero address.
    with brownie.reverts("ERC20: mint to the zero address"):
        uni_btc.mint(zero_address, amount, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: Minting was successful, and the balance has been updated.
    tx = uni_btc.mint(alice, amount, {'from': owner})
    assert "Transfer" in tx.events
    assert uni_btc.balanceOf(alice) == amount
    assert uni_btc.totalSupply() == amount
    assert uni_btc.name() == "uniBTC"
    assert uni_btc.symbol() == "uniBTC"
    assert uni_btc.decimals() == 8


def test_approve(fn_isolation, contracts, alice, bob, zero_address):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Can't approve from the zero address.
    with brownie.reverts("ERC20: approve from the zero address"):
        uni_btc.approve(bob, amount, {'from': zero_address})

    # Scenario 2: Can't approve to the zero address.
    with brownie.reverts("ERC20: approve to the zero address"):
        uni_btc.approve(zero_address, amount, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 3: The approval was successful, and the allowance has been updated.
    tx = uni_btc.approve(bob, amount, {'from': alice})
    assert "Approval" in tx.events
    assert uni_btc.allowance(alice, bob) == amount


def test_increaseAllowance(fn_isolation, contracts, alice, bob, zero_address):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Can't approve from the zero address.
    with brownie.reverts("ERC20: approve from the zero address"):
        uni_btc.increaseAllowance(bob, amount, {'from': zero_address})

    # Scenario 2: Can't approve to the zero address.
    with brownie.reverts("ERC20: approve to the zero address"):
        uni_btc.increaseAllowance(zero_address, amount, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 3: The approval was successful, and the allowance has been updated.
    tx = uni_btc.increaseAllowance(bob, amount, {'from': alice})
    assert "Approval" in tx.events
    assert uni_btc.allowance(alice, bob) == amount


def test_decreaseAllowance(fn_isolation, contracts, alice, bob):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Can't decrease allowance below zero.
    with brownie.reverts("ERC20: decreased allowance below zero"):
        uni_btc.decreaseAllowance(bob, amount, {'from': alice})

    # ---Happy Path Testing---

    # Scenario 2: The approval was successful, and the allowance has been updated.
    tx = uni_btc.increaseAllowance(bob, amount, {'from': alice})
    assert "Approval" in tx.events
    assert uni_btc.allowance(alice, bob) == amount

    tx = uni_btc.decreaseAllowance(bob, amount, {'from': alice})
    assert "Approval" in tx.events
    assert uni_btc.allowance(alice, bob) == 0


def test_transfer(fn_isolation, contracts, owner, alice, zero_address):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Can't approve from the zero address.
    with brownie.reverts("ERC20: transfer from the zero address"):
        uni_btc.transfer(alice, amount, {'from': zero_address})

    # Scenario 2: Can't approve to the zero address.
    with brownie.reverts("ERC20: transfer to the zero address"):
        uni_btc.transfer(zero_address, amount, {'from': owner})

    # Scenario 3: Can't transfer an amount exceeding the balance.
    with brownie.reverts("ERC20: transfer amount exceeds balance"):
        uni_btc.transfer(alice, amount, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 4: The transfer was successful, and the allowance has been updated.
    uni_btc.mint(owner, amount, {'from': owner})
    tx = uni_btc.transfer(alice, amount, {'from': owner})
    assert "Transfer" in tx.events
    assert uni_btc.balanceOf(owner) == 0
    assert uni_btc.balanceOf(alice) == amount


def test_batchTransfer(fn_isolation, contracts, owner, alice, bob):
    uni_btc = contracts[0]

    amt = 200

    # ---Revert Path Testing---

    # Scenario 1: At least one recipient is provided.
    with brownie .reverts("USR001"):
        uni_btc.batchTransfer([], [], {'from': owner})

    # Scenario 2: The number of recipients must equal the number of tokens
    with brownie .reverts("USR002"):
        uni_btc.batchTransfer([alice, bob], [amt / 2], {'from': owner})
    with brownie .reverts("USR002"):
        uni_btc.batchTransfer([alice], [amt / 2, amt / 2], {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: Transfer successful and balances update accordingly
    uni_btc.mint(owner, amt, {'from': owner})
    tx = uni_btc.batchTransfer([alice, bob], [amt / 2, amt / 2], {'from': owner})
    assert 'Transfer' in tx.events
    assert uni_btc.totalSupply() == amt
    assert uni_btc.balanceOf(owner) == 0
    assert uni_btc.balanceOf(alice) == amt / 2
    assert uni_btc.balanceOf(bob) == amt / 2


def test_transferFrom(fn_isolation, contracts, owner, alice, bob):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 0: Can't transfer for insufficient allowance.
    with brownie.reverts("ERC20: insufficient allowance"):
        uni_btc.transferFrom(alice, owner, amount, {'from': bob})

    # Scenario 3: Can't transfer an amount exceeding the balance.
    uni_btc.approve(bob, amount, {'from': alice})

    with brownie.reverts("ERC20: transfer amount exceeds balance"):
        uni_btc.transferFrom(alice, owner, amount, {'from': bob})

    # ---Happy Path Testing---

    # Scenario 4: The transfer was successful, and the allowance has been updated.
    uni_btc.mint(alice, amount, {'from': owner})

    tx = uni_btc.transferFrom(alice, owner, amount, {'from': bob})
    assert "Transfer" in tx.events
    assert uni_btc.balanceOf(alice) == 0
    assert uni_btc.balanceOf(owner) == amount


def test_burn(fn_isolation, contracts, owner, alice, zero_address):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Only MINTER_ROLE can call burn function
    with brownie.reverts():
        uni_btc.burn(amount, {'from': alice})

    # Scenario 2: Can't burn an amount exceeding the balance.
    with brownie.reverts("ERC20: burn amount exceeds balance"):
        uni_btc.burn(amount, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: The burn was successful, and the allowance has been updated.
    uni_btc.mint(owner, amount, {'from': owner})
    assert uni_btc.balanceOf(owner) == amount

    tx = uni_btc.burn(amount, {'from': owner})
    assert "Transfer" in tx.events
    assert uni_btc.totalSupply() == 0


def test_burnFrom(fn_isolation, contracts, owner, alice):
    uni_btc = contracts[0]

    amount = 1e8

    # ---Revert Path Testing---

    # Scenario 1: Only MINTER_ROLE can call burnFrom function
    with brownie.reverts():
        uni_btc.burnFrom(alice, amount, {'from': alice})

    # Scenario 2: Can't burn for insufficient allowance.
    with brownie.reverts("ERC20: insufficient allowance"):
        uni_btc.burnFrom(alice, amount, {'from': owner})

    # Scenario 3: Can't burn an amount exceeding the balance.
    uni_btc.approve(owner, amount, {'from': alice})
    with brownie.reverts("ERC20: burn amount exceeds balance"):
        uni_btc.burnFrom(alice, amount, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 4: The burn was successful, and the allowance has been updated.
    uni_btc.mint(alice, amount, {'from': owner})

    tx = uni_btc.burnFrom(alice, amount, {'from': owner})
    assert "Transfer" in tx.events
    assert uni_btc.totalSupply() == 0
