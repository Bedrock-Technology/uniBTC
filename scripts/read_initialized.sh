#!/bin/bash
#
# Read the _initialized version (from OZ Initializable, storage slot 0)
# for all deployed uniBTC proxy contracts across chains.
#
# Requires: cast (from Foundry)
#
# Usage: ./scripts/read_initialized.sh
#

set -euo pipefail

# Define chains: "chain_name rpc_url proxy_address"
CHAINS=(
    "Ethereum|https://eth.llamarpc.com|0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568"
    "Arbitrum|https://arb1.arbitrum.io/rpc|0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"
    "Optimism|https://mainnet.optimism.io|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "BSC|https://bsc-dataseed.binance.org|0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"
    "Base|https://mainnet.base.org|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "Mantle|https://rpc.mantle.xyz|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "BOB|https://rpc.gobob.xyz|0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894"
    "Mode|https://mainnet.mode.network|0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"
    "Bitlayer|https://rpc.bitlayer.org|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "B2|https://rpc.bsquared.network|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "Merlin|https://rpc.merlinchain.io|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "Corn|https://rpc.corn.fun|0x93919784c523f39cacaa98ee0a9d96c3f32b593e"
    "Zeta|https://zetachain-evm.blockpi.network/v1/rpc/public|0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"
    "Bera|https://rpc.berachain.com|0xC3827A4BC8224ee2D116637023b124CED6db6e90"
    "Sonic|https://rpc.soniclabs.com|0xC3827A4BC8224ee2D116637023b124CED6db6e90"
    "Sei|https://evm-rpc.sei-apis.com|0xDfc7D2d003A053b2E0490531e9317A59962b511E"
    "Taiko|https://rpc.mainnet.taiko.xyz|0x93919784c523f39cacaa98ee0a9d96c3f32b593e"
    "IoTeX|https://babel-api.mainnet.iotex.io|0x93919784c523f39cacaa98ee0a9d96c3f32b593e"
    "XLayer|https://rpc.xlayer.tech|0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"
    "Rootstock|https://public-node.rsk.co|0xd3C8Da379d71A33BFEe8875F87AC2748beb1D58d"
    "Hemi|https://rpc.hemi.network/rpc|0xF9775085d726E782E83585033B58606f7731AB18"
    "HyperEVM|https://rpc.hyperliquid.xyz/evm|0xF9775085d726E782E83585033B58606f7731AB18"
    "Ink|https://rpc-gel.inkonchain.com|0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"
    "DuckChain|https://rpc.duckchain.com|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "Unichain|https://mainnet.unichain.org|0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"
    "Taker|https://rpc-mainnet.taker.xyz|0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"
    "TAC|https://turin.rpc.tac.build|0xF9775085d726E782E83585033B58606f7731AB18"
)

printf "%-15s %-44s %s\n" "Chain" "Proxy Address" "Initialized Version"
printf "%-15s %-44s %s\n" "---------------" "--------------------------------------------" "-------------------"

for entry in "${CHAINS[@]}"; do
    IFS='|' read -r chain rpc address <<< "$entry"

    # Read storage slot 0: _initialized (uint8) is the lowest byte
    raw=$(cast storage "$address" 0 --rpc-url "$rpc" 2>/dev/null || echo "ERROR")

    if [[ "$raw" == "ERROR" ]]; then
        version="RPC_ERROR"
    else
        # Convert hex to decimal — the lowest byte is _initialized
        version=$(printf "%d" "$raw" 2>/dev/null || echo "PARSE_ERROR")
    fi

    printf "%-15s %-44s %s\n" "$chain" "$address" "$version"
done
