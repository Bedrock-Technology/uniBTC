// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test, console} from "forge-std/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";
import {uniBTC} from "../mock/uniBTC.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract AirdropTest is Test {
    Airdrop public airdrop;
    uniBTC public unibtc;
    ProxyAdmin public proxyAdmin;
    Account public Owner = makeAccount("owner");

    uint32 private activationDelay = 1 days;
    uint32 private validDuration = 30 days;

    bytes32 private merkleRoot;

    receive() external payable {
        // Fallback function to receive ether
    }

    function setUp() public {
        uniBTC unibtcImp = new uniBTC();
        Airdrop airdropImp = new Airdrop();
        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        proxyAdmin = _proxyAdmin;

        merkleRoot = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, 1000))));

        proxyAdmin.transferOwnership(Owner.addr);
        TransparentUpgradeableProxy airdropProxy = new TransparentUpgradeableProxy(
            address(airdropImp),
            address(proxyAdmin),
            abi.encodeWithSelector(Airdrop.initialize.selector, activationDelay, Owner.addr)
        );

        TransparentUpgradeableProxy uniBTCProxy = new TransparentUpgradeableProxy(
            address(unibtcImp),
            address(proxyAdmin),
            abi.encodeWithSelector(uniBTC.initialize.selector, Owner.addr, Owner.addr, new address[](0))
        );
        airdrop = Airdrop(payable(airdropProxy));
        vm.startPrank(Owner.addr);
        airdrop.grantRole(airdrop.OPERATOR_ROLE(), Owner.addr);
        vm.stopPrank();
        unibtc = uniBTC(address(uniBTCProxy));
        // Deal tokens to airdrop contract for distribution
        deal(address(airdrop), 1 ether);
    }

    //forge test test/Airdrop.t.sol --match-test testInitialize
    function testInitialize() public view {
        assertEq(airdrop.activationDelay(), activationDelay);
        assertEq(airdrop.epochAdded(), 0);
    }

    //forge test test/Airdrop.t.sol --match-test testSubmitMerkleRoot
    function testSubmitMerkleRoot() public {
        vm.prank(Owner.addr);
        airdrop.submitRoot(merkleRoot, validDuration, address(0), 1);
        Airdrop.Dist memory distribution = airdrop.getRoot(1);
        assertEq(distribution.root, merkleRoot);
        assertEq(distribution.duration, validDuration);
        assertEq(distribution.disabled, false);
    }

    //forge test test/Airdrop.t.sol --match-test testClaim
    function testClaim() public {
        // Submit merkle root and wait for activation
        vm.prank(Owner.addr);
        airdrop.submitRoot(merkleRoot, validDuration, address(0), 1);
        vm.warp(block.timestamp + activationDelay);

        // Calculate leaf using the same method as in contract
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(address(this), 1000))));

        // Use this leaf as merkleRoot (simplified Merkle tree)
        merkleRoot = leaf;
        vm.prank(Owner.addr);
        airdrop.updateRoot(merkleRoot, 1);

        // Create empty proof (since we use leaf as root directly)
        bytes32[] memory proof = new bytes32[](0);

        uint256 _beforeBalance = address(this).balance;
        vm.expectRevert(bytes("USR006"));
        // Execute claim failed
        airdrop.claim(1000, proof, 0);

        // Execute claim
        airdrop.claim(1000, proof, 1);

        assertEq(address(this).balance, _beforeBalance + 1000);

        // Verify claim success using updated function
        address[] memory users = new address[](1);
        users[0] = address(this);
        bool[] memory claims = airdrop.hasClaimed(1, users);
        assertTrue(claims[0]);
    }

    //forge test test/Airdrop.t.sol --match-test testUpdateRoot
    function testUpdateRoot() public {
        // Submit initial merkle root
        vm.prank(Owner.addr);
        airdrop.submitRoot(merkleRoot, validDuration, address(0), 1);

        // Update to new merkle root
        bytes32 newMerkleRoot = keccak256(bytes.concat(keccak256(abi.encode(address(this), 2000))));
        vm.prank(Owner.addr);
        airdrop.updateRoot(newMerkleRoot, 1);

        Airdrop.Dist memory distribution = airdrop.getRoot(1);
        assertEq(distribution.root, newMerkleRoot);
        vm.prank(Owner.addr);
        vm.expectRevert(bytes("USR002"));
        airdrop.updateRoot(newMerkleRoot, 2);
    }

    //forge test test/Airdrop.t.sol --match-test testClaimWithERC20
    function testClaimWithERC20() public {
        // Submit merkle root and wait for activation
        vm.prank(Owner.addr);
        airdrop.submitRoot(merkleRoot, validDuration, address(unibtc), 1);
        vm.warp(block.timestamp + activationDelay);

        // Calculate leaf using the same method as in contract
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(address(this), 1000))));

        // Use this leaf as merkleRoot (simplified Merkle tree)
        merkleRoot = leaf;
        vm.startPrank(Owner.addr);
        airdrop.updateRoot(merkleRoot, 1);
        unibtc.mint(address(airdrop), 1000000000); // Mint some uniBTC to the test contract for claiming
        vm.stopPrank();

        // Create empty proof (since we use leaf as root directly)
        bytes32[] memory proof = new bytes32[](0);

        uint256 _beforeBalance = unibtc.balanceOf(address(this));

        // Execute claim
        airdrop.claim(1000, proof, 1);

        assertEq(unibtc.balanceOf(address(this)), _beforeBalance + 1000);
    }
}
