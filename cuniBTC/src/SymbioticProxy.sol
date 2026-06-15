// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interface/IVault.sol";
import "../interface/ISymbioticVault.sol";
import "../interface/IDefaultStakerRewards.sol";

contract SymbioticProxy is Ownable, ReentrancyGuard {

	address public symbioticVault;
	address public defaultStakerRewards;
	address public vault;
	address public uniBTC;

	address public principleRecipient;
	address public rewardRecipient;
	address public rewardToken;

	constructor(address _symbioticVault, address _defaultStakerRewards, address _vault, address _uniBTC, address _admin, address _rewardToken) {
		require(_symbioticVault != address(0), "SymbioticProxy: invalid symbiotic vault");
		require(_defaultStakerRewards != address(0), "SymbioticProxy: invalid rewards");
		require(_vault != address(0), "SymbioticProxy: invalid vault");
		require(_uniBTC != address(0), "SymbioticProxy: invalid uniBTC");
		require(_admin != address(0), "SymbioticProxy: invalid admin");
		require(_rewardToken != address(0), "SymbioticProxy: invalid reward token");

		_transferOwnership(_admin);

		symbioticVault = _symbioticVault;
		defaultStakerRewards = _defaultStakerRewards;
		vault = _vault;
		uniBTC = _uniBTC;
		principleRecipient = _vault;
		rewardRecipient = _vault;
		rewardToken = _rewardToken;
	}

	function deposit(uint256 amount) external onlyOwner nonReentrant returns (uint256 depositedAmount, uint256 mintedShares) {
		require(amount > 0, "SymbioticProxy: invalid amount");

		bytes memory approveZeroData = abi.encodeWithSelector(IERC20.approve.selector, symbioticVault, 0);
		IVault(vault).execute(uniBTC, approveZeroData, 0);

		bytes memory approveData = abi.encodeWithSelector(IERC20.approve.selector, symbioticVault, amount);
		IVault(vault).execute(uniBTC, approveData, 0);

		bytes memory depositData = abi.encodeWithSelector(ISymbioticVault.deposit.selector, vault, amount);
		bytes memory result = IVault(vault).execute(symbioticVault, depositData, 0);

		(depositedAmount, mintedShares) = abi.decode(result, (uint256, uint256));
		require(depositedAmount == amount, "SymbioticProxy: invalid deposited amount");
	}

	function withdraw(uint256 amount) external onlyOwner nonReentrant returns (uint256 burnedShares, uint256 mintedShares) {
		require(amount > 0, "SymbioticProxy: invalid amount");

		bytes memory withdrawData = abi.encodeWithSelector(ISymbioticVault.withdraw.selector, vault, amount);
		bytes memory result = IVault(vault).execute(symbioticVault, withdrawData, 0);

		(burnedShares, mintedShares) = abi.decode(result, (uint256, uint256));
	}

	function redeem(uint256 shares) external onlyOwner nonReentrant returns (uint256 withdrawnAssets, uint256 mintedShares) {
		require(shares > 0, "SymbioticProxy: invalid shares");

		bytes memory redeemData = abi.encodeWithSelector(ISymbioticVault.redeem.selector, vault, shares);
		bytes memory result = IVault(vault).execute(symbioticVault, redeemData, 0);

		(withdrawnAssets, mintedShares) = abi.decode(result, (uint256, uint256));
	}

	function claim(uint256 epoch) external onlyOwner nonReentrant returns (uint256 amount) {
		require(principleRecipient != address(0), "SymbioticProxy: principle recipient not set");

		bytes memory claimData = abi.encodeWithSelector(ISymbioticVault.claim.selector, principleRecipient, epoch);
		bytes memory result = IVault(vault).execute(symbioticVault, claimData, 0);

		amount = abi.decode(result, (uint256));
	}

	function claimRewards() external onlyOwner nonReentrant {
		require(rewardRecipient != address(0), "SymbioticProxy: reward recipient not set");
		require(rewardToken != address(0), "SymbioticProxy: reward token not set");

		bytes[] memory activeSharesOfHints = new bytes[](0);
		address network = address(0x98e52Ea7578F2088c152E81b17A9a459bF089f2a);
		uint256 maxRewards = 1000;
		bytes memory rewardData = abi.encode(network, maxRewards, activeSharesOfHints);
		bytes memory callData = abi.encodeWithSelector(
			IDefaultStakerRewards.claimRewards.selector,
			rewardRecipient,
			rewardToken,
			rewardData
		);

		IVault(vault).execute(defaultStakerRewards, callData, 0);
	}
}