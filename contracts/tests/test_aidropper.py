import brownie


def test_airdrop(fn_isolation, contracts, owner, alice, bob):
    uni_btc, air_dropper = contracts[0], contracts[9]

    recipients = [alice, bob]
    amount = 1e18
    total_amout = amount * len(recipients)

    # ---Revert Path Testing---

    # Scenario 1: airdrop reverts if caller allowance is insufficient
    with brownie .reverts("ERC20: insufficient allowance"):
        air_dropper.airdrop(uni_btc, recipients, amount, {'from': owner})

    # Scenario 2: airdrop reverts if caller balance is insufficient
    uni_btc.approve(air_dropper, total_amout, {'from': owner})
    with brownie .reverts("ERC20: transfer amount exceeds balance"):
        air_dropper.airdrop(uni_btc, recipients, amount, {'from': owner})

    # ---Happy Path Testing---

    # Scenario 3: airdrop tokens successfully with sufficient caller allowance and balance
    uni_btc.mint(owner, total_amout, {'from': owner})
    air_dropper.airdrop(uni_btc, recipients, amount, {'from': owner})

    for recipient in recipients:
        assert uni_btc.balanceOf(recipient) == amount
    assert uni_btc.balanceOf(air_dropper) == 0
