from brownie import accounts, interface, config, Contract, directBTC, DirectBTCMinter, Vault
import brownie
from web3 import Web3


# ProxyAdmin:  0xC0c9E78BfC3996E8b68D872b29340816495D7e89
# uniBtc Vault:  0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823
# -----
# Deployed directBTC proxy:  0x4213455d10Cf464cC987169DF9A94a10aB0f0723
# Deployed directBTC implementation:  0x322Edee552a536339282C31a5815ea967fadd497
# -----
# Deployed DirectBTCMinter proxy:  0x270A0cbAc24063541d108C63A5a206C83F8Ed275
# Deployed DirectBTCMinter implementation:  0xeEcCdFDFf1c579c84E50541c0BA1bB27A467cD63
#
# Command to run test: `brownie test tests/test_directBTCMinter.py --network=holesky-fork -I`
def test_directBTCMinter(deps):
    uniBtcVault = '0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823'

    owner = accounts.load('testnet-owner')
    operator = accounts.load('testnet-operator')
    recipient = accounts.at('0x50B20dFB650Ca8E353aDbbAD37C609B81623BDf3', True)
    admin = accounts.at('0xbFdDf5e269C74157b157c7DaC5E416d44afB790d', True)
    minterAdmin = owner

    # grantRole admin, setRecipient
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    admin_role = w3.keccak(text='ADMIN_ROLE')
    operator_role = w3.keccak(text='OPERATOR_ROLE')

    #directBTC
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTC_proxy = TransparentUpgradeableProxy.at('0x4213455d10Cf464cC987169DF9A94a10aB0f0723')
    direct_btc = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)

    #directBTCMinter
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTCMinter_proxy = TransparentUpgradeableProxy.at('0x270A0cbAc24063541d108C63A5a206C83F8Ed275')
    direct_btc_minter = Contract.from_abi("DirectBTCMinter", directBTCMinter_proxy, DirectBTCMinter.abi)

    # grantRole operator role
    direct_btc_minter.grantRole(operator_role, operator, {'from': owner})
    assert direct_btc_minter.hasRole(operator_role, operator)

    # grantRole admin
    direct_btc_minter.grantRole(admin_role, owner, {'from': owner})
    assert direct_btc_minter.hasRole(admin_role, owner)

    # setRecipient
    direct_btc_minter.setRecipient(recipient, True, {'from': owner})
    assert direct_btc_minter.recipients(recipient) == True

    # #uniBTCVault
    cap = 50 * 1e8
    vaultProxy = TransparentUpgradeableProxy.at(uniBtcVault)
    uniBTCVault = Contract.from_abi("Vault", vaultProxy, Vault.abi)
    uniBTCVault.setCap(directBTC_proxy.address, cap, {'from': admin})
    assert uniBTCVault.caps(directBTC_proxy.address) == cap

    # before balance
    uni_btc = uniBTCVault.uniBTC()
    erc20_unibtc = interface.IERC20(uni_btc)
    erc20_directbtc = interface.IERC20(direct_btc.address)
    balance_unibtc_1 = erc20_unibtc.balanceOf(recipient)
    balance_directbtc_1 = erc20_directbtc.balanceOf(uniBtcVault)

    # success test
    amount = 10 * 1e8
    direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000001', amount, {'from': operator})
    direct_btc_minter.approveEvent({'from': minterAdmin})

    # after balance
    balance_unibtc_2 = erc20_unibtc.balanceOf(recipient)
    balance2_directbtc_2 = erc20_directbtc.balanceOf(uniBtcVault)
    assert amount == balance_unibtc_2 - balance_unibtc_1
    assert amount == balance2_directbtc_2 - balance_directbtc_1

    direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000002', amount, {'from': operator})
    direct_btc_minter.rejectEvent({'from': minterAdmin})

    with brownie.reverts('USR013'):
        direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000002', amount, {'from': operator})

    # over cap test
    with brownie.reverts('USR003'):
        amount = 100 * 1e8
        direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000003', amount, {'from': operator})
        direct_btc_minter.approveEvent({'from': minterAdmin})

