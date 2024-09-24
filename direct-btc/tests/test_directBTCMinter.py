from brownie import accounts, interface, config, Contract, directBTC, DirectBTCMinter
import brownie

#ProxyAdmin address:  0x56c3024eB229Ca0570479644c78Af9D53472B3e4
#uniBtc Vault:  0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823
#-----
#Deployed directBTC proxy address:  0xfB5228dc26aDB70e0a652879761C4490c4e45023
#Deployed directBTC implementation address:  0x02335f4B4B896f37ea83274A6A926d40b62Da626
#-----
#Deployed minter proxy address:  0x8D5AeFCC9a2BA96784775f930FD64F2b35750Ab5
#Deployed minter implementation address:  0x2a3357F709bb54f6Dcb93DbD58DDce3963299189

# Command to run test: `brownie test tests/test_directBTCMinter.py --network=holesky-fork -I`
def test_directBTCMinter(deps):

    uniBtcVault = '0x97e16DB82E089D0C9c37bc07F23FcE98cfF04823'
    #proxy admin
    ProxyAdmin = deps.ProxyAdmin
    admin = accounts.at('0xbFdDf5e269C74157b157c7DaC5E416d44afB790d', True)
    proxyAdmin = ProxyAdmin.at('0xC0c9E78BfC3996E8b68D872b29340816495D7e89')

    owner = accounts.at('0xF2Ff70B9dE74432c0dfC3dc4F43BA22Fb4da2B55', True)
    deployer = accounts.at('0x7e694e48c2Ac40eFf0EEE1f4521ea692352D4677', True)
    operator = accounts.at('0x2D4405dED8b41b9FC133c98927f2592408008096', True)
    recipient = accounts.at('0x50B20dFB650Ca8E353aDbbAD37C609B81623BDf3', True)
    minterAdmin = owner
    
    #directBTC
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTC_proxy = TransparentUpgradeableProxy.at('0xdC3c6eE727A59e45829568fe02d4F2d323fA0f45')
    direct_btc = Contract.from_abi("directBTC", directBTC_proxy, directBTC.abi)
    
    #directBTCMinter
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy
    directBTCMinter_proxy = TransparentUpgradeableProxy.at('0x72EC6e637BAF1698250a02DeED8b029ABDBB71EB')
    direct_btc_minter = Contract.from_abi("DirectBTCMinter", directBTCMinter_proxy, DirectBTCMinter.abi)

    # before balance
    uni_btc = interface.IVault(uniBtcVault).uniBTC()
    erc20_unibtc = interface.IERC20(uni_btc)
    erc20_directbtc = interface.IERC20(direct_btc.address)
    balance_b = erc20_unibtc.balanceOf(recipient)
    balance2_b = erc20_directbtc.balanceOf(uniBtcVault)

    amount = 10 * 1e8
    direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000001', amount, {'from': operator})
    direct_btc_minter.approveEvent({'from': minterAdmin})

    # after balance
    balance_a = erc20_unibtc.balanceOf(recipient)
    balance2_a = erc20_directbtc.balanceOf(uniBtcVault)
    assert amount == balance_a - balance_b
    assert amount == balance2_a - balance2_b
    
    direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000002', amount, {'from': operator})
    direct_btc_minter.rejectEvent({'from': minterAdmin})

    with brownie.reverts('USR013'):
        direct_btc_minter.receiveEvent(recipient, '0x0000000000000000000000000000000000000000000000000000000000000002', amount, {'from': operator})
    
    # #uniBTCVault
    # cap = 5000 * 1e8
    # vaultProxy = TransparentUpgradeableProxy.at(uniBtcVault)
    # uniBTCVault = Contract.from_exploer("Vault", vaultProxy, Vault.abi)
    # uniBTCVault.setCap(directBTC.address, cap, {'from': admin})
    # assert uniBTCVault.caps(directBTC.address) == cap
    
    


