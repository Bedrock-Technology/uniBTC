from brownie import accounts

# Execution Command Format:
# `brownie run scripts/mantle-mainnet/transfer_remaining_funds.py --network=mantle-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x03fb1ea4c3dfefc064b63815f32184d1f2a523790ef57460b38a4d5271e751b3
    owner.transfer(recipient, owner.balance() * 95 / 100)          # Tx: 0xa60e7d338aeeb787c924b61d5529b4386f7782933382de6e073d6b4308898a72