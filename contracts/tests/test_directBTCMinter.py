from brownie import accounts, interface, config, Contract, directBTC, DirectBTCMinter, Vault
import brownie
from web3 import Web3


#| Contract                     | Address                                    |
#|------------------------------|--------------------------------------------|
#| ProxyAdmin                   | 0xC0c9E78BfC3996E8b68D872b29340816495D7e89 |
#| uniBtcVault                  | 0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823 |
#|------------------------------|--------------------------------------------|
#| directBTC proxy              | 0xAE250F66C8cD0A5812d0b89F5B3eFB7B426459Eb |
#| directBTC imple              | 0x7a79A591A0f946B7B8537bfCC737C5EeaA8D3182 |
#|------------------------------|--------------------------------------------|
#| DirectBTCMinter proxy        | 0x7c0384D4D8Cd9e8d0D0F3CD2d55d967Aa3776f95 |
#| DirectBTCMinter imple        | 0x617F80273eA88600a17fD9F601290635317eDD61 |
#|------------------------------|--------------------------------------------|
#
# Command to run test: `brownie test tests/test_directBTCMinter.py --network=holesky-fork -I -W ignore::DeprecationWarning`
def test_directBTCMinter(deps):
    uniBtcVault = '0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823'

    owner = accounts.load('testnet-owner')
    operator = accounts.load('testnet-operator')
    recipient = accounts.at('0x50B20dFB650Ca8E353aDbbAD37C609B81623BDf3', True)
    admin = accounts.at('0xbFdDf5e269C74157b157c7DaC5E416d44afB790d', True)
    minterAdmin = owner

    # grantRole admin, setRecipient
    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    approver_role = w3.keccak(text='APPROVER_ROLE')
    operator_role = w3.keccak(text='L1_MINTER_ROLE')

    #directBTC
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTC_proxy = TransparentUpgradeableProxy.at('0xAE250F66C8cD0A5812d0b89F5B3eFB7B426459Eb')
    direct_btc = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)

    #directBTCMinter
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTCMinter_proxy = TransparentUpgradeableProxy.at('0x7c0384D4D8Cd9e8d0D0F3CD2d55d967Aa3776f95')
    direct_btc_minter = Contract.from_abi("DirectBTCMinter", directBTCMinter_proxy, DirectBTCMinter.abi)

    # grantRole operator role
    direct_btc_minter.grantRole(operator_role, operator, {'from': owner})
    assert direct_btc_minter.hasRole(operator_role, operator)

    # validate approver_role
    assert direct_btc_minter.hasRole(approver_role, owner)
    assert direct_btc_minter.hasRole(operator_role, owner)

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
    direct_btc_minter.receiveEvent(recipient, '0x01', amount, {'from': operator})
    direct_btc_minter.approveEvent('0x01', {'from': minterAdmin})

    # after balance
    balance_unibtc_2 = erc20_unibtc.balanceOf(recipient)
    balance2_directbtc_2 = erc20_directbtc.balanceOf(uniBtcVault)
    assert amount == balance_unibtc_2 - balance_unibtc_1
    assert amount == balance2_directbtc_2 - balance_directbtc_1

    #reject
    direct_btc_minter.receiveEvent(recipient, '0x02', amount, {'from': operator})
    direct_btc_minter.rejectEvent('0x02', {'from': minterAdmin})
    with brownie.reverts('USR013'):
        direct_btc_minter.receiveEvent(recipient, '0x02', amount, {'from': operator})

    # over cap test
    amount = 100 * 1e8
    direct_btc_minter.receiveEvent(recipient, '0x03', amount, {'from': operator})
    with brownie.reverts('USR003'):
        direct_btc_minter.approveEvent('0x03', {'from': minterAdmin})

    direct_btc_minter.rejectEvent('0x03', {'from': minterAdmin})

    # approve not match
    amount = 1 * 1e8
    direct_btc_minter.receiveEvent(recipient, '0x04', amount, {'from': operator})
    with brownie.reverts('USR015'):
        direct_btc_minter.approveEvent('0xA4', {'from': minterAdmin})

    npe = direct_btc_minter.nextPendingEvent()
    print(npe)
    direct_btc_minter.approveEvent('0x04', {'from': minterAdmin})

    # reject not match
    direct_btc_minter.receiveEvent(recipient, '0x05', amount, {'from': operator})
    with brownie.reverts('USR015'):
        direct_btc_minter.rejectEvent('0xA5', {'from': minterAdmin})

    direct_btc_minter.rejectEvent('0x05', {'from': minterAdmin})

    # view next
    direct_btc_minter.receiveEvent(recipient, '0x06', 6 * 1e8, {'from': operator})
    direct_btc_minter.receiveEvent(recipient, '0x07', 7 * 1e8, {'from': operator})
    direct_btc_minter.receiveEvent(recipient, '0x08', 8 * 1e8, {'from': operator})

    npe = direct_btc_minter.nextPendingEvent()
    txHash, event = npe
    assert txHash == '0x06'
    assert event[1] == 6 * 1e8

