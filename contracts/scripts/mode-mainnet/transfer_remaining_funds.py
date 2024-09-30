from brownie import accounts

# Execution Command Format:
# `brownie run scripts/mode-mainnet/transfer_remaining_funds.py --network=mode-main -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x2ec59026b885d879e37b23efa7c280187bdcdf8f5baf7001fca640e665943720
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x3185a80ce35a2c81e81364346f78c4226b4ad56929a72f8a9a985d218626970e