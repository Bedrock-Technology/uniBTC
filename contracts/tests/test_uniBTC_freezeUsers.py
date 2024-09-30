import brownie
from brownie import accounts, uniBTC, Contract, project, config

# NOTE: This test designed to run on the fork Ethereum network
# Command to run test: `brownie test tests/test_vault_fix_exploit.py --network=mainnet-public-fork`

def test_freeze_users_after_upgrade(fn_isolation, deps):
    ProxyAdmin = deps.ProxyAdmin

    frozen_user = accounts.at(accounts[0], True)
    bob = accounts.at(accounts[1], True)
    smith = accounts.at(accounts[2], True)
    deployer = accounts.at(accounts[3], True)
    default_admin = "0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3"
    default_freeze_to_recipient = "0x899c284A89E113056a72dC9ade5b60E80DD3c94f"
    vault = accounts.at("0x047d41f2544b7f63a8e991af2068a363d210d6da", True)

    uni_btc = uniBTC.at("0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568")

    # Mint some uniBTC
    amt = 2e18
    uni_btc.mint(frozen_user, amt, {'from': vault})
    uni_btc.mint(smith, amt, {'from': vault})

    # Check current uniBTC contract status before upgrade
    assert uni_btc.hasRole(uni_btc.DEFAULT_ADMIN_ROLE(), default_admin)
    assert  uni_btc.hasRole(uni_btc.MINTER_ROLE(), vault)

    # Upgrade uniBTC
    proxyAdmin = ProxyAdmin.at("0x029E4FbDAa31DE075dD74B2238222A08233978f6")

    uniBTC_impl = uniBTC.deploy({'from': deployer})
    reinitialize_data = uniBTC_impl.initialize.encode_input(default_admin, vault, [frozen_user])
    proxyAdmin.upgradeAndCall(uni_btc.address, uniBTC_impl, reinitialize_data, {'from': default_admin})

    # Check reinitialized uniBTC contract status after upgrade
    assert uni_btc.hasRole(uni_btc.DEFAULT_ADMIN_ROLE(), default_admin)
    assert  uni_btc.hasRole(uni_btc.MINTER_ROLE(), vault)
    assert uni_btc.frozenUsers(frozen_user)
    assert uni_btc.freezeToRecipient() == default_freeze_to_recipient

    assert uni_btc.decimals() == 8
    assert uni_btc.symbol() == "uniBTC"
    assert uni_btc.name() == "uniBTC"

    # Scenario 1: Only the default admin can set the freezeToRecipient as bob.
    with brownie .reverts():
        uni_btc.setFreezeToRecipient(default_freeze_to_recipient, {'from': frozen_user})
    uni_btc.setFreezeToRecipient(bob, {'from': default_admin})
    freeze_to_recipient = uni_btc.freezeToRecipient()
    assert freeze_to_recipient == bob

    # Scenario 2: The freezeToRecipient is allowed to be transferred from a normal account after the upgrade.
    tx = uni_btc.transfer(freeze_to_recipient, amt/2, {'from': smith})
    assert "Transfer" in tx.events

    # Scenarios 3: A frozen account can only transfer to the dedicated account after the upgrade.
    with brownie .reverts("USR016"):
        uni_btc.transfer(smith, amt/2, {'from': frozen_user})
    tx = uni_btc.transfer(freeze_to_recipient, amt/2, {'from': frozen_user})
    assert "Transfer" in tx.events

    uni_btc.approve(smith, amt, {'from': frozen_user})
    with brownie .reverts("USR016"):
        uni_btc.transferFrom(frozen_user, smith, amt/2, {'from': smith})
    tx = uni_btc.transferFrom(frozen_user, freeze_to_recipient, amt/2, {'from': smith})
    assert "Transfer" in tx.events

    # Scenarios 4: Minting should work as usual after the upgrade.
    total_supply = uni_btc.totalSupply()
    uni_btc.mint(bob, amt, {'from': vault})
    assert "Transfer" in tx.events
    assert uni_btc.totalSupply() == total_supply + amt


def test_freeze_users_after_new_deployment(fn_isolation, deps):
    ProxyAdmin = deps.ProxyAdmin
    TransparentUpgradeableProxy = deps.TransparentUpgradeableProxy

    frozen_user = accounts.at(accounts[0], True)
    bob = accounts.at(accounts[1], True)
    smith = accounts.at(accounts[2], True)
    deployer = accounts.at(accounts[3], True)
    default_admin = "0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3"
    default_freeze_to_recipient = "0x899c284A89E113056a72dC9ade5b60E80DD3c94f"
    vault = accounts.at("0x047d41f2544b7f63a8e991af2068a363d210d6da", True)

    # Deploy uniBTC
    proxyAdmin = ProxyAdmin.at("0x029E4FbDAa31DE075dD74B2238222A08233978f6")
    uniBTC_impl = uniBTC.deploy({'from': deployer})
    initialize_data = uniBTC_impl.initialize.encode_input(default_admin, vault, [frozen_user])
    uniBTC_proxy = TransparentUpgradeableProxy.deploy(uniBTC_impl, proxyAdmin, initialize_data, {'from': deployer})
    uni_btc = Contract.from_abi("uniBTC", uniBTC_proxy, uniBTC.abi)

    # Check uniBTC contract status after deployment
    assert uni_btc.hasRole(uni_btc.DEFAULT_ADMIN_ROLE(), default_admin)
    assert uni_btc.hasRole(uni_btc.MINTER_ROLE(), vault)
    assert uni_btc.frozenUsers(frozen_user)
    assert uni_btc.freezeToRecipient() == default_freeze_to_recipient

    assert uni_btc.decimals() == 8
    assert uni_btc.symbol() == "uniBTC"
    assert uni_btc.name() == "uniBTC"

    # Mint some uniBTC
    amt = 2e18
    uni_btc.mint(frozen_user, amt, {'from': vault})
    uni_btc.mint(smith, amt, {'from': vault})

    # Scenario 1: Only the default admin can set the freezeToRecipient as bob.
    with brownie .reverts():
        uni_btc.setFreezeToRecipient(default_freeze_to_recipient, {'from': frozen_user})
    uni_btc.setFreezeToRecipient(bob, {'from': default_admin})
    freeze_to_recipient = uni_btc.freezeToRecipient()
    assert freeze_to_recipient== bob

    # Scenario 2: The freezeToRecipient is allowed to be transferred from a normal account.
    tx = uni_btc.transfer(freeze_to_recipient, amt/2, {'from': smith})
    assert "Transfer" in tx.events

    # Scenarios 3: A frozen account can only transfer to the dedicated account
    with brownie .reverts("USR016"):
        uni_btc.transfer(smith, amt/2, {'from': frozen_user})
    tx = uni_btc.transfer(freeze_to_recipient, amt/2, {'from': frozen_user})
    assert "Transfer" in tx.events

    uni_btc.approve(smith, amt, {'from': frozen_user})
    with brownie .reverts("USR016"):
        uni_btc.transferFrom(frozen_user, smith, amt/2, {'from': smith})
    tx = uni_btc.transferFrom(frozen_user, freeze_to_recipient, amt/2, {'from': smith})
    assert "Transfer" in tx.events

    # Scenarios 4: Minting should work as usual
    total_supply = uni_btc.totalSupply()
    uni_btc.mint(bob, amt, {'from': vault})
    assert "Transfer" in tx.events
    assert uni_btc.totalSupply() == total_supply + amt