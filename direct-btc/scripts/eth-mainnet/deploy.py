from brownie import directBTC, DirectBTCMinter, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/deploy.py main "mainnet-deployer" "mainnet-owner" --network=mainnet -I`

def main(deployer="mainnet-deployer", owner="mainnet-owner"):

    # make sure to set the correct ProxyAdmin and uniBtcVault address
    proxyAdmin = '0x029E4FbDAa31DE075dD74B2238222A08233978f6'
    uniBtcVault = '0x047d41f2544b7f63a8e991af2068a363d210d6da'
    # set the directBTC operator address
    directBTC_operator = '0x0'

    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")

    minter_role = w3.keccak(text='MINTER_ROLE')
    operator_role = w3.keccak(text='OPERATOR_ROLE')

    deployer = accounts.load(deployer)
    owner = accounts.load(owner)

    # Deploy directBTC
    directBTC_impl = directBTC.deploy({'from': deployer})
    directBTC_proxy = TransparentUpgradeableProxy.deploy(directBTC_impl, proxyAdmin, b'', {'from': deployer})

    # Deploy minter
    minter_impl = DirectBTCMinter.deploy({'from': deployer})
    minter_proxy = TransparentUpgradeableProxy.deploy(minter_impl, proxyAdmin, b'', {'from': deployer})

    # init minter
    minter_transparent = Contract.from_abi("DirectBTCMinter", minter_proxy, DirectBTCMinter.abi)
    minter_transparent.initialize(owner, directBTC_proxy, uniBtcVault, {'from': owner})
    assert minter_transparent.hasRole(default_admin_role, owner)
    assert minter_transparent.directBTC() == directBTC_proxy

    # # Set minter role
    # minter_transparent.grantRole(operator_role, directBTC_operator, {'from': owner})
    # assert minter_transparent.hasRole(operator_role, directBTC_operator)

    # init directBTC
    transparent_directBTC = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)
    transparent_directBTC.initialize(owner, minter_proxy, {'from': owner})
    assert transparent_directBTC.hasRole(default_admin_role, owner)
    assert transparent_directBTC.hasRole(minter_role, minter_proxy)

    print("ProxyAdmin: ", proxyAdmin)
    print("uniBtc Vault: ", uniBtcVault)
    print("-----")
    print("Deployed directBTC proxy: ", directBTC_proxy)
    print("Deployed directBTC impl : ", directBTC_impl)
    print("-----")
    print("Deployed DirectBTCMinter proxy: ", minter_proxy)
    print("Deployed DirectBTCMinter impl : ", minter_impl)





