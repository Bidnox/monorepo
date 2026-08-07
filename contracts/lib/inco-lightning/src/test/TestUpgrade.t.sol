// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Safe} from "safe-smart-account/Safe.sol";
import {Enum} from "safe-smart-account/libraries/Enum.sol";
import {IOwnerManager} from "safe-smart-account/interfaces/IOwnerManager.sol";
import {IncoTest} from "./IncoTest.sol";
import {inco} from "../Lib.sol";
import {IncoLightning} from "../IncoLightning.sol";
import {IncoVerifier} from "../IncoVerifier.sol";
import {SessionVerifier, Session} from "../periphery/SessionVerifier.sol";
import {ALLOWANCE_GRANTED_MAGIC_VALUE} from "../Types.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IVersion} from "../version/interfaces/IVersion.sol";
import {Version} from "../version/Version.sol";
import {IIncoVerifier} from "../interfaces/IIncoVerifier.sol";
import {MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION} from "../version/IncoLightningConfig.sol";
import {Salt} from "../periphery/SaltLib.sol";

interface IUUPS {

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;

}

contract IncoLightningV2 is IncoLightning {

    uint8 constant MAJOR_VERSION_MOCK = 255;
    uint8 constant MINOR_VERSION_MOCK = 255;
    uint8 constant PATCH_VERSION_MOCK = 255;

    constructor(bytes32 salt) IncoLightning(salt, IIncoVerifier(address(0))) {}

    function getVersion() public view virtual override(IVersion, Version) returns (string memory) {
        return versionString(MAJOR_VERSION_MOCK, MINOR_VERSION_MOCK, PATCH_VERSION_MOCK);
    }

}

contract TestUpgrade is IncoTest {

    using Strings for uint256;

    // EIP-1967 implementation slot
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC;

    address private incoProxyAddr;
    IncoLightning private v1Impl;
    IncoLightningV2 private v2Impl;

    function safe() internal view returns (Safe) {
        return Safe(payable(owner));
    }

    function setUp() public override {
        super.setUp();
        incoProxyAddr = address(inco);

        // Deploy V2
        bytes32 salt = Salt.getSalt("IncoLightningV2", 255, testDeployer, "testnet");
        v2Impl = new IncoLightningV2(salt);
    }

    function test_SafeUpgrade2of3_Succeeds() public {
        string memory versionBefore = inco.getVersion();
        assertEq(
            versionBefore,
            string.concat(
                uint256(MAJOR_VERSION).toString(),
                "_",
                uint256(MINOR_VERSION).toString(),
                "_",
                uint256(PATCH_VERSION).toString()
            )
        );
        // data to sign
        bytes memory data = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        // prepare txhash
        bytes32 txHash = _txHash(safe(), incoProxyAddr, 0, data);
        // sign txHash
        bytes memory sigA = _sign(alicePrivKey, txHash);
        bytes memory sigB = _sign(bobPrivKey, txHash);
        // sort signatures (asc)
        bytes memory signatures = _packSortedTwo(sigA, alice, sigB, bob);
        // execute tx with sorted signatures
        _execSafe(safe(), incoProxyAddr, 0, data, signatures);

        address implAfter = address(uint160(uint256(vm.load(incoProxyAddr, IMPLEMENTATION_SLOT))));
        assertEq(implAfter, address(v2Impl));

        string memory versionAfter = inco.getVersion();
        assertEq(versionAfter, "255_255_255");
    }

    function test_SafeSingleSignature_Fails() public {
        bytes memory data = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        bytes32 txHash = _txHash(safe(), incoProxyAddr, 0, data);
        bytes memory sigA = _sign(alicePrivKey, txHash);
        vm.expectRevert();
        _execSafe(safe(), incoProxyAddr, 0, data, sigA);
    }

    function test_Safe_UnsortedSignatures_Fails() public {
        bytes memory data = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        bytes32 txHash = _txHash(safe(), incoProxyAddr, 0, data);
        bytes memory sigA = _sign(alicePrivKey, txHash);
        bytes memory sigC = _sign(carolPrivKey, txHash);
        bytes memory signatures = bytes.concat(sigC, sigA); // unsorted
        vm.expectRevert();
        _execSafe(safe(), incoProxyAddr, 0, data, signatures);
    }

    function test_Safe_WrongSigner_Fails() public {
        bytes memory data = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        bytes32 txHash = _txHash(safe(), incoProxyAddr, 0, data);
        bytes memory sigOwner = _sign(alicePrivKey, txHash);
        bytes memory sigAttacker = _sign(davePrivKey, txHash);
        bytes memory signatures = _packSortedTwo(sigOwner, alice, sigAttacker, dave); // dave not an owner
        vm.expectRevert();
        _execSafe(safe(), incoProxyAddr, 0, data, signatures);
    }

    function test_Safe_ReplayNonce_Fails() public {
        bytes memory data = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        bytes32 txHash = _txHash(safe(), incoProxyAddr, 0, data);
        bytes memory sigA = _sign(alicePrivKey, txHash);
        bytes memory sigB = _sign(bobPrivKey, txHash);
        bytes memory signatures = _packSortedTwo(sigA, alice, sigB, bob);
        _execSafe(safe(), incoProxyAddr, 0, data, signatures);

        string memory versionAfter = inco.getVersion();
        assertEq(versionAfter, "255_255_255");

        vm.expectRevert();
        _execSafe(safe(), incoProxyAddr, 0, data, signatures); // nonce advanced
    }

    function test_Safe_UpdateSigners_SwapOwner_ThenUpgrade() public {
        // swap bob -> eve (prevOwner = alice since owners were [alice, bob, carol])
        bytes memory change = abi.encodeWithSelector(IOwnerManager.swapOwner.selector, alice, bob, eve);
        bytes32 changeHash = _txHash(safe(), address(safe()), 0, change);
        bytes memory changeSigA = _sign(alicePrivKey, changeHash);
        bytes memory changeSigC = _sign(carolPrivKey, changeHash);
        bytes memory changeSigs = _packSortedTwo(changeSigA, alice, changeSigC, carol);
        _execSafe(safe(), address(safe()), 0, change, changeSigs);

        // assertions on owners/threshold
        assertTrue(safe().isOwner(eve), "new owner not added");
        assertFalse(safe().isOwner(bob), "old owner not removed");
        assertEq(safe().getThreshold(), 2, "threshold changed unexpectedly");

        // Attempt upgrade signed by removed owner should fail
        bytes memory upg = abi.encodeWithSelector(IUUPS.upgradeToAndCall.selector, address(v2Impl), "");
        bytes32 upgHash = _txHash(safe(), incoProxyAddr, 0, upg);
        bytes memory badSigA = _sign(alicePrivKey, upgHash);
        bytes memory badSigB = _sign(bobPrivKey, upgHash); // removed owner
        bytes memory badSigs = _packSortedTwo(badSigA, alice, badSigB, bob);
        vm.expectRevert();
        _execSafe(safe(), incoProxyAddr, 0, upg, badSigs);

        // Now sign with new owner (owner4) and succeed
        bytes memory goodSigA = _sign(alicePrivKey, upgHash);
        bytes memory goodSigE = _sign(evePrivKey, upgHash);
        bytes memory goodSigs = _packSortedTwo(goodSigA, alice, goodSigE, eve);
        _execSafe(safe(), incoProxyAddr, 0, upg, goodSigs);

        address implAfter = address(uint160(uint256(vm.load(incoProxyAddr, IMPLEMENTATION_SLOT))));
        assertEq(implAfter, address(v2Impl));

        string memory versionAfter = inco.getVersion();
        assertEq(versionAfter, "255_255_255");
    }

    function test_Upgrade_NotBy_SafeWallet_Fails() public {
        vm.prank(alice);
        vm.expectRevert();
        inco.upgradeToAndCall(address(v2Impl), "");
    }

    // ============ IncoVerifier Tests ============

    function test_IncoVerifier_GetEIP712Name() public view {
        IncoVerifier verifier = IncoVerifier(address(inco.incoVerifier()));
        string memory name = verifier.getEIP712Name();
        // Name should not be empty
        assertGt(bytes(name).length, 0, "EIP712 name should not be empty");
    }

    function test_IncoVerifier_GetEIP712Version() public view {
        IncoVerifier verifier = IncoVerifier(address(inco.incoVerifier()));
        string memory version = verifier.getEIP712Version();
        // Version should not be empty
        assertGt(bytes(version).length, 0, "EIP712 version should not be empty");
    }

    function test_IncoVerifier_Upgrade_ByOwner_Succeeds() public {
        IncoVerifier verifier = IncoVerifier(address(inco.incoVerifier()));

        // Deploy a new IncoVerifier implementation
        IncoVerifier newImpl = new IncoVerifier(address(inco));

        // Upgrade by owner should succeed — owner is the Safe, so prank as Safe
        vm.prank(owner);
        verifier.upgradeToAndCall(address(newImpl), "");
    }

    function test_IncoVerifier_Upgrade_ByNonOwner_Fails() public {
        IncoVerifier verifier = IncoVerifier(address(inco.incoVerifier()));

        // Deploy a new IncoVerifier implementation
        IncoVerifier newImpl = new IncoVerifier(address(inco));

        // Upgrade by non-owner should fail
        vm.prank(alice);
        vm.expectRevert();
        verifier.upgradeToAndCall(address(newImpl), "");
    }

    // ============ SessionVerifier Tests ============

    function test_SessionVerifier_ValidSession_ReturnsAllowanceGranted() public {
        SessionVerifier verifier = new SessionVerifier("");

        bytes memory sharerArgData = abi.encode(Session({decrypter: bob, expiresAt: block.timestamp + 1 days}));

        bytes32 result = verifier.canUseSession(bytes32(0), bob, sharerArgData, "");
        assertEq(result, ALLOWANCE_GRANTED_MAGIC_VALUE, "Valid session should return ALLOWANCE_GRANTED_MAGIC_VALUE");
    }

    function test_SessionVerifier_ExpiredSession_ReturnsZero() public {
        SessionVerifier verifier = new SessionVerifier("");

        // Create session that expired 1 second ago
        bytes memory sharerArgData = abi.encode(Session({decrypter: bob, expiresAt: block.timestamp - 1}));

        bytes32 result = verifier.canUseSession(bytes32(0), bob, sharerArgData, "");
        assertEq(result, bytes32(0), "Expired session should return bytes32(0)");
    }

    function test_SessionVerifier_WrongDecrypter_ReturnsZero() public {
        SessionVerifier verifier = new SessionVerifier("");

        // Session is valid but decrypter doesn't match caller
        bytes memory sharerArgData = abi.encode(Session({decrypter: alice, expiresAt: block.timestamp + 1 days}));

        bytes32 result = verifier.canUseSession(bytes32(0), bob, sharerArgData, "");
        assertEq(result, bytes32(0), "Wrong decrypter should return bytes32(0)");
    }

    function test_SessionVerifier_Initialize() public {
        SessionVerifier verifier = _deploySessionVerifierProxy(alice);
        assertEq(verifier.owner(), alice, "Owner should be alice after initialize");
    }

    function test_SessionVerifier_Upgrade_ByOwner_Succeeds() public {
        SessionVerifier verifier = _deploySessionVerifierProxy(alice);

        // Deploy new implementation
        SessionVerifier newImpl = new SessionVerifier("");

        // Upgrade by owner should succeed
        vm.prank(alice);
        verifier.upgradeToAndCall(address(newImpl), "");
    }

    function test_SessionVerifier_Upgrade_ByNonOwner_Fails() public {
        SessionVerifier verifier = _deploySessionVerifierProxy(alice);

        // Deploy new implementation
        SessionVerifier newImpl = new SessionVerifier("");

        // Upgrade by non-owner should fail
        vm.prank(bob);
        vm.expectRevert();
        verifier.upgradeToAndCall(address(newImpl), "");
    }

    // Helpers
    function _deploySessionVerifierProxy(address proxyOwner) private returns (SessionVerifier) {
        SessionVerifier impl = new SessionVerifier(bytes32(0));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(SessionVerifier.initialize, (proxyOwner)));
        return SessionVerifier(address(proxy));
    }

    function _txHash(Safe _safe, address to, uint256 value, bytes memory data) internal view returns (bytes32) {
        return _safe.getTransactionHash(
            to, value, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), _safe.nonce()
        );
    }

    function _sign(uint256 pk, bytes32 txHash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, txHash);
        if (v < 27) v += 27;
        return abi.encodePacked(r, s, v);
    }

    function _packSortedTwo(bytes memory sigA, address addrA, bytes memory sigB, address addrB)
        internal
        pure
        returns (bytes memory)
    {
        return addrA < addrB ? bytes.concat(sigA, sigB) : bytes.concat(sigB, sigA);
    }

    function _execSafe(Safe _safe, address to, uint256 value, bytes memory data, bytes memory signatures) internal {
        _safe.execTransaction(
            to, value, data, Enum.Operation.Call, 0, 0, 0, address(0), payable(address(0)), signatures
        );
    }

}
