import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/bera_mainnet_d/deploy_transfer_proxy_br.py main "rockx-eben" "bera" --network=bera-mainnet`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "bera": {
            "vault": "0xF9775085d726E782E83585033B58606f7731AB18",
            "to": "0xb1c33E68dF3e0A27D46dF1ca3a21bDC22aFFe8BB",
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
