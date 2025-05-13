import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/mode-mainnet/deploy_transfer_proxy.py main "rockx-eben" "mode" --network=mainnet-mode`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "mode": {
            "vault": "0x84E5C854A7fF9F49c888d69DECa578D406C26800",
            "to": "0xa9cf74D45896E50F0942DCC346D1382dca48e039",
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
