// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {SymbioticProxy} from "../src/SymbioticProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct RewardDistribution {
    uint256 amount;
    uint48 timestamp;
}

interface IDefaultStakerRewardsDistribute {
    function distributeRewards(address network, address token, uint256 amount, bytes calldata data) external;

    function claimable(address token, address account, bytes calldata data) external view returns (uint256 amount);

    function rewardsLength(address token, address network) external view returns (uint256);

    function lastUnclaimedReward(address account, address token, address network) external view returns (uint256);

    function rewards(address token, address network, uint256 index) external view returns (RewardDistribution memory);
}

interface IVaultExtended {
    function grantRole(bytes32 role, address account) external;
    function allowTarget(address[] memory _targets) external;
}

interface ISymbioticVaultExtended {
    function currentEpoch() external view returns (uint48);
    function activeStakeAt(uint48 timestamp, bytes calldata hint) external view returns (uint256);
    function activeSharesAt(uint48 timestamp, bytes calldata hint) external view returns (uint256);
    function activeSharesOfAt(address account, uint48 timestamp, bytes memory hint) external view returns (uint256);
}

contract SymbioticProxyForkTest is Test {
    // ============ Mainnet addresses ============
    address constant VAULT_ADDR = 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230;
    address constant VAULT_ADMIN = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
    address constant UNIBTC = 0x004E9C3EF86bc1ca1f0bB5C7662861Ee93350568;
    address constant SYMBIOTIC_VAULT_ADDR = 0x9ee1881Cc42478F3d0Cf9b76A0135ece398AF1F7;
    address constant DEFAULT_STAKER_REWARDS = 0x51329193eB24924CE48E8c5d7588Dd6187392A83;
    address constant PROXY_ADMIN = 0xac07f2721EcD955c4370e7388922fA547E922A4f;
    address constant REWARD_RECIPIENT = 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant PRINCIPLE_RECIPIENT = 0xB8b0aEd0a1Ce913183665B71bD9653fe378f2230;
    address constant DISTRIBUTOR = 0x09A3976d8D63728d20DCDFEe1e531C206Ba91225;
    address constant NETWORK = 0x98e52Ea7578F2088c152E81b17A9a459bF089f2a;
    address constant SYMBIOTIC_PORXY = 0x581d1860AeC248BB59E8f8345C70dA71dFDeA31D;

    bytes32 constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    SymbioticProxy public proxy;

    function _printRewardsInfo() internal view {
        uint256 len = IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS).rewardsLength(USDC, NETWORK);
        console.log("[Rewards] rewardsLength:", len);
        if (len > 0) {
            RewardDistribution memory rd =
                IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS).rewards(USDC, NETWORK, len - 1);
            console.log("[Rewards]   last index:", len - 1);
            console.log("[Rewards]   last amount:", rd.amount);
            console.log("[Rewards]   last timestamp:", uint256(rd.timestamp));

            uint256 activeSharesVault =
                ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).activeSharesOfAt(VAULT_ADDR, rd.timestamp, new bytes(0));
            console.log("[SymbioticVault] activeSharesOfAt at timestamp:", activeSharesVault);
        }
    }

    /// forge test test/SymbioticProxy.t.sol --match-test testForkFlow --fork-url $RPC_ETH_MAINNET -vvvv
    function testForkFlow() public {
        // ============================================================
        // Step 0: Setup & deploy SymbioticProxy
        // ============================================================

        // proxy = new SymbioticProxy(SYMBIOTIC_VAULT_ADDR, DEFAULT_STAKER_REWARDS, VAULT_ADDR, UNIBTC, PROXY_ADMIN);
        proxy = SymbioticProxy(SYMBIOTIC_PORXY);
        // Allow Vault to execute on symbioticVault, defaultStakerRewards, and uniBTC
        // address[] memory targets = new address[](3);
        // targets[0] = SYMBIOTIC_VAULT_ADDR;
        // targets[1] = DEFAULT_STAKER_REWARDS;
        // targets[2] = UNIBTC;
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).allowTarget(targets);
        // Grant OPERATOR_ROLE on Vault to the proxy (needed for execute)
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).grantRole(OPERATOR_ROLE, address(proxy));
        // Fund vault with uniBTC for deposit
        deal(UNIBTC, VAULT_ADDR, 100e8); // 1 uniBTC (8 decimals)

        // ============================================================
        // Step 1: Deposit via SymbioticProxy
        // ============================================================
        vm.prank(PROXY_ADMIN);
        (uint256 depositedAmount, uint256 mintedShares) = proxy.deposit(100e8);
        console.log("[Deposit] depositedAmount:", depositedAmount);
        console.log("[Deposit] mintedShares:", mintedShares);

        // ============================================================
        // Step 2: Warp 1 week + distribute rewards
        // ============================================================
        vm.warp(block.timestamp + 7 days);

        // Transfer 10000 USDC to DISTRIBUTOR and approve DefaultStakerRewards
        deal(USDC, DISTRIBUTOR, 10000 * 1e8);
        vm.prank(DISTRIBUTOR);
        IERC20(USDC).approve(DEFAULT_STAKER_REWARDS, 10000 * 1e8);

        // Encode distributeRewards data: (uint48 amount, uint256 timestamp, bytes, bytes)
        uint48 rewardU48 = 10000 * 1e8;
        uint256 blocktime = block.timestamp;

        // Print activeStakeAt and activeSharesAt from symbiotic vault
        uint256 activeStake =
            ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).activeStakeAt(uint48(blocktime), new bytes(0));
        uint256 activeShares =
            ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).activeSharesAt(uint48(blocktime), new bytes(0));
        console.log("[SymbioticVault] activeStakeAt:", activeStake);
        console.log("[SymbioticVault] activeSharesAt:", activeShares);

        // timestamp must be strictly before current Time.timestamp()
        bytes memory distributeData = abi.encode(uint48(blocktime - 1), 0, new bytes(0), new bytes(0));

        // DISTRIBUTOR calls distributeRewards on DefaultStakerRewards
        vm.prank(DISTRIBUTOR);
        IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS)
            .distributeRewards(NETWORK, USDC, rewardU48, distributeData);

        console.log("[Distribute] rewards distributed by distributor");
        _printRewardsInfo();

        vm.warp(block.timestamp + 7 days);
        // Transfer 10000 USDC to DISTRIBUTOR and approve DefaultStakerRewards
        deal(USDC, DISTRIBUTOR, 10000 * 1e8);
        vm.prank(DISTRIBUTOR);
        IERC20(USDC).approve(DEFAULT_STAKER_REWARDS, 10000 * 1e8);

        // Encode distributeRewards data: (uint48 amount, uint256 timestamp, bytes, bytes)
        rewardU48 = 10000 * 1e8;
        blocktime = block.timestamp;
        uint256 activeSharesVault =
            ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).activeSharesOfAt(VAULT_ADDR, uint48(blocktime), new bytes(0));
        console.log("[SymbioticVault] activeSharesAt:", activeSharesVault);
        distributeData = abi.encode(uint48(blocktime - 1), 0, new bytes(0), new bytes(0));

        // DISTRIBUTOR calls distributeRewards on DefaultStakerRewards
        vm.prank(DISTRIBUTOR);
        IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS)
            .distributeRewards(NETWORK, USDC, rewardU48, distributeData);
        console.log("[Distribute] rewards distributed by distributor 2");
        _printRewardsInfo();
        // ============================================================
        // Step 3: Claim rewards & log balance change
        // ============================================================
        uint256 maxRewards = 1000;
        bytes memory claimableData = abi.encode(NETWORK, maxRewards);

        uint256 lur =
            IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS).lastUnclaimedReward(VAULT_ADDR, USDC, NETWORK);
        console.log("lastUnclaimedReward for VAULT:", lur);

        uint256 claimableAmount =
            IDefaultStakerRewardsDistribute(DEFAULT_STAKER_REWARDS).claimable(USDC, VAULT_ADDR, claimableData);
        console.log("[Claim] claimable USDC for rewardVault:", claimableAmount);

        uint256 balanceBefore = IERC20(USDC).balanceOf(REWARD_RECIPIENT);
        console.log("[Claim] USDC balance of rewardRecipient before:", balanceBefore);

        vm.prank(PROXY_ADMIN);
        proxy.claimRewards(NETWORK, USDC);

        uint256 balanceAfter = IERC20(USDC).balanceOf(REWARD_RECIPIENT);
        console.log("[Claim] USDC balance of rewardRecipient after:", balanceAfter);
        console.log("[Claim] USDC claimed:", balanceAfter - balanceBefore);

        assertGt(balanceAfter, balanceBefore, "Should have claimed rewards");
    }

    /// forge test test/SymbioticProxy.t.sol --match-test testForkRedeem --fork-url $RPC_ETH_MAINNET -vvvv
    function testForkRedeem() public {
        // ============================================================
        // Step 0: Setup & deploy SymbioticProxy
        // ============================================================

        // proxy = new SymbioticProxy(SYMBIOTIC_VAULT_ADDR, DEFAULT_STAKER_REWARDS, VAULT_ADDR, UNIBTC, PROXY_ADMIN);
        proxy = SymbioticProxy(SYMBIOTIC_PORXY);

        // Allow Vault to execute on symbioticVault, defaultStakerRewards, and uniBTC
        // address[] memory targets = new address[](3);
        // targets[0] = SYMBIOTIC_VAULT_ADDR;
        // targets[1] = DEFAULT_STAKER_REWARDS;
        // targets[2] = UNIBTC;
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).allowTarget(targets);

        // // Grant OPERATOR_ROLE on Vault to the proxy (needed for execute)
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).grantRole(OPERATOR_ROLE, address(proxy));

        // Fund vault with uniBTC for deposit
        deal(UNIBTC, VAULT_ADDR, 100e8); // 100 uniBTC (8 decimals)

        // ============================================================
        // Step 1: Deposit via SymbioticProxy
        // ============================================================
        vm.prank(PROXY_ADMIN);
        (uint256 depositedAmount, uint256 mintedShares) = proxy.deposit(100e8);
        console.log("[Deposit] depositedAmount:", depositedAmount);
        console.log("[Deposit] mintedShares:", mintedShares);

        // ============================================================
        // Step 2: Record currentEpoch, withdraw 50 uniBTC
        // ============================================================
        uint48 epochBefore = ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).currentEpoch();
        console.log("[Before Withdraw] currentEpoch from SYMBIOTIC_VAULT_ADDR:", epochBefore);

        vm.prank(PROXY_ADMIN);
        (uint256 burnedShares, uint256 withdrawMintedShares) = proxy.withdraw(50e8);
        console.log("[Withdraw] burnedShares:", burnedShares);
        console.log("[Withdraw] mintedShares:", withdrawMintedShares);

        // ============================================================
        // Step 3: Warp 14 days, print currentEpoch, claim
        // ============================================================
        vm.warp(block.timestamp + 14 days);

        uint48 epochAfter = ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).currentEpoch();
        console.log("[After Warp] currentEpoch from SYMBIOTIC_VAULT_ADDR:", epochAfter);

        uint48 claimEpoch = epochBefore + 1;
        console.log("[Claim] claiming epoch:", claimEpoch);

        vm.prank(PROXY_ADMIN);
        uint256 claimedAmount = proxy.claim(uint256(claimEpoch));
        console.log("[Claim] claimed amount:", claimedAmount);

        assertGt(claimedAmount, 0, "Should have claimed withdrawn uniBTC");
    }

    /// forge test test/SymbioticProxy.t.sol --match-test testForkRedeemShares --fork-url $RPC_ETH_MAINNET -vvvv
    function testForkRedeemShares() public {
        // ============================================================
        // Step 0: Setup & deploy SymbioticProxy
        // ============================================================

        // proxy = new SymbioticProxy(SYMBIOTIC_VAULT_ADDR, DEFAULT_STAKER_REWARDS, VAULT_ADDR, UNIBTC, PROXY_ADMIN);
        proxy = SymbioticProxy(SYMBIOTIC_PORXY);

        // Allow Vault to execute on symbioticVault, defaultStakerRewards, and uniBTC
        // address[] memory targets = new address[](3);
        // targets[0] = SYMBIOTIC_VAULT_ADDR;
        // targets[1] = DEFAULT_STAKER_REWARDS;
        // targets[2] = UNIBTC;
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).allowTarget(targets);

        // // Grant OPERATOR_ROLE on Vault to the proxy (needed for execute)
        // vm.prank(VAULT_ADMIN);
        // IVaultExtended(VAULT_ADDR).grantRole(OPERATOR_ROLE, address(proxy));

        // Fund vault with uniBTC for deposit
        deal(UNIBTC, VAULT_ADDR, 100e8); // 100 uniBTC (8 decimals)

        // ============================================================
        // Step 1: Deposit via SymbioticProxy
        // ============================================================
        vm.prank(PROXY_ADMIN);
        (uint256 depositedAmount, uint256 mintedShares) = proxy.deposit(100e8);
        console.log("[Deposit] depositedAmount:", depositedAmount);
        console.log("[Deposit] mintedShares:", mintedShares);

        // ============================================================
        // Step 2: Record currentEpoch, redeem 100e8 shares
        // ============================================================
        uint48 epochBefore = ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).currentEpoch();
        console.log("[Before Redeem] currentEpoch from SYMBIOTIC_VAULT_ADDR:", epochBefore);

        vm.prank(PROXY_ADMIN);
        (uint256 withdrawnAssets, uint256 redeemMintedShares) = proxy.redeem(100e8);
        console.log("[Redeem] withdrawnAssets:", withdrawnAssets);
        console.log("[Redeem] mintedShares:", redeemMintedShares);

        // ============================================================
        // Step 3: Warp 14 days, print currentEpoch, claim
        // ============================================================
        vm.warp(block.timestamp + 14 days);

        uint48 epochAfter = ISymbioticVaultExtended(SYMBIOTIC_VAULT_ADDR).currentEpoch();
        console.log("[After Warp] currentEpoch from SYMBIOTIC_VAULT_ADDR:", epochAfter);

        uint48 claimEpoch = epochBefore + 1;
        console.log("[Claim] claiming epoch:", claimEpoch);

        vm.prank(PROXY_ADMIN);
        uint256 claimedAmount = proxy.claim(uint256(claimEpoch));
        console.log("[Claim] claimed amount:", claimedAmount);

        assertGt(claimedAmount, 0, "Should have claimed redeemed uniBTC");
    }
}
