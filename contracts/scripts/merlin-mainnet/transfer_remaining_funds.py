from brownie import accounts

# Execution Command Format:
# `brownie run scripts/merlin-mainnet/transfer_remaining_funds.py --network=merlin-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x42c904ba23a5291468b43d5b4d92fcc1cd66e13e86a8220c408d3b99d9792905
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x5d7293bda3574933b2abfa438318ee15d87aa57569ebee212f34d78c42c806e1