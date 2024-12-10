import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/swap_proxy_deploy.py main "deployer" "ethereum" --network=eth-mainnet`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "ethereum": {
            "vault_proxy": "0x047D41F2544B7F63A8e991aF2068a363d210d6Da",  # https://etherscan.io/address/0x047D41F2544B7F63A8e991aF2068a363d210d6Da
            "swap_from_token": "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",  # [wbtc] https://etherscan.io/token/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
            "swap_to_token": "0xC96dE26018A54D51c097160568752c4E3BD6C364",  # [fbtc] https://etherscan.io/token/0xC96dE26018A54D51c097160568752c4E3BD6C364
        },
        "holesky": {
            "vault_proxy": "0x6924818BD9d4Fd543a81F0c2D816E326c3c5b355",
            "swap_from_token": "0x2ECFd64cF6e976928E3c9Fa87fDce407b89afbFa",
            "swap_to_token": "0x707e48586780D5948e2b892B5FD30a32e55098E0",
        },
    }

    assert config_contact[network_cfg]["vault_proxy"] != ""
    assert config_contact[network_cfg]["swap_from_token"] != ""
    assert config_contact[network_cfg]["swap_to_token"] != ""

    deployer = accounts.load(deployer_account)
    # deploy SwapProxy contract
    swapProxy_contract = SwapProxy.deploy(
        config_contact[network_cfg]["vault_proxy"],
        config_contact[network_cfg]["swap_from_token"],
        config_contact[network_cfg]["swap_to_token"],
        {"from": deployer},
    )
    print("SwapProxy contract address", swapProxy_contract)

    assert swapProxy_contract.owner() == deployer
    print("SwapProxy contract swap type", swapProxy_contract.getSwapType())
