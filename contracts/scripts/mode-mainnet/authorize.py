from brownie import uniBTC, Vault, accounts, Contract, project, config
from pathlib import Path
from web3 import Web3

# Execution Command Format:
# `brownie run scripts/mode-mainnet/authorize.py main "uniBTCMainnetAdmin" --network=mode-main -I`


def main(owner="owner"):
    deps = project.load(  Path.home() / ".brownie" / "packages" / config["dependencies"][0])
    ProxyAdmin = deps.ProxyAdmin

    w3 = Web3(Web3.HTTPProvider('http://localhost:8545'))
    default_admin_role = w3.to_bytes(hexstr="0x00")
    pauser_role = w3.keccak(text='PAUSER_ROLE')
    minter_role = w3.keccak(text='MINTER_ROLE')

    owner = accounts.load(owner)
    new_owner = "0x1fc76b7C6F092e0566Ce9Bbb9c6803Ba5e45Ba32"

    proxyAdmin_address = "0xb3f925B430C60bA467F7729975D5151c8DE26698"
    uniBTC_proxy_address = "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"
    vault_proxy_address = "0x84E5C854A7fF9F49c888d69DECa578D406C26800"

    proxyAdmin = ProxyAdmin.at(proxyAdmin_address)
    uniBTC_transparent = Contract.from_abi("uniBTC", uniBTC_proxy_address, uniBTC.abi)
    vault_transparent = Contract.from_abi("Vault", vault_proxy_address, Vault.abi)


    # -------------------- uniBTC --------------------
    # Transfer default admin role
    uniBTC_transparent.grantRole(default_admin_role, new_owner, {'from': owner})     # Tx: [0xc7e31d5f9fbbc255238a3ef26f554cd7bfab14bf587ead3674090c4ccbe6b006](https://modescan.io/tx/0xc7e31d5f9fbbc255238a3ef26f554cd7bfab14bf587ead3674090c4ccbe6b006)
    assert uniBTC_transparent.hasRole(default_admin_role, new_owner)
    uniBTC_transparent.renounceRole(default_admin_role, owner, {'from': owner})      # Tx: [0x6acb9d38dfc8b91d9a2f227d81797a38aee2e8304586106b245aab2279bcaed2](https://modescan.io/tx/0x6acb9d38dfc8b91d9a2f227d81797a38aee2e8304586106b245aab2279bcaed2)
    assert not uniBTC_transparent.hasRole(default_admin_role, owner)


    # -------------------- Vault --------------------
    # Transfer pauser role
    vault_transparent.grantRole(pauser_role, new_owner, {'from': owner})             # Tx: [0xe86f0361042afe02003f5dd0d19b106491393f268c408cf58fd86160332df140](https://modescan.io/tx/0xe86f0361042afe02003f5dd0d19b106491393f268c408cf58fd86160332df140)
    assert vault_transparent.hasRole(pauser_role, new_owner)
    vault_transparent.renounceRole(pauser_role, owner, {'from': owner})              # Tx: [0xb441dea09e05fb177d012218388c15511a483ff731a4f9b3c1a3d3b3c8e73b63](https://modescan.io/tx/0xb441dea09e05fb177d012218388c15511a483ff731a4f9b3c1a3d3b3c8e73b63)
    assert not vault_transparent.hasRole(pauser_role, owner)

    # Transfer default admin role
    vault_transparent.grantRole(default_admin_role, new_owner, {'from': owner})      # Tx: [0xe59fda4de21b3b1d75ccb3f74fdbef545dfdb168014caf99147eceb7e33c7dc5](https://modescan.io/tx/0xe59fda4de21b3b1d75ccb3f74fdbef545dfdb168014caf99147eceb7e33c7dc5)
    assert vault_transparent.hasRole(default_admin_role, new_owner)
    vault_transparent.renounceRole(default_admin_role, owner, {'from': owner})       # Tx: [0x8e7c0743ab61e2aaca2cbbcf0997459288704a27e5fdc49cc50a9e4b084132d6](https://modescan.io/tx/0x8e7c0743ab61e2aaca2cbbcf0997459288704a27e5fdc49cc50a9e4b084132d6)
    assert not vault_transparent.hasRole(default_admin_role, owner)

    # -------------------- ProxyAdmin --------------------
    # Transfer ownership
    proxyAdmin.transferOwnership(new_owner, {'from': owner})                         # Tx: [0xa88a8e508c6e0cfdc9ca0620d3336cb269f6e8d45f72e979ec171d359b993d66](https://modescan.io/tx/0xa88a8e508c6e0cfdc9ca0620d3336cb269f6e8d45f72e979ec171d359b993d66)
    assert proxyAdmin.owner() == new_owner