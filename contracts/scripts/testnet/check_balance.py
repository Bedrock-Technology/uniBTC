from brownie import WBTC, uniBTC, Vault, Peer, accounts, Contract, project, config

from scripts.testnet.configs import contracts, amount

# Execution Command Format:
# `brownie run scripts/testnet/check_balance.py main "0xbFdDf5e269C74157b157c7DaC5E416d44afB790d" "avax-test" --network=avax-test`
#
# NOTE: Run this script after send_token.py for all testnet.


def main(user_addr="0xbFdDf5e269C74157b157c7DaC5E416d44afB790d", network="avax-test"):
    wbtc_addr = contracts[network]["wbtc"]
    uni_btc_addr = contracts[network]["uni_btc"]
    vault_addr = contracts[network]["vault"]
    peer_addr = contracts[network]["peer"]

    wbtc = Contract.from_abi("WBTC", wbtc_addr, WBTC.abi)
    uni_btc = Contract.from_abi("uniBTC", uni_btc_addr, uniBTC.abi)

    # Check user balance
    assert wbtc.balanceOf(user_addr) == 0
    assert uni_btc.balanceOf(user_addr) == amount

    # Check Vault balance
    assert wbtc.balanceOf(vault_addr) == amount
    assert uni_btc.balanceOf(vault_addr) == 0

    # Check Peer balance
    assert wbtc.balanceOf(peer_addr) == 0
    assert uni_btc.balanceOf(peer_addr) == 0
