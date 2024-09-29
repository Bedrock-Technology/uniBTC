from brownie import accounts

# Execution Command Format:
# `brownie run scripts/zeta-mainnet/transfer_remaining_funds.py --network=zeta-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x0ac905a3e0e60355bb183d7e7038cba7aad6978219829db24cb04ef66a7ffab0
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x23fde1bd2f24c9c16887972fa251fc74fb5d0c69281c95e59576953d1bd65bcf