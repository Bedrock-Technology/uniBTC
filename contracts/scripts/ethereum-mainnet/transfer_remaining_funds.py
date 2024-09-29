from brownie import accounts

# Execution Command Format:
# `brownie run scripts/ethereum-mainnet/transfer_remaining_funds.py --network=eth-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x865011e6c10d869a805673a843a032625b5310d24b4efe1468559a76fb31c8de
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x5b9128a7e0a1b58d6896f7d085cd6c90ffad808c43ed9ad7e06219f948586b90