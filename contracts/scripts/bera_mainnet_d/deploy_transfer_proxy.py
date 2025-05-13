import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/bera_mainnet_d/deploy_transfer_proxy.py main "rockx-eben" "bera" --network=bera-mainnet`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "bera": {
            "vault": "0xE0240d05Ae9eF703E2b71F3f4Eb326ea1888DEa3",
            "to": "0x77386EAaA8F969D0bBCEc97230A536bDC4Fc7AAE",
        },
    }

    deps = project.load(
        Path.home() / ".brownie" / "packages" / config["dependencies"][0]
    )

    assert config_contact[network_cfg]["vault"] != ""
    assert config_contact[network_cfg]["to"] != ""

    deployer = accounts.load(deployer_account)
    # deploy TransferProxy contract
    transfer_proxy_contract = TransferProxy.deploy(
        config_contact[network_cfg]["vault"],
        config_contact[network_cfg]["to"],
        {"from": deployer},
    )
    print("transfer_proxy contract", transfer_proxy_contract)

    transparent_transfer_proxy = Contract.from_abi(
        "TransferProxy", transfer_proxy_contract, TransferProxy.abi
    )
    default_owner_role = transparent_transfer_proxy.owner()
    assert deployer == default_owner_role
