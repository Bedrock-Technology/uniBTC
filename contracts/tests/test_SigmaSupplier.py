import brownie
from brownie import SigmaSupplier, Contract


def test_setTokenHolders(fn_isolation, contracts, deps, deployer, owner, bob, zero_address):
    fbtc, locked_fbtc, wbtc18, vault = contracts[7], contracts[10], contracts[11], contracts[6],

    ProxyAdmin = deps.ProxyAdmin
    Proxy = deps.TransparentUpgradeableProxy

    # Deploy ProxyAdmin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # Deploy SigmaSupplier
    sigmaSupplier_impl = SigmaSupplier.deploy({'from': deployer})
    sigmaSupplier_proxy = Proxy.deploy(sigmaSupplier_impl, proxyAdmin, b'', {'from': deployer})

    # Initialize SigmaSupplier
    sigmaSupplier = Contract.from_abi("SigmaSupplier", sigmaSupplier_proxy, SigmaSupplier.abi)
    with brownie.reverts("SYS001"):
        sigmaSupplier.initialize(zero_address, {'from': owner})
    sigmaSupplier.initialize(owner, {'from': owner})
    assert sigmaSupplier.hasRole(sigmaSupplier.DEFAULT_ADMIN_ROLE(), owner)

    # ---Revert Path Testing---

    # Scenario 1: Only a DEFAULT_ADMIN_ROLE can call this function.
    with brownie.reverts():
        sigmaSupplier.setTokenHolders(fbtc, [], {'from': bob})

    # Scenario 3: Decimals should be the same.
    pools = [
        (fbtc, (vault,)),
        (wbtc18, (vault,))
    ]
    with brownie.reverts("SYS010"):
        sigmaSupplier.setTokenHolders(fbtc, pools, {'from': owner})

    # ---Happy Path Testing---
    # Scenario 4: The token holders have been set successfully.
    pools = [
        (fbtc, (vault,)),
        (locked_fbtc, (vault,))
    ]

    tx = sigmaSupplier.setTokenHolders(fbtc, pools, {'from': owner})
    assert "TokenHoldersSet" in tx.events
    assert sigmaSupplier.getTokenHolders(fbtc) == pools
    assert len(sigmaSupplier.ListLeadingTokens()) == 1


def test_totalSupply(fn_isolation, contracts, deps, deployer, owner, bob):
    fbtc, wbtc, vault = contracts[7], contracts[5], contracts[6],

    ProxyAdmin = deps.ProxyAdmin
    Proxy = deps.TransparentUpgradeableProxy

    # Deploy ProxyAdmin
    proxyAdmin = ProxyAdmin.deploy({'from': owner})

    # Deploy SigmaSuppliers
    sigmaSupplier_impl = SigmaSupplier.deploy({'from': deployer})
    sigmaSupplier_proxy = Proxy.deploy(sigmaSupplier_impl, proxyAdmin, b'', {'from': deployer})

    # Initialize SigmaSupplier
    sigmaSupplier = Contract.from_abi("SigmaSupplier", sigmaSupplier_proxy, SigmaSupplier.abi)
    sigmaSupplier.initialize(owner, {'from': owner})

    # Set holders
    pools = [
        (fbtc, (vault,)),
        (wbtc, (vault,))
    ]

    sigmaSupplier.setTokenHolders(fbtc, pools, {'from': owner})

    # ---Happy Path Testing---
    # Scenario 1: The total supply is zero
    assert sigmaSupplier.totalSupply(fbtc) == 0

    # Scenario 2: The total supply is updated successfully
    amt = 10000 * 1e8
    fbtc.mint(vault, amt, {'from': owner})
    wbtc.mint(vault, amt, {'from': owner})
    assert sigmaSupplier.totalSupply(fbtc) == amt * 2

