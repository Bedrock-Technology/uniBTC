from brownie import accounts

# Execution Command Format:
# `brownie run scripts/optimism-mainnet/transfer_remaining_funds.py --network=optimism-main -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x039a364d8d6d86b963930554aee3d7f4144b8d37ba69a7809244794b7c4548ff
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x677e02870edce4a41df16a0aff0cdf5023d18c19ca01278593d3e2afd31fc821