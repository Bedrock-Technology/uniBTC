from brownie import accounts

# Execution Command Format:
# `brownie run scripts/b2-mainnet/transfer_remaining_funds.py --network=b2-mainnet -I`


def main():
    deployer = accounts.load("uniBTCMainnetDeployer")   # 0x4c262Baa7c09a0234E67A1FF39D7C02A02F003f6
    owner = accounts.load("uniBTCMainnetAdmin") # 0x5af438CaF91e5A4C490d2DB2973235c1599E271a

    recipient = "0x9251fd3D79522bB2243a58FFf1dB43E25A495aaB"

    # -------------------- Transfer --------------------
    deployer.transfer(recipient, deployer.balance() * 99 / 100)    # Tx: 0x751a3fcde57f5f2b222e67385efbc3d7006fe22ed5e87b2e6dce3af5812d709d
    owner.transfer(recipient, owner.balance() * 99 / 100)          # Tx: 0x8da23e54d6b27c2a3f5cf6137ca87590b04f1140b923240e7cd16e063844bac1