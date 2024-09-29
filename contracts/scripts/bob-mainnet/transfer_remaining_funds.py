from brownie import accounts

# Execution Command Format:
# `brownie run scripts/bob-mainnet/transfer_remaining_funds.py --network=bob-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0xb837d21fc0a5ae114586ae904e37de28269e948fbfffea7d13c24e2b63a8ac25
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0xe01c7d164ad86aeda35b839296ad0f6cfc5c2c74d66085e59889cf81367fd96a