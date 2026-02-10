#!/usr/bin/env python3
"""
Check the _initialized version (on-chain storage) vs the reinitializer(N)
compiled into the implementation bytecode for all deployed uniBTC proxy
contracts across chains.

The reinitializer version is extracted by disassembling the implementation
bytecode and looking for the OZ Initializable pattern:
    PUSH1 0x00 / SLOAD / PUSH1 <N>

No block-explorer API or source code is needed.

Requires: cast (Foundry), python3
Usage: python3 scripts/check_initialized.py
"""

import subprocess
import re
import sys
from typing import Optional
from concurrent.futures import ThreadPoolExecutor, as_completed

CHAINS = [
    ("BOB",       60808,    "https://rpc.gobob.xyz",
     "0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894"),
    ("Mode",      34443,    "https://mainnet.mode.network",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"),
    ("Zeta",      7000,     "https://zetachain-evm.blockpi.network/v1/rpc/public",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"),
    ("Rootstock", 30,       "https://public-node.rsk.co",
     "0xd3C8Da379d71A33BFEe8875F87AC2748beb1D58d"),
    ("Hemi",      43111,    "https://rpc.hemi.network/rpc",
     "0xF9775085d726E782E83585033B58606f7731AB18"),
    ("Ink",       57073,    "https://rpc-gel.inkonchain.com",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"),
    ("Unichain",  130,      "https://mainnet.unichain.org",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"),
    ("IoTeX",     4689,     "https://babel-api.mainnet.iotex.io",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e"),
    ("Ethereum",  1,        "https://eth.llamarpc.com",
     "0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568"),
    ("Arbitrum",  42161,    "https://arb1.arbitrum.io/rpc",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"),
    ("Optimism",  10,       "https://mainnet.optimism.io",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("Base",      8453,     "https://mainnet.base.org",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("Mantle",    5000,     "https://rpc.mantle.xyz",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("Bitlayer",  200901,   "https://rpc.bitlayer.org",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("Bera",      80094,    "https://rpc.berachain.com",
     "0xC3827A4BC8224ee2D116637023b124CED6db6e90"),
    ("Corn",      21000000, "https://mainnet.corn-rpc.com",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e"),
    ("TAC",       2390,     "https://rpc.tac.build",
     "0xF9775085d726E782E83585033B58606f7731AB18"),
    ("BSC",       56,       "https://bsc-dataseed.binance.org",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a"),
    ("Sonic",     146,      "https://rpc.soniclabs.com",
     "0xC3827A4BC8224ee2D116637023b124CED6db6e90"),
    ("Taiko",     167000,   "https://rpc.mainnet.taiko.xyz",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e"),
    ("HyperEVM",  999,      "https://rpc.hyperliquid.xyz/evm",
     "0xF9775085d726E782E83585033B58606f7731AB18"),
    ("Merlin",    4200,     "https://rpc.merlinchain.io",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("B2",        223,      "https://rpc.bsquared.network",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("Sei",       1329,     "https://evm-rpc.sei-apis.com",
     "0xDfc7D2d003A053b2E0490531e9317A59962b511E"),
    ("XLayer",    196,      "https://xlayerrpc.okx.com",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d"),
    ("Taker",     2524,     "https://rpc-mainnet.taker.xyz",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
    ("DuckChain", 5545,     "https://rpc.duckchain.io",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e"),
]


def run_cmd(args, timeout=15):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


# EIP-1967 implementation slot
IMPL_SLOT = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"


def get_initialized_version(proxy, rpc):
    """Read slot 0 (_initialized) at the latest block."""
    raw = run_cmd(["cast", "storage", proxy, "0", "--rpc-url", rpc, "--block", "latest"])
    if raw is None:
        return "RPC_ERR"
    try:
        return str(int(raw, 16))
    except ValueError:
        return "PARSE_ERR"


def get_implementation(proxy, rpc):
    """Read the EIP-1967 implementation slot at the latest block."""
    raw = run_cmd(["cast", "storage", proxy, IMPL_SLOT, "--rpc-url", rpc, "--block", "latest"])
    if raw is None:
        return None
    try:
        addr = "0x" + raw[-40:]  # last 20 bytes = address
        if int(addr, 16) == 0:
            return None
        return addr
    except (ValueError, IndexError):
        return None


def extract_version_from_bytecode(address, rpc):
    """
    Extract reinitializer(N) by searching the raw bytecode hex for the
    OZ Initializable modifier's compiled opcode pattern:

        PUSH1 0x00   (6000)   ; storage slot of _initialized / _initializing
        SLOAD        (54)     ; load packed slot value
        PUSH1 <N>    (60NN)   ; version literal from reinitializer(N)
        SWAP1        (90)     ; reorder stack
        PUSH2 0x0100 (610100) ; 256 — to extract _initializing (byte 1)
        SWAP1        (90)     ;
        DIV          (04)     ; slot_val / 256 → _initializing
        PUSH1 0xFF   (60ff)   ; mask
        AND          (16)     ; & 0xFF
        ISZERO       (15)     ; !_initializing

    Full hex pattern: 600054 60<NN> 90 610100 90 04 60ff 16 15
    """
    bytecode = run_cmd(["cast", "code", address, "--rpc-url", rpc, "--block", "latest"], timeout=20)
    if not bytecode or bytecode == "0x":
        return "N/A"
    h = bytecode[2:] if bytecode.startswith("0x") else bytecode
    # Strict pattern: PUSH1 0x00 + SLOAD + PUSH1 <N> + SWAP1 + PUSH2 0x0100 + SWAP1 + DIV + PUSH1 0xFF + AND + ISZERO
    for m in re.finditer(r"60005460([0-9a-fA-F]{2})90610100900460ff1615", h):
        ver = int(m.group(1), 16)
        if 1 <= ver <= 255 and ver != 0xFF:
            return str(ver)
    return "N/A"


def check_chain(chain_info):
    name, chain_id, rpc, proxy = chain_info
    storage_ver = get_initialized_version(proxy, rpc)
    impl = get_implementation(proxy, rpc)
    disasm_ver = "N/A"
    if impl:
        disasm_ver = extract_version_from_bytecode(impl, rpc)

    if storage_ver in ("RPC_ERR", "PARSE_ERR") or disasm_ver == "N/A":
        match = "warn"
    elif storage_ver == disasm_ver:
        match = "ok"
    else:
        match = "MISMATCH"

    return {
        "name": name, "proxy": proxy, "impl": impl or "N/A",
        "storage_ver": storage_ver, "disasm_ver": disasm_ver, "match": match,
    }


def main():
    n = len(CHAINS)
    print(f"Checking _initialized vs bytecode reinitializer(N) for {n} chains ...\n")
    results = []
    with ThreadPoolExecutor(max_workers=5) as executor:
        future_to_chain = {executor.submit(check_chain, c): c for c in CHAINS}
        for future in as_completed(future_to_chain):
            chain = future_to_chain[future]
            try:
                r = future.result()
                results.append(r)
                icon = {"ok": "\u2705", "MISMATCH": "\u274c", "warn": "\u26a0\ufe0f "}[r["match"]]
                sys.stderr.write(f"  {icon} {r['name']:<12s} storage={r['storage_ver']:<4s} disasm={r['disasm_ver']:<4s}\n")
            except Exception as e:
                sys.stderr.write(f"  \U0001f4a5 {chain[0]:<12s} {e}\n")

    chain_order = {c[0]: i for i, c in enumerate(CHAINS)}
    results.sort(key=lambda r: chain_order.get(r["name"], 999))

    hdr = ("Chain", "Implementation", "Storage", "Disasm")
    print(f"{hdr[0]:<12} {hdr[1]:<44} {hdr[2]:>8} {hdr[3]:>8} Match")
    print(f"{'-'*12} {'-'*44} {'-'*8} {'-'*8} {'-'*5}")
    for r in results:
        icon = {"ok": "\u2705", "MISMATCH": "\u274c", "warn": "\u26a0\ufe0f "}[r["match"]]
        print(f"{r['name']:<12} {r['impl']:<44} {r['storage_ver']:>8} {r['disasm_ver']:>8} {icon}")

    mismatches = [r for r in results if r["match"] == "MISMATCH"]
    warnings = [r for r in results if r["match"] == "warn"]
    ok = [r for r in results if r["match"] == "ok"]
    sep = "=" * 80
    print(f"\n{sep}")
    print(f"SUMMARY: {len(ok)} OK, {len(mismatches)} MISMATCH, {len(warnings)} WARNINGS (total {len(results)} chains)\n")
    if mismatches:
        print("\u274c MISMATCHES (on-chain _initialized != bytecode reinitializer):")
        for r in mismatches:
            print(f"   {r['name']:<12} storage={r['storage_ver']}, disasm={r['disasm_ver']}  impl={r['impl']}")
    if warnings:
        print(f"\n\u26a0\ufe0f  WARNINGS (could not fully verify):")
        for r in warnings:
            reasons = []
            if r["storage_ver"] in ("RPC_ERR", "PARSE_ERR"):
                reasons.append("RPC failed")
            if r["disasm_ver"] == "N/A":
                reasons.append("disassembly failed")
            print(f"   {r['name']:<12} storage={r['storage_ver']}, disasm={r['disasm_ver']}  ({', '.join(reasons)})")


if __name__ == "__main__":
    main()
