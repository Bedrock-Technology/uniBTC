import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/mode-mainnet/depend_transfer_proxy.py --network=mainnet-mode -I`


def main():
    
    deps = project.load(
        Path.home() / ".brownie" / "packages" / config["dependencies"][0]
    )

    owner = accounts.load("rockx-eben")
    transfer_proxy_contract = TransferProxy.at(
        "0x782d9a8b9ba6de823835c95242d955508d2b5ea9"
    )
    print("transfer_proxy contract", transfer_proxy_contract)

    transparent_transfer_proxy = Contract.from_abi(
        "TransferProxy", transfer_proxy_contract, TransferProxy.abi
    )

