import brownie


def test_sendToken(fn_isolation, chain_id, contracts, owner, alice, bob, zero_address):
    uni_btc, peer_sender, peer_receiver = contracts[0], contracts[1], contracts[2]

    fee = peer_sender. calcFee()
    min_amt = peer_sender.minTransferAmt()

    # ---Revert Path Testing---

    # Scenario 1: Sending a token is not allowed when the sender peer is paused.
    peer_sender.pause({'from': owner})
    with brownie .reverts("Pausable: paused"):
        peer_sender.sendToken(chain_id + 1, bob, 0, {'from': alice})
    peer_sender.unpause({'from': owner})

    # Scenario 2: Not allowed to send tokens to the same chain as the sender peer.
    with brownie .reverts("USR004"):
        peer_sender.sendToken(chain_id, bob, 0, {'from': alice})

    # Scenario 3: Not allowed to send tokens to the chain where the receiver peer is not registered.
    with brownie .reverts("USR005"):
        peer_sender.sendToken(chain_id + 2, bob, 0, {'from': alice})

    # Scenario 4: Not allowed to send tokens with an insufficient amount.
    with brownie .reverts("USR006"):
        peer_sender.sendToken(chain_id + 1, bob, 0, {'from': alice})
    uni_btc.mint(alice, min_amt, {'from': owner})

    # Scenario 5: Not allowed to send tokens to the zero address.
    with brownie .reverts("USR007"):
        peer_sender.sendToken(chain_id + 1, zero_address, min_amt, {'from': alice})

    # Scenario 6: Not allowed to send tokens with an insufficient fee provided.
    with brownie .reverts("USR008"):
        peer_sender.sendToken(chain_id + 1, bob, min_amt, {'from': alice})

    # Scenario 7: Not allowed to send tokens with an insufficient fee provided.
    with brownie .reverts("USR008"):
        peer_sender.sendToken(chain_id + 1, bob, min_amt, {'from': alice})

    # Scenario 8: Not allowed to send tokens if the allowance is insufficient.
    with brownie .reverts("ERC20: insufficient allowance"):
        peer_sender.sendToken(chain_id + 1, bob, min_amt, {'from': alice, 'value': fee})

    # ---Happy Path Testing---

    # Scenario 9: Burn tokens successfully with valid inputs.
    uni_btc.approve(peer_sender, min_amt, {'from': alice})
    tx = peer_sender.sendToken(chain_id + 1, bob, min_amt, {'from': alice, 'value': fee})
    assert "SourceBurned" in tx.events
    assert uni_btc.balanceOf(alice) == 0
    assert peer_sender.nonce() == 1


def test_executeMessage(fn_isolation, chain_id, contracts, executor, alice, bob, zero_address):
    uni_btc, peer_sender, peer_receiver, message_bus_receiver = contracts[0], contracts[1], contracts[2], contracts[4]

    min_amt = peer_sender.minTransferAmt()

    # ---Revert Path Testing---

    # Scenario 1: Only message bus is permitted to call the executeMessage function
    with brownie .reverts("caller is not message bus"):
        peer_receiver.executeMessage['address,uint64,bytes,address'](peer_sender, chain_id, b'', executor, {'from': executor})

    # Scenario 2: The message won't be executed if the given source chain ID is not registered.
    with brownie .reverts("USR009"):
        message_bus_receiver.executeMessage(0, zero_address, peer_receiver, alice, bob, min_amt, 1, {'from': executor})

    with brownie .reverts("USR009"):
        message_bus_receiver.executeMessage(chain_id+2, peer_sender, peer_receiver, alice, bob, min_amt, 1, {'from': executor})

    with brownie .reverts("USR009"):
        message_bus_receiver.executeMessage(chain_id+2, zero_address, peer_receiver, alice, bob, min_amt, 1, {'from': executor})

    # Scenario 3: The message won't be executed if the given sender peer is incorrect.
    with brownie .reverts("USR009"):
        message_bus_receiver.executeMessage(chain_id, zero_address, peer_receiver, alice, bob, min_amt, 1, {'from': executor})

    with brownie .reverts("USR009"):
        message_bus_receiver.executeMessage(chain_id, peer_receiver, peer_receiver, alice, bob, min_amt, 1, {'from': executor})

    # ---Happy Path Testing---

    # Scenario 4: Mint tokens successfully with valid inputs.
    tx = message_bus_receiver.executeMessage(chain_id, peer_sender, peer_receiver, alice, bob, min_amt, 1, {'from': executor})
    assert "DestinationMinted" in tx.events
    assert uni_btc.balanceOf(bob) == min_amt


def test_configurePeers(fn_isolation, chain_id, contracts, executor, owner, zero_address):
    peer_sender, peer_receiver = contracts[1], contracts[2]

    # ---Revert Path Testing---

    # Scenario 1: Only MANAGER_ROLE is permitted to call the configurePeers function.
    with brownie .reverts():
        peer_sender.configurePeers([], [], {'from': executor})

    # Scenario 2: The lengths of inputs must be equal and greater than zero.
    with brownie .reverts("SYS006"):
        peer_sender.configurePeers([], [], {'from': owner})

    with brownie .reverts("SYS006"):
        peer_sender.configurePeers([chain_id, chain_id+1], [], {'from': owner})

    # Scenario 3: Zero chain ID not accepted
    with brownie .reverts("SYS007"):
        peer_sender.configurePeers([0], [peer_sender], {'from': owner})

    # Scenario 4: Zero Peer address not accepted
    with brownie .reverts("SYS008"):
        peer_sender.configurePeers([chain_id], [zero_address], {'from': owner})

    # ---Happy Path Testing---

    # Scenario 5: Mint tokens successfully with valid inputs.
    tx = peer_sender.configurePeers([chain_id+2, chain_id+3], [peer_sender, peer_receiver], {'from': owner})
    assert "PeersConfigured" in tx.events
    assert peer_sender.peers(chain_id+2) == peer_sender
    assert peer_sender.peers(chain_id+3) == peer_receiver


def test_setMinTransferAmt(fn_isolation, contracts, owner, executor):
    peer_sender = contracts[1]

    min_amt = peer_sender.minTransferAmt() + 100000

    # ---Revert Path Testing---

    # Scenario 1: Only MANAGER_ROLE is permitted to call the setMinTransferAmt function.
    with brownie .reverts():
        peer_sender.setMinTransferAmt(min_amt, {'from': executor})

    # Scenario 2: The minimum amount to set must be a positive multiple of 10000
    for amt in [0, 1000, 10001]:
        with brownie .reverts("SYS005"):
            peer_sender.setMinTransferAmt(amt, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: Mint tokens successfully with valid inputs.
    tx = peer_sender.setMinTransferAmt(min_amt, {'from': owner})
    assert "MinTransferAmtSet" in tx.events


def test_claimTokens(fn_isolation, contracts, owner, executor, bob):
    uni_btc, peer_receiver = contracts[0], contracts[1]

    amt = 1e8
    uni_btc.mint(peer_receiver, amt, {'from': owner})
    owner.transfer(peer_receiver, amt)
    assert uni_btc.balanceOf(peer_receiver) == amt
    assert peer_receiver.balance() == amt

    # ---Revert Path Testing---

    # Scenario 1: Only DEFAULT_ADMIN_ROLE is permitted to call the claimTokens function.
    with brownie .reverts():
        peer_receiver.claimTokens(bob, 0, {'from': executor})

    with brownie .reverts():
        peer_receiver.claimTokens(uni_btc, bob, 0, {'from': executor})

    # ---Happy Path Testing---

    # Scenario 2: Mint tokens successfully with valid inputs.
    bob_balance = bob.balance()
    tx = peer_receiver.claimTokens(bob, amt, {'from': owner})
    assert "NativeTokensClaimed" in tx.events
    assert peer_receiver.balance() == 0
    assert bob.balance() == bob_balance + amt

    tx = peer_receiver.claimTokens(bob, uni_btc, amt, {'from': owner})
    assert "ERC20TokensClaimed" in tx.events
    assert uni_btc.balanceOf(peer_receiver) == 0
    assert uni_btc.balanceOf(bob) == amt
