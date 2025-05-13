import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/bob-mainnet/deploy_transfer_proxy.py main "rockx-eben" "bob" --network=mainnet-bob`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "bob": {
            "vault": "0x2ac98DB41Cbd3172CB7B8FD8A8Ab3b91cFe45dCf",
            "to": "0xa5adCfc8b9B0fe1CbA36659f317eEa431561bdc7",
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
