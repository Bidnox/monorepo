// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {inco} from "../Lib.sol";
import {euint256, ALLOWANCE_GRANTED_MAGIC_VALUE} from "../Types.sol";
import {IncoTest} from "./IncoTest.sol";
import {IIncoVerifier} from "../interfaces/IIncoVerifier.sol";
import {IncoVerifier} from "../IncoVerifier.sol";
import {AdvancedAccessControl} from "../lightning-parts/AccessControl/AdvancedAccessControl.sol";
import {AllowanceVoucher, AllowanceProof} from "../lightning-parts/AccessControl/AdvancedAccessControl.sol";
import {REQUIRED_ALLOWANCE_VOUCHER_WARNING} from "../lightning-parts/AccessControl/AdvancedAccessControl.types.sol";
import {DecryptionAttester} from "../lightning-parts/DecryptionAttester.sol";
import {
    DecryptionAttestation,
    ElementAttestationWithProof,
    ReencryptionAttestation
} from "../lightning-parts/DecryptionAttester.types.sol";

/// @dev Approves any caller — simplest possible voucher verifier so the proof flow doesn't
/// shadow the property under test (which is the pause gate, not voucher logic).
contract AlwaysApprove {

    function check(bytes32, address, bytes memory, bytes memory) public pure returns (bytes32) {
        return ALLOWANCE_GRANTED_MAGIC_VALUE;
    }

}

/// @dev Minimal test contract — reverts if the verifier reports the attestation invalid.
contract TestContract {

    error InvalidAttestation();

    IIncoVerifier verifier;

    constructor(IIncoVerifier _verifier) {
        verifier = _verifier;
    }

    function verify(DecryptionAttestation memory att, bytes[] calldata signatures) external view {
        if (!verifier.isValidDecryptionAttestation(att, signatures)) {
            revert InvalidAttestation();
        }
    }

}

contract TestVerifierPause is IncoTest {

    function testValidAttestationsBecomeInvalidWhenVerifierIsPaused() public {
        IIncoVerifier verifier = inco.incoVerifier();

        // Set up a valid decryption attestation for a handle alice owns
        vm.startPrank(alice);
        euint256 secret = inco.asEuint256(42);
        inco.allow(euint256.unwrap(secret), alice);
        vm.stopPrank();
        bytes32 handle = euint256.unwrap(secret);

        AllowanceProof memory emptyProof; // sharer == address(0) → no voucher needed
        (DecryptionAttestation memory att, bytes[] memory sigs) =
            getDecryptionAttestation(alice, HandleWithProof({handle: handle, proof: emptyProof}));

        // Set up a valid voucher-based AllowanceProof so isAllowedWithProof returns true
        AlwaysApprove approver = new AlwaysApprove();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(approver),
            callFunction: approver.check.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory proof = AllowanceProof({
            sharer: alice,
            voucher: voucher,
            voucherSignature: getSignatureForDigest(verifier.allowanceVoucherDigest(voucher), alicePrivKey),
            requesterArgData: ""
        });

        // Set up valid reencryption + elist attestations (helpers scope away locals
        // that would otherwise blow the 16-slot stack limit in this function)
        (ReencryptionAttestation[] memory reAtts, bytes[] memory reSigs) = _buildValidReencryption(verifier, handle);
        (ElementAttestationWithProof[] memory proofElements, bytes32 elistProof, bytes[] memory elistSigs) =
            _buildValidElistAttestation(verifier, handle);

        TestContract testContract = new TestContract(verifier);

        // Sanity: every attestation is valid before pause
        assertTrue(verifier.isValidDecryptionAttestation(att, sigs), "decryption attestation should be valid");
        assertTrue(verifier.isAllowedWithProof(handle, bob, proof), "voucher proof should grant access");
        assertTrue(verifier.isValidReencryptionAttestation(reAtts, reSigs), "reencryption attestation should be valid");
        assertTrue(
            verifier.isValidEListDecryptionAttestation(handle, proofElements, elistProof, elistSigs),
            "elist decryption attestation should be valid"
        );
        testContract.verify(att, sigs); // shouldn't revert

        // Pause the verifier
        vm.prank(owner);
        IncoVerifier(address(verifier)).pause();

        // Pause flips every verifier check to false for the same inputs
        assertFalse(
            verifier.isValidDecryptionAttestation(att, sigs), "decryption attestation should be invalid when paused"
        );
        assertFalse(verifier.isAllowedWithProof(handle, bob, proof), "voucher proof should be rejected when paused");
        assertFalse(
            verifier.isValidReencryptionAttestation(reAtts, reSigs),
            "reencryption attestation should be invalid when paused"
        );
        assertFalse(
            verifier.isValidEListDecryptionAttestation(handle, proofElements, elistProof, elistSigs),
            "elist decryption attestation should be invalid when paused"
        );

        // Downstream test contract that trusts the verifier reverts
        vm.expectRevert(TestContract.InvalidAttestation.selector);
        testContract.verify(att, sigs);

        // Unpause restores validity (the attestation/proof bytes are unchanged)
        vm.prank(owner);
        IncoVerifier(address(verifier)).unpause();
        assertTrue(verifier.isValidDecryptionAttestation(att, sigs), "decryption attestation should be valid again");
        assertTrue(verifier.isAllowedWithProof(handle, bob, proof), "voucher proof should grant access again");
        assertTrue(
            verifier.isValidReencryptionAttestation(reAtts, reSigs), "reencryption attestation should be valid again"
        );
        assertTrue(
            verifier.isValidEListDecryptionAttestation(handle, proofElements, elistProof, elistSigs),
            "elist decryption attestation should be valid again"
        );
        testContract.verify(att, sigs); // shouldn't revert
    }

    /// @dev helper to build a valid ReencryptionAttestation + signatures that pass the verifier checks when not paused.
    function _buildValidReencryption(IIncoVerifier verifier, bytes32 handle)
        private
        view
        returns (ReencryptionAttestation[] memory atts, bytes[] memory sigs)
    {
        atts = new ReencryptionAttestation[](1);
        atts[0] =
            ReencryptionAttestation({handle: handle, userCiphertext: hex"deadbeef", encryptedSignature: hex"cafebabe"});
        sigs = new bytes[](1);
        sigs[0] = getSignatureForDigest(verifier.reencryptionAttestationDigest(atts[0]), teePrivKey);
    }

    /// @dev helper to build a valid EListAttestation + signatures that pass the verifier checks when not paused.
    function _buildValidElistAttestation(IIncoVerifier verifier, bytes32 handle)
        private
        view
        returns (ElementAttestationWithProof[] memory elements, bytes32 proof, bytes[] memory sigs)
    {
        elements = new ElementAttestationWithProof[](1);
        elements[0] =
            ElementAttestationWithProof({pairHash: keccak256("elem"), commitment: bytes32(0), value: bytes32(0)});
        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = elements[0].pairHash;
        proof = keccak256(abi.encodePacked(hashes));
        sigs = new bytes[](1);
        sigs[0] = getSignatureForDigest(
            verifier.decryptionAttestationDigest(DecryptionAttestation({handle: handle, value: proof})), teePrivKey
        );
    }

    /// @dev Security-critical: when paused, the four verifier checks must short-circuit to
    /// false BEFORE running any input validation.
    function testPausedVerifierShortCircuitsBeforeInputValidation() public {
        IIncoVerifier verifier = inco.incoVerifier();

        // Inputs designed to exercise the unpaused revert paths in two of the four checks.
        // (`isValidDecryptionAttestation` and `isValidEListDecryptionAttestation` use
        // tryRecover + length-based early returns, so they don't have a clean malformed-revert
        // path — for them we just assert the pause gate cleanly returns false.)
        AllowanceProof memory garbageProof; // voucher.warning == "" → InvalidVoucherWarning
        ReencryptionAttestation[] memory atts = new ReencryptionAttestation[](2);
        bytes[] memory sigsLenOne = new bytes[](1); // mismatched → AttestationsSignaturesLengthMismatch
        bytes[] memory sigsEmpty = new bytes[](0);
        DecryptionAttestation memory garbageAtt;
        ElementAttestationWithProof[] memory emptyElements = new ElementAttestationWithProof[](0);

        // Sanity: the malformed inputs DO revert when not paused
        vm.expectRevert(AdvancedAccessControl.InvalidVoucherWarning.selector);
        verifier.isAllowedWithProof(bytes32(0), address(0), garbageProof);

        vm.expectRevert(abi.encodeWithSelector(DecryptionAttester.AttestationsSignaturesLengthMismatch.selector, 2, 1));
        verifier.isValidReencryptionAttestation(atts, sigsLenOne);

        // Pause; the same calls must return false WITHOUT reverting
        vm.prank(owner);
        IncoVerifier(address(verifier)).pause();

        assertFalse(
            verifier.isAllowedWithProof(bytes32(0), address(0), garbageProof),
            "isAllowedWithProof must return false (not revert) when paused with garbage proof"
        );
        assertFalse(
            verifier.isValidReencryptionAttestation(atts, sigsLenOne),
            "isValidReencryptionAttestation must return false (not revert) when paused with mismatched arrays"
        );
        assertFalse(
            verifier.isValidDecryptionAttestation(garbageAtt, sigsEmpty),
            "isValidDecryptionAttestation must return false when paused"
        );
        assertFalse(
            verifier.isValidEListDecryptionAttestation(bytes32(0), emptyElements, bytes32(0), sigsEmpty),
            "isValidEListDecryptionAttestation must return false when paused"
        );
    }

}
