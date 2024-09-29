from brownie import accounts

# Execution Command Format:
# `brownie run scripts/bitlayer-mainnet/transfer_remaining_funds.py --network=bitlayer-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x265559fef80e100255a0040f8ad72423a2d8350c240fc720e10e952ddd8e0e3e
    owner.transfer(recipient, owner.balance() * 95 / 100)          # Tx: 0xfa772cf196dcc533ff48a2421d15bc409a5303d8d41c22ac18c90b2574b2bc5b