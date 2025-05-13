import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/ethereum-mainnet/deploy_transfer_proxy.py main "rockx-eben" "ethereum" --network=mainnet-public`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "ethereum": {
            "vault": "0x1419b48e5C1f5ce413Cf02D6dcbe1314170E3386",
            "to": "0x1F3c54EC74F1A5C0Bc19af04dAdFa1A677231ac9",
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
