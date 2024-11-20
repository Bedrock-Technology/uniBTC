import brownie
from brownie import *
from pathlib import Path

# Execution Command Format:
# `brownie run scripts/redeem_proxy_deploy.py main "mainnet-deployer" "ethereum" --network=mainnet`


def main(deployer_account="deployer", network_cfg="ethereum"):
    config_contact = {
        "ethereum": {
            "uniBTC_proxy": "0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568",  # https://etherscan.io/address/0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568
            "vault_proxy": "0x047D41F2544B7F63A8e991aF2068a363d210d6Da",  # https://etherscan.io/address/0x047D41F2544B7F63A8e991aF2068a363d210d6Da
            "redeem_owner": "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB",  # https://etherscan.io/address/0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB
            "redeem_time_duration": 691201,  # 8 days time duration
            "whitelist_enabled": True,
            "contract_deployer": "0x029E4FbDAa31DE075dD74B2238222A08233978f6",  # deployer account
        },
    }

    deps = project.load(
        Path.home() / ".brownie" / "packages" / config["dependencies"][0]
    )
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    assert config_contact[network_cfg]["redeem_owner"] != ""
    assert config_contact[network_cfg]["uniBTC_proxy"] != ""
    assert config_contact[network_cfg]["vault_proxy"] != ""
    assert config_contact[network_cfg]["redeem_time_duration"] > 0  # 691200
    assert config_contact[network_cfg]["contract_deployer"] != ""

    deployer = accounts.load(deployer_account)
    # deploy DelayRedeemRouter contract
    delay_redeem_router_contract = DelayRedeemRouter.deploy({"from": deployer})
    print("delay_redeem_router contract", delay_redeem_router_contract)

    data = DelayRedeemRouter[-1].initialize.encode_input(
        config_contact[network_cfg]["redeem_owner"],
        config_contact[network_cfg]["uniBTC_proxy"],
        config_contact[network_cfg]["vault_proxy"],
        config_contact[network_cfg]["redeem_time_duration"],
        config_contact[network_cfg]["whitelist_enabled"],
    )
    delay_redeem_router_proxy = TransparentUpgradeableProxy.deploy(
        delay_redeem_router_contract,
        config_contact[network_cfg]["contract_deployer"],
        data,
        {"from": deployer},
    )
    print("delay_redeem_router proxy", delay_redeem_router_proxy)

    transparent_delay_redeem_router = Contract.from_abi(
        "DelayRedeemRouter", delay_redeem_router_proxy, DelayRedeemRouter.abi
    )
    default_admin_role = transparent_delay_redeem_router.DEFAULT_ADMIN_ROLE()
    assert (
        transparent_delay_redeem_router.hasRole(
            default_admin_role, config_contact[network_cfg]["redeem_owner"]
        )
        == True
    )
