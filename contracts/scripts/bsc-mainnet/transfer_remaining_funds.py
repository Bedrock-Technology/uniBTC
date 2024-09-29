from brownie import accounts

# Execution Command Format:
# `brownie run scripts/bsc-mainnet/transfer_remaining_funds.py --network=bsc-main -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 95 / 100)    # Tx: 0xc939421a4e48d890824485bac9850f58a7aa5f94d095738e0ebf936cf565d552
    owner.transfer(recipient, owner.balance() * 95 / 100)          # Tx: 0x3fdcfc672c244ced5a8367886a2f6be344c83adc62fb5412f9f4bdf179c5001f