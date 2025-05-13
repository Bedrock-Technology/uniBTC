import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/bsc-mainnet/deploy_transfer_proxy.py main "rockx-eben" "bsc" --network=bsc-main`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "bsc": {
            "vault": "0x1dF46ec5e86FeC4589b3fA7D60B6Dc7Ef890AD93",
            "to": "0x1Ae02CD8a4566A4f2432857D7A943765D1e3E757",
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
