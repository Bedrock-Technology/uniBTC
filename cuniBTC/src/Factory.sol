// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./cuniBTC.sol";
import "./Vault.sol";
import "./Airdrop.sol";
import "./DelayRedeemRouter.sol";

contract Factory is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    struct Strategy {
        string name;
        string symbol;
        address vault;
        address cuniBTC;
        address delayRedeemRouter;
        address airdrop;
    }
    mapping(string => Strategy) public strategies;

    cuniBTC public cuniBTCImpl;
    UpgradeableBeacon public cuniBTCBeacon;

    Vault public vaultImpl;
    UpgradeableBeacon public vaultBeacon;

    Airdrop public airdropImpl;
    UpgradeableBeacon public airdropBeacon;

    DelayRedeemRouter public delayRedeemRouterImpl;
    UpgradeableBeacon public delayRedeemRouterBeacon;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _cuniBTCImpl, address _vaultImpl, address _airdropImpl, address _delayRedeemRouterImpl)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(
            _cuniBTCImpl != address(0) && _vaultImpl != address(0) && _airdropImpl != address(0)
                && _delayRedeemRouterImpl != address(0)
        );
        cuniBTCImpl = cuniBTC(_cuniBTCImpl);
        cuniBTCBeacon = new UpgradeableBeacon(address(cuniBTCImpl));

        vaultImpl = Vault(payable(_vaultImpl));
        vaultBeacon = new UpgradeableBeacon(address(vaultImpl));

        airdropImpl = Airdrop(payable(_airdropImpl));
        airdropBeacon = new UpgradeableBeacon(address(airdropImpl));

        delayRedeemRouterImpl = DelayRedeemRouter(payable(_delayRedeemRouterImpl));
        delayRedeemRouterBeacon = new UpgradeableBeacon(address(delayRedeemRouterImpl));
    }

    function createStrategy(string memory _name, string memory _symbol, address _defaultAdmin, address _uniBTC)
        external
        nonReentrant
        onlyOwner
    {
        Strategy memory existing = strategies[_symbol];
        if (existing.vault != address(0)) {
            revert("Strategy already exists");
        }

        BeaconProxy cuniBTCProxy = new BeaconProxy(
            address(cuniBTCBeacon), abi.encodeCall(cuniBTC.initialize, (address(this), _name, _symbol))
        );
        BeaconProxy vaultProxy = new BeaconProxy(
            address(vaultBeacon), abi.encodeCall(Vault.initialize, (address(this), address(cuniBTCProxy), 50e8))
        );
        BeaconProxy airdropProxy =
            new BeaconProxy(address(airdropBeacon), abi.encodeCall(Airdrop.initialize, (1 days, address(this))));
        BeaconProxy delayRedeemRouterProxy = new BeaconProxy(
            address(delayRedeemRouterBeacon),
            abi.encodeCall(
                DelayRedeemRouter.initialize, (address(this), address(cuniBTCProxy), address(vaultProxy), 7 days, false)
            )
        );
        Strategy memory strategy = Strategy({
            name: _name,
            symbol: _symbol,
            vault: address(vaultProxy),
            cuniBTC: address(cuniBTCProxy),
            delayRedeemRouter: address(delayRedeemRouterProxy),
            airdrop: address(airdropProxy)
        });

        strategies[_symbol] = strategy;
        _setup(strategy, _uniBTC);
        _grantRevokeAdmin(strategy, _defaultAdmin);
        emit StrategyCreate(_symbol, strategy);
    }

    function upgradeBeacon(address _beacon, address _newImpl) external onlyOwner {
        UpgradeableBeacon(_beacon).upgradeTo(_newImpl);
        require(UpgradeableBeacon(_beacon).implementation() == _newImpl, "Upgrade failed");
        if (_beacon == address(cuniBTCBeacon)) {
            cuniBTCImpl = cuniBTC(_newImpl);
        } else if (_beacon == address(vaultBeacon)) {
            vaultImpl = Vault(payable(_newImpl));
        } else if (_beacon == address(airdropBeacon)) {
            airdropImpl = Airdrop(payable(_newImpl));
        } else if (_beacon == address(delayRedeemRouterBeacon)) {
            delayRedeemRouterImpl = DelayRedeemRouter(payable(_newImpl));
        } else {
            revert("Invalid beacon address");
        }
        emit BeaconUpgrade(_beacon, _newImpl);
    }

    function _setup(Strategy memory strategy, address uniBTC) internal {
        address[] memory allowToken = new address[](1);
        allowToken[0] = uniBTC;
        Vault(payable(strategy.vault)).allowToken(allowToken);
        // Grant roles to vault
        cuniBTC(strategy.cuniBTC).grantRole(cuniBTC(strategy.cuniBTC).MINTER_ROLE(), strategy.vault);

        address[] memory btcList = new address[](1);
        btcList[0] = uniBTC;
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).addToBtclist(btcList);
        uint256[] memory quotas = new uint256[](1);
        quotas[0] = 2e8;
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).setMaxQuotaForTokens(btcList, quotas);
        quotas[0] = 2314;
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).setQuotaRates(btcList, quotas);
        DelayRedeemRouter(payable(strategy.delayRedeemRouter)).setRedeemFeeRate(0);
        // DelayRedeemRouter(payable(strategy.delayRedeemRouter))
        //     .grantRole(DelayRedeemRouter(payable(strategy.delayRedeemRouter)).OPERATOR_ROLE(), strategy.vault);
        //allow transfer cuniBTC to redeem
        cuniBTC(strategy.cuniBTC).setRedeemRouter(strategy.delayRedeemRouter);
        Vault(payable(strategy.vault))
            .grantRole(Vault(payable(strategy.vault)).OPERATOR_ROLE(), strategy.delayRedeemRouter);
        address[] memory allowTarget = new address[](2);
        allowTarget[0] = uniBTC;
        allowTarget[1] = strategy.cuniBTC;
        Vault(payable(strategy.vault)).allowTarget(allowTarget);
    }

    function _grantRevokeAdmin(Strategy memory strategy, address admin) internal {
        Vault(payable(strategy.vault)).grantRole(Vault(payable(strategy.vault)).DEFAULT_ADMIN_ROLE(), admin);
        Vault(payable(strategy.vault)).revokeRole(Vault(payable(strategy.vault)).DEFAULT_ADMIN_ROLE(), address(this));

        cuniBTC(strategy.cuniBTC).grantRole(cuniBTC(strategy.cuniBTC).DEFAULT_ADMIN_ROLE(), admin);
        cuniBTC(strategy.cuniBTC).revokeRole(cuniBTC(strategy.cuniBTC).DEFAULT_ADMIN_ROLE(), address(this));

        DelayRedeemRouter(payable(strategy.delayRedeemRouter))
            .grantRole(DelayRedeemRouter(payable(strategy.delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), admin);
        DelayRedeemRouter(payable(strategy.delayRedeemRouter))
            .revokeRole(DelayRedeemRouter(payable(strategy.delayRedeemRouter)).DEFAULT_ADMIN_ROLE(), address(this));

        Airdrop(payable(strategy.airdrop)).grantRole(Airdrop(payable(strategy.airdrop)).DEFAULT_ADMIN_ROLE(), admin);
        Airdrop(payable(strategy.airdrop))
            .revokeRole(Airdrop(payable(strategy.airdrop)).DEFAULT_ADMIN_ROLE(), address(this));
    }
    event StrategyCreate(string symbol, Strategy strategy);
    event BeaconUpgrade(address beacon, address newImpl);
}
