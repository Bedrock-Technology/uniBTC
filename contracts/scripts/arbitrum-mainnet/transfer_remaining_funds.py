from brownie import accounts

# Execution Command Format:
# `brownie run scripts/arbitrum-mainnet/transfer_remaining_funds.py --network=arbitrum-main -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x04bda0eb538015f1b3889404d1963903439d70a52be7566c4fb7f60482c1c9b7
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x9fd2f7b6c4a1eae6425c759e2a1ae419b6a3b2004a4302f2071f52fbfc5700c6