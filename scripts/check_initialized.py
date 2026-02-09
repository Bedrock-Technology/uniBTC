#!/usr/bin/env python3
"""
Check the _initialized version (on-chain storage) vs verified source code
reinitializer(N) for all deployed uniBTC proxy contracts across chains.

Source code is fetched from each chain's native block explorer API.
No Sourcify fallback (Sourcify verified source often doesn't match on-chain).

Requires: cast (Foundry), curl, python3
Usage: python3 scripts/check_initialized.py
"""

import subprocess
import json
import re
import sys
import os
import time
from typing import Optional, List, Tuple, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed

# ────────────────────────────────────────────────────────────────────────────────
# Chain configs: (name, chain_id, rpc_url, proxy_address, explorer_apis)
#
# explorer_apis: list of (api_url, api_type) tuples, tried in order.
#   api_type:
#     "etherscan"  - Etherscan-compatible (Blockscout, btrscan, etc.)
#     "routescan"  - Routescan Etherscan-compatible wrapper
#     "etherscan_v2" - Etherscan V2 unified API (needs ETHERSCAN_API_KEY)
# ────────────────────────────────────────────────────────────────────────────────

CHAINS = [
    # ── Blockscout self-hosted / independent explorers ──
    ("BOB",       60808,    "https://rpc.gobob.xyz",
     "0x236f8c0a61dA474dB21B693fB2ea7AAB0c803894",
     [("https://explorer.gobob.xyz/api", "etherscan")]),

    ("Mode",      34443,    "https://mainnet.mode.network",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a",
     [("https://explorer.mode.network/api", "etherscan")]),

    ("Zeta",      7000,     "https://zetachain-evm.blockpi.network/v1/rpc/public",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a",
     [("https://zetachain.blockscout.com/api", "etherscan")]),

    ("Rootstock", 30,       "https://public-node.rsk.co",
     "0xd3C8Da379d71A33BFEe8875F87AC2748beb1D58d",
     [("https://rootstock.blockscout.com/api", "etherscan")]),

    ("Hemi",      43111,    "https://rpc.hemi.network/rpc",
     "0xF9775085d726E782E83585033B58606f7731AB18",
     [("https://explorer.hemi.xyz/api", "etherscan")]),

    ("Ink",       57073,    "https://rpc-gel.inkonchain.com",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d",
     [("https://explorer.inkonchain.com/api", "etherscan")]),

    ("Unichain",  130,      "https://mainnet.unichain.org",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d",
     [("https://unichain.blockscout.com/api", "etherscan")]),

    ("IoTeX",     4689,     "https://babel-api.mainnet.iotex.io",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e",
     [("https://index.iotexscan.io/api", "etherscan")]),

    # ── Blockscout cloud instances (free, no API key) ──
    ("Ethereum",  1,        "https://eth.llamarpc.com",
     "0x004e9c3ef86bc1ca1f0bb5c7662861ee93350568",
     [("https://eth.blockscout.com/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("Arbitrum",  42161,    "https://arb1.arbitrum.io/rpc",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a",
     [("https://arbitrum.blockscout.com/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("Optimism",  10,       "https://mainnet.optimism.io",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     [("https://optimism.blockscout.com/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("Base",      8453,     "https://mainnet.base.org",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     [("https://base.blockscout.com/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("Mantle",    5000,     "https://rpc.mantle.xyz",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     [("https://explorer.mantle.xyz/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    # ── Chains with native explorer (non-Blockscout) ──
    ("Bitlayer",  200901,   "https://rpc.bitlayer.org",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     [("https://api.btrscan.com/scan/api", "etherscan")]),

    ("Bera",      80094,    "https://rpc.berachain.com",
     "0xC3827A4BC8224ee2D116637023b124CED6db6e90",
     [("https://api.routescan.io/v2/network/mainnet/evm/80094/etherscan/api", "routescan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("Corn",      21000000, "https://rpc.corn.fun",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e",
     [("https://maizenet-explorer.usecorn.com/api", "etherscan")]),

    ("TAC",       2390,     "https://turin.rpc.tac.build",
     "0xF9775085d726E782E83585033B58606f7731AB18",
     [("https://explorer.tac.build/api", "etherscan")]),

    # ── Etherscan V2 only (sonicscan, taikoscan, hyperevmscan) ──
    ("BSC",       56,       "https://bsc-dataseed.binance.org",
     "0x6B2a01A5f79dEb4c2f3c0eDa7b01DF456FbD726a",
     [("etherscan_v2", "etherscan_v2")]),

    ("Sonic",     146,      "https://rpc.soniclabs.com",
     "0xC3827A4BC8224ee2D116637023b124CED6db6e90",
     [("etherscan_v2", "etherscan_v2")]),

    ("Taiko",     167000,   "https://rpc.mainnet.taiko.xyz",
     "0x93919784c523f39cacaa98ee0a9d96c3f32b593e",
     [("https://blockscoutapi.mainnet.taiko.xyz/api", "etherscan"),
      ("etherscan_v2", "etherscan_v2")]),

    ("HyperEVM",  999,      "https://rpc.hyperliquid.xyz/evm",
     "0xF9775085d726E782E83585033B58606f7731AB18",
     [("etherscan_v2", "etherscan_v2")]),

    # ── Hard to reach: rate limited / Cloudflare / no API ──
    ("Merlin",    4200,     "https://rpc.merlinchain.io",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     [("https://scan.merlinchain.io/api", "etherscan")]),

    ("B2",        223,      "https://rpc.bsquared.network",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     []),  # explorer.bsquared.network has no working API

    ("Sei",       1329,     "https://evm-rpc.sei-apis.com",
     "0xDfc7D2d003A053b2E0490531e9317A59962b511E",
     []),  # seistream.app / seitrace.com have no Etherscan-compatible API

    ("XLayer",    196,      "https://rpc.xlayer.tech",
     "0xd3c8dA379d71a33BfEE8875F87Ac2748bEB1d58d",
     []),  # oklink.com requires API key with different format

    ("Taker",     2524,     "https://rpc-mainnet.taker.xyz",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     []),  # explorer.taker.xyz behind Cloudflare challenge

    ("DuckChain", 5545,     "https://rpc.duckchain.com",
     "0x93919784C523f39CACaa98Ee0a9d96c3F32b593e",
     []),  # scan.duckchain.io times out
]

ETHERSCAN_API_KEY = os.environ.get("ETHERSCAN_API_KEY", "")


# ────────────────────────────────────────────────────────────────────────────────
# Utilities
# ────────────────────────────────────────────────────────────────────────────────

def run_cmd(args, timeout=15):
    # type: (List[str], int) -> Optional[str]
    """Run a command and return stdout, or None on error."""
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


def curl_json(url, timeout=15):
    # type: (str, int) -> Optional[Dict[str, Any]]
    """Fetch a URL and return parsed JSON, or None."""
    body = run_cmd(
        ["curl", "-sL", "--connect-timeout", "8", "--max-time", str(timeout), url],
        timeout=timeout + 5
    )
    if not body:
        return None
    body = body.strip()
    if body.startswith("{") or body.startswith("["):
        try:
            return json.loads(body)
        except json.JSONDecodeError:
            pass
    return None


def get_initialized_version(proxy, rpc):
    # type: (str, str) -> str
    """Read _initialized (uint8) from storage slot 0."""
    raw = run_cmd(["cast", "storage", proxy, "0", "--rpc-url", rpc])
    if raw is None:
        return "RPC_ERR"
    try:
        return str(int(raw, 16))
    except ValueError:
        return "PARSE_ERR"


def get_implementation(proxy, rpc):
    # type: (str, str) -> Optional[str]
    """Get implementation address behind a proxy using EIP-1967 slot."""
    return run_cmd(["cast", "implementation", proxy, "--rpc-url", rpc])


# ────────────────────────────────────────────────────────────────────────────────
# Source fetching: multiple strategies per chain
# ────────────────────────────────────────────────────────────────────────────────

def _parse_etherscan_source(data):
    # type: (Optional[Dict[str, Any]]) -> Optional[str]
    """Parse source code from an Etherscan/Blockscout API response."""
    if not data:
        return None

    # Handle error responses
    if "error" in data:
        return None

    result = data.get("result")
    if not isinstance(result, list) or len(result) == 0:
        return None

    item = result[0]
    source = item.get("SourceCode", "")
    if not source:
        # Try AdditionalSources (Blockscout format)
        additional = item.get("AdditionalSources", [])
        if additional:
            for asrc in additional:
                content = asrc.get("SourceCode", "")
                if "function initialize" in content and ("reinitializer" in content or "initializer" in content):
                    return content
        return None

    # Handle double-wrapped JSON (Etherscan multi-file: {{...}})
    if source.startswith("{{"):
        source = source[1:-1]

    # Handle JSON source (multi-file verified contracts)
    if source.startswith("{"):
        try:
            sources_json = json.loads(source)
            srcs = sources_json.get("sources", sources_json)
            # First pass: find the uniBTC contract file specifically
            for fname, fdata in srcs.items():
                content = fdata if isinstance(fdata, str) else fdata.get("content", "")
                if ("uniBTC" in fname or "UniBTC" in fname) and "reinitializer" in content:
                    return content
            # Second pass: any file with initialize + reinitializer
            for fname, fdata in srcs.items():
                content = fdata if isinstance(fdata, str) else fdata.get("content", "")
                if "function initialize" in content and "reinitializer" in content:
                    return content
            # Third pass: any file with initialize + initializer
            for fname, fdata in srcs.items():
                content = fdata if isinstance(fdata, str) else fdata.get("content", "")
                if "function initialize" in content and "initializer" in content:
                    return content
            # Fallback: concatenate all sources
            all_src = "\n".join(
                (fdata if isinstance(fdata, str) else fdata.get("content", ""))
                for fdata in srcs.values()
            )
            if "reinitializer" in all_src or "initializer" in all_src:
                return all_src
        except (json.JSONDecodeError, AttributeError):
            pass

    # Plain/flattened source
    if "function initialize" in source or "reinitializer" in source or "initializer" in source:
        return source

    # Also check AdditionalSources (Blockscout may put them separately)
    additional = item.get("AdditionalSources", [])
    if additional:
        for asrc in additional:
            content = asrc.get("SourceCode", "")
            if "function initialize" in content and ("reinitializer" in content or "initializer" in content):
                return content

    return None


def curl_json_retry(url, retries=2, delay=3, timeout=15):
    # type: (str, int, int, int) -> Optional[Dict[str, Any]]
    """Fetch JSON with retry for rate-limited APIs."""
    for attempt in range(retries + 1):
        data = curl_json(url, timeout=timeout)
        if data is not None:
            # Check for rate-limit error
            if isinstance(data, dict) and "error" in data and "too many" in str(data.get("error", "")).lower():
                if attempt < retries:
                    time.sleep(delay * (attempt + 1))
                    continue
            return data
        if attempt < retries:
            time.sleep(delay)
    return None


def fetch_from_etherscan_api(api_url, address):
    # type: (str, str) -> Optional[str]
    """Fetch source code from an Etherscan-compatible API endpoint."""
    url = "{0}?module=contract&action=getsourcecode&address={1}".format(api_url, address)
    data = curl_json_retry(url)
    return _parse_etherscan_source(data)


def fetch_from_etherscan_v2(chain_id, address):
    # type: (int, str) -> Optional[str]
    """Fetch from Etherscan V2 unified API (requires API key)."""
    if not ETHERSCAN_API_KEY:
        return None
    url = ("https://api.etherscan.io/v2/api?chainid={0}"
           "&module=contract&action=getsourcecode&address={1}"
           "&apikey={2}").format(chain_id, address, ETHERSCAN_API_KEY)
    data = curl_json(url)
    return _parse_etherscan_source(data)


def fetch_source(chain_name, chain_id, explorer_apis, address):
    # type: (str, int, List[Tuple[str, str]], str) -> Tuple[Optional[str], str]
    """Try all source fetching methods in order of preference.
    Returns (source_code, method_name).
    """
    for api_url, api_type in explorer_apis:
        if api_type in ("etherscan", "routescan"):
            src = fetch_from_etherscan_api(api_url, address)
            if src:
                return src, api_type
        elif api_type == "etherscan_v2":
            src = fetch_from_etherscan_v2(chain_id, address)
            if src:
                return src, "etherscan_v2"

    return None, "none"


# ────────────────────────────────────────────────────────────────────────────────
# Source code parsing
# ────────────────────────────────────────────────────────────────────────────────

def extract_version_from_source(source):
    # type: (str) -> str
    """Extract the reinitializer(N) or initializer version from uniBTC source code.
    Ignores the Initializable library's own modifier definition.
    """
    # Look specifically for: function initialize(...) ... reinitializer(N)
    m = re.search(
        r'function\s+initialize\s*\([^)]*\)\s*[^{]*?\breinitializer\((\d+)\)',
        source, re.DOTALL
    )
    if m:
        return m.group(1)

    # Check for plain initializer modifier on initialize function
    m = re.search(
        r'function\s+initialize\s*\([^)]*\)\s*[^{]*?\binitializer\b',
        source, re.DOTALL
    )
    if m:
        # Make sure it's not reinitializer
        snippet = source[max(0, m.start() - 5):m.end()]
        if "reinitializer" not in snippet:
            return "1"

    return "N/A"


# ────────────────────────────────────────────────────────────────────────────────
# Main check per chain
# ────────────────────────────────────────────────────────────────────────────────

def check_chain(chain_info):
    # type: (Tuple) -> Dict[str, Any]
    """Check a single chain. Returns a result dict."""
    name, chain_id, rpc, proxy, explorer_apis = chain_info

    # 1. Read _initialized from storage
    storage_ver = get_initialized_version(proxy, rpc)

    # 2. Get implementation address
    impl = get_implementation(proxy, rpc)

    # 3. Fetch verified source code (try implementation first, then proxy)
    source_ver = "N/A"
    src_from = "none"

    if impl:
        source, src_from = fetch_source(name, chain_id, explorer_apis, impl)
        if source:
            source_ver = extract_version_from_source(source)

    # If not found via impl, try proxy address
    if source_ver == "N/A":
        source, src_from2 = fetch_source(name, chain_id, explorer_apis, proxy)
        if source:
            source_ver = extract_version_from_source(source)
            if source_ver != "N/A":
                src_from = src_from2

    # 4. Compare
    if storage_ver in ("RPC_ERR", "PARSE_ERR") or source_ver == "N/A":
        match = "warn"
    elif storage_ver == source_ver:
        match = "ok"
    else:
        match = "MISMATCH"

    return {
        "name": name,
        "proxy": proxy,
        "impl": impl or "N/A",
        "storage_ver": storage_ver,
        "source_ver": source_ver,
        "src_from": src_from,
        "match": match,
    }


def main():
    if ETHERSCAN_API_KEY:
        print("Etherscan API key: configured ✓")
    else:
        print("Etherscan API key: NOT SET")
        print("  → Set ETHERSCAN_API_KEY env to enable Etherscan V2 for BSC/Sonic/Taiko/HyperEVM\n")

    print("Checking _initialized version vs verified source for {0} uniBTC deployments...\n".format(len(CHAINS)))

    results = []  # type: List[Dict[str, Any]]

    with ThreadPoolExecutor(max_workers=5) as executor:
        future_to_chain = {executor.submit(check_chain, c): c for c in CHAINS}
        for future in as_completed(future_to_chain):
            chain = future_to_chain[future]
            try:
                result = future.result()
                results.append(result)
                icon = {"ok": "✅", "MISMATCH": "❌", "warn": "⚠️ "}[result["match"]]
                sys.stderr.write("  {0} {1:<12s} storage={2:<4s} source={3:<4s} via={4:<14s}\n".format(
                    icon, result["name"], result["storage_ver"], result["source_ver"], result["src_from"]))
            except Exception as e:
                sys.stderr.write("  💥 {0:<12s} {1}\n".format(chain[0], e))

    # Sort by original order
    chain_order = {c[0]: i for i, c in enumerate(CHAINS)}
    results.sort(key=lambda r: chain_order.get(r["name"], 999))

    # Print table
    print()
    print("{0:<12} {1:<44} {2:>8} {3:>8} {4:<14} {5}".format(
        "Chain", "Implementation", "Storage", "Source", "Via", "Match"))
    print("{0} {1} {2} {3} {4} {5}".format(
        "-" * 12, "-" * 44, "-" * 8, "-" * 8, "-" * 14, "-" * 5))

    for r in results:
        icon = {"ok": "✅", "MISMATCH": "❌", "warn": "⚠️ "}[r["match"]]
        print("{0:<12} {1:<44} {2:>8} {3:>8} {4:<14} {5}".format(
            r["name"], r["impl"],
            r["storage_ver"], r["source_ver"], r["src_from"], icon))

    # Summary
    mismatches = [r for r in results if r["match"] == "MISMATCH"]
    warnings = [r for r in results if r["match"] == "warn"]
    ok = [r for r in results if r["match"] == "ok"]

    print("\n" + "=" * 100)
    print("SUMMARY: {0} OK, {1} MISMATCH, {2} WARNINGS (total {3} chains)\n".format(
        len(ok), len(mismatches), len(warnings), len(results)))

    if mismatches:
        print("❌ MISMATCHES (on-chain _initialized != verified source reinitializer):")
        for r in mismatches:
            print("   {0:<12} storage={1}, source={2}  impl={3}  via={4}".format(
                r["name"], r["storage_ver"], r["source_ver"], r["impl"], r["src_from"]))

    if warnings:
        print("\n⚠️  WARNINGS (could not fully verify):")
        for r in warnings:
            reasons = []
            if r["storage_ver"] in ("RPC_ERR", "PARSE_ERR"):
                reasons.append("RPC failed")
            if r["source_ver"] == "N/A":
                reasons.append("source not found")
            print("   {0:<12} storage={1}, source={2}  ({3})".format(
                r["name"], r["storage_ver"], r["source_ver"], ", ".join(reasons)))


if __name__ == "__main__":
    main()
