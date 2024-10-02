import brownie
from brownie import Sigma, Contract

# NOTE: This test designed to run on the development network
# Command to run test: `brownie test tests/test_Sigma.py -I`
def test_setTokenHolders(fn_isolation, contracts, deps, deployer, owner, bob, zero_address):
    fbtc, locked_fbtc, wbtc18, vault = contracts[7], contracts[10], contracts[11], contracts[6],

    ProxyAdmin = deps.ProxyAdmin
    Proxy = deps.TransparentUpgradeableProxy

    # Deploy ProxyAdmin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # Deploy Sigma
    sigma_impl = Sigma.deploy({'from': deployer})
    sigma_proxy = Proxy.deploy(sigma_impl, proxyAdmin, b'', {'from': deployer})

    # Initialize Sigma
    sigma = Contract.from_abi("Sigma", sigma_proxy, Sigma.abi)
    with brownie.reverts("SYS001"):
        sigma.initialize(zero_address, {'from': owner})
    sigma.initialize(owner, {'from': owner})
    assert sigma.hasRole(sigma.DEFAULT_ADMIN_ROLE(), owner)

    # ---Revert Path Testing---

    # Scenario 1: Only a DEFAULT_ADMIN_ROLE can call this function.
    with brownie.reverts():
        sigma.setTokenHolders(fbtc, [], {'from': bob})

    # Scenario 3: Decimals should be the same.
    pools = [
        (fbtc, (vault,)),
        (wbtc18, (vault,))
    ]
    with brownie.reverts("SYS010"):
        sigma.setTokenHolders(fbtc, pools, {'from': owner})

    # ---Happy Path Testing---
    # Scenario 4: The token holders have been set successfully.
    pools = [
        (fbtc, (vault,)),
        (locked_fbtc, (vault,))
    ]

    tx = sigma.setTokenHolders(fbtc, pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigma.getTokenHolders(fbtc) == pools
    assert len(sigma.ListLeadingTokens()) == 1


def test_totalSupply(fn_isolation, contracts, deps, deployer, owner, bob):
    fbtc, wbtc, vault = contracts[7], contracts[5], contracts[6],

    ProxyAdmin = deps.ProxyAdmin
    Proxy = deps.TransparentUpgradeableProxy

    # Deploy ProxyAdmin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # Deploy Sigma
    sigma_impl = Sigma.deploy({'from': deployer})
    sigma_proxy = Proxy.deploy(sigma_impl, proxyAdmin, b'', {'from': deployer})

    # Initialize Sigma
    sigma = Contract.from_abi("Sigma", sigma_proxy, Sigma.abi)
    sigma.initialize(owner, {'from': owner})

    # ---Revert Path Testing---

    # Scenario 1: The leading token hasn't been registered and 'totalSupply' should revert
    with brownie.reverts("USR018"):
        sigma.totalSupply(fbtc)

    # ---Happy Path Testing---

    # Scenario 2: The total supply is zero
    pools = [
        (fbtc, (vault,)),
        (wbtc, (vault,))
    ]

    sigma.setTokenHolders(fbtc, pools, {'from': owner})

    assert sigma.totalSupply(fbtc) == 0

    # Scenario 3: The total supply is updated successfully
    amt = 10000 * 1e8
    fbtc.mint(vault, amt, {'from': owner})
    wbtc.mint(vault, amt, {'from': owner})
    assert sigma.totalSupply(fbtc) == amt * 2

