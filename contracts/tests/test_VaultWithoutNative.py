import brownie
from brownie import accounts, uniBTC, LockedFBTC, VaultWithoutNative, Contract, project, config

# NOTE: This test designed to run on the fork Ethereum network
# Command to run test: `brownie test tests/test_VaultWithoutNative.py --network=mainnet-public-fork`

def test_setCaps_after_upgrade(fn_isolation, deps, zero_address, roles):
    ProxyAdmin = deps.ProxyAdmin

    deployer = accounts.at(accounts[3], True)
    default_admin = "0xC9dA980fFABbE2bbe15d4734FDae5761B86b5Fc3"
    vault_proxy_addr = "0x047d41f2544b7f63a8e991af2068a363d210d6da"
    sigma_proxy_addr = "0x94C7F81E3B0458daa721Ca5E29F6cEd05CCCE2B3" # supply feeder

    cap_8 = 5000 * 1e8

    native_btc = "0xbeDFFfFfFFfFfFfFFfFfFFFFfFFfFFffffFFFFFF"
    fbtc = deps.ERC20.at("0xc96de26018a54d51c097160568752c4e3bd6c364") # decimals = 8
    wbtc = deps.ERC20.at("0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599") # decimals = 8
    cbBTC = deps.ERC20.at("0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf") # decimals = 8
    uni_btc = uniBTC.at("0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568") # decimals = 8
    locked_fbtc = LockedFBTC.at("0xd681C5574b7F4E387B608ed9AF5F5Fc88662b37c") # decimals = 8

    # Upgrade uniBTC
    proxyAdmin = ProxyAdmin.at("0x029E4FbDAa31DE075dD74B2238222A08233978f6")
    vault_without_native_impl = VaultWithoutNative.deploy({'from': deployer})
    proxyAdmin.upgrade(vault_proxy_addr, vault_without_native_impl, {'from': default_admin})
    vault_without_native = Contract.from_abi("VaultWithoutNative", vault_proxy_addr, VaultWithoutNative.abi)

    # Check status after Vault upgrade to VaultWithoutNative
    assert vault_without_native.hasRole(roles[3], default_admin)
    assert vault_without_native.uniBTC() == uni_btc.address
    assert vault_without_native.paused(native_btc)
    assert vault_without_native.caps(native_btc) == 0
    assert vault_without_native.caps(fbtc) == cap_8
    assert vault_without_native.caps(wbtc) == cap_8
    assert vault_without_native.caps(cbBTC) == cap_8
    assert vault_without_native.EXCHANGE_RATE_BASE() == 1e10
    assert vault_without_native.supplyFeeder() == sigma_proxy_addr
    assert vault_without_native.balance() > 0  # balance exploited
    assert fbtc.balanceOf(vault_without_native) > 0
    assert wbtc.balanceOf(vault_without_native) > 0
    assert locked_fbtc.balanceOf(vault_without_native) > 0

    # Scenario 1: Native BTC is not allowed to have a cap
    with brownie .reverts("SYS011"):
        vault_without_native.setCap(native_btc, cap_8, {'from': default_admin})

    # Scenario 2: Zero address is not allowed to have a cap
    with brownie .reverts("SYS003"):
        vault_without_native.setCap(zero_address, cap_8, {'from': default_admin})

    # Scenario 3: Normal wrapped BTC token with correct decimals allowed to have a cap
    tx = vault_without_native.setCap(cbBTC.address, cap_8 * 2, {'from': default_admin})
    assert vault_without_native.caps(cbBTC) == cap_8 * 2
