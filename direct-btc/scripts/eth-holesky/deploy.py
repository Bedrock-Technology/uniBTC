from brownie import directBTC, DirectBTCMinter, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3


# Execution Command Format:
# `brownie run scripts/deploy.py main "testnet-deployer" "testnet-owner" --network=holesky -I`

def main(deployer="testnet-deployer", owner="testnet-owner"):

    # make sure to set the correct ProxyAdmin and uniBtcVault address
    proxyAdmin = '0xC0c9E78BfC3996E8b68D872b29340816495D7e89'
    uniBtcVault = '0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823'
    directBTC_operator = accounts.load('testnet-operator')
    recipient = '0x50B20dFB650Ca8E353aDbbAD37C609B81623BDf3'

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
    
    # Set operator role
    minter_transparent.grantRole(operator_role, directBTC_operator, {'from': owner})
    assert minter_transparent.hasRole(operator_role, directBTC_operator)

    # init directBTC
    transparent_directBTC = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)
    transparent_directBTC.initialize(owner, minter_proxy, {'from': owner})
    assert transparent_directBTC.hasRole(default_admin_role, owner)
    assert transparent_directBTC.hasRole(minter_role, minter_proxy)

    print("ProxyAdmin: ", proxyAdmin)
    print("uniBtc Vault: ", uniBtcVault)
    print("-----")
    print("Deployed directBTC proxy: ", directBTC_proxy)
    print("Deployed directBTC implementation: ", directBTC_impl)
    print("-----")
    print("Deployed DirectBTCMinter proxy: ", minter_proxy)
    print("Deployed DirectBTCMinter implementation: ", minter_impl)

    # grantRole admin, setRecipient
    admin_role = w3.keccak(text='ADMIN_ROLE')
    minter_transparent.grantRole(admin_role, owner, {'from': owner})
    assert minter_transparent.hasRole(admin_role, owner)
    minter_transparent.setRecipient(recipient, True, {'from': owner})
    assert minter_transparent.recipients(recipient) == True

