from brownie import Peer, accounts, Contract, project, config

from scripts.testnet.configs import contracts

# Execution Command Format:
# `brownie run scripts/testnet/configure_peers.py main "manager" "avax-test" --network=avax-test`


def main(manager="manager", network="avax-test"):
    manager = accounts.load(manager)

    chain_ids = [contracts["avax-test"]["chain_id"],
                 contracts["bsc-test"]["chain_id"],
                 contracts["ftm-test"]["chain_id"]]

    peers = [contracts["avax-test"]["peer"],
             contracts["bsc-test"]["peer"],
             contracts["ftm-test"]["peer"]]

    peer = contracts[network]["peer"]

    peer = Contract.from_abi("Peer", peer, Peer.abi)

    tx = peer.configurePeers(chain_ids, peers, {'from': manager})
    assert "PeersConfigured" in tx.events
    assert peer.peers(contracts["avax-test"]["chain_id"]) == contracts["avax-test"]["peer"]
    assert peer.peers(contracts["bsc-test"]["chain_id"]) == contracts["bsc-test"]["peer"]
    assert peer.peers(contracts["ftm-test"]["chain_id"]) == contracts["ftm-test"]["peer"]
