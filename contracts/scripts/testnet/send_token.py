from brownie import WBTC, uniBTC, Vault, Peer, accounts, Contract, project, config

from scripts.testnet.configs import contracts, amount

# Execution Command Format:
# `brownie run scripts/testnet/send_token.py main "owner" "minter" "user" "avax-test" "bsc-test" --network=avax-test`


def main(owner="owner", minter="minter", user="user", from_network="avax-test", to_network="bsc-test"):
    owner = accounts.load(owner)
    minter = accounts.load(minter)
    user = accounts.load(user)

    from_wbtc_addr = contracts[from_network]["wbtc"]
    from_uni_btc_addr = contracts[from_network]["uni_btc"]
    from_vault_addr = contracts[from_network]["vault"]
    from_peer_addr = contracts[from_network]["peer"]

    to_chain_id = contracts[to_network]["chain_id"]

    wbtc = Contract.from_abi("WBTC", from_wbtc_addr, WBTC.abi)
    uni_btc = Contract.from_abi("uniBTC", from_uni_btc_addr, uniBTC.abi)
    vault = Contract.from_abi("Vault", from_vault_addr, Vault.abi)
    peer = Contract.from_abi("Peer", from_peer_addr, Peer.abi)

    user_wbtc_balance_before = wbtc.balanceOf(user)
    user_uni_btc_balance_before = uni_btc.balanceOf(user)

    vault_wbtc_balance_before = wbtc.balanceOf(vault)

    peer_uni_btc_balance_before = uni_btc.balanceOf(peer)

    # Mint local WBTC
    wbtc.mint(user, amount, {'from': minter})
    assert wbtc.balanceOf(user) == user_wbtc_balance_before + amount

    # Mint local uniBTC
    vault.setCap(wbtc, amount, {'from': owner})
    wbtc.approve(vault, amount, {'from': user})
    vault.mint(amount/2, {'from': minter})
    vault.mint(wbtc, amount/2, {'from': minter})
    assert wbtc.balanceOf(user) == user_wbtc_balance_before
    assert wbtc.balanceOf(vault) == vault_wbtc_balance_before + amount
    assert uni_btc.balanceOf(user) == user_uni_btc_balance_before + amount

    # Send local uniBTC
    uni_btc.approve(peer, amount, {'from': user})
    fee = peer.calcFee()
    tx = peer.sendToken(to_chain_id, user, amount, {'from': user, 'value': fee})
    assert "Message" in tx.events
    assert "SourceBurned" in tx.events
    assert uni_btc.balanceOf(peer) == peer_uni_btc_balance_before
    assert uni_btc.balanceOf(user) == user_uni_btc_balance_before

    # SendToken tx from avax-test to bsc-test:
    # https://testnet.snowtrace.io/tx/0x1d4f5ef714d67bdf7840df3f0c0dcdc0052e04baad6452f06cff79e903086ec5

    # SendToken tx from bsc-test to ftm-test:
    # https://testnet.bscscan.com/tx/0x888943972d446b5fdbc2ad424eaf009d1fb258f0575a22753d4b599cf5be4d7e

    # SendToken tx from ftm-test to avax-test:
    # https://testnet.ftmscan.com/tx/0x78bfda70b70734b49784699dd6d28ed04bdf5455052e8118a4e366fbc93333ea