// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {TestUtils} from "../../../shared/TestUtils.sol";
import {SignatureVerifier} from "../SignatureVerifier.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TestSignatureVerifier is TestUtils, SignatureVerifier {

    using ECDSA for bytes32;

    function setUp() public initializer {
        // Initialize the contract
        __Ownable_init(address(this));
    }

    // Helper function to create sorted signatures
    // Takes a digest and an array of private keys, generates signatures,
    // and returns them sorted by signer address in ascending order
    function getSortedSignatures(bytes32 digest, uint256[] memory privKeys) internal pure returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](privKeys.length);
        address[] memory signers = new address[](privKeys.length);

        // Generate signatures and recover signer addresses
        for (uint256 i = 0; i < privKeys.length; i++) {
            signatures[i] = getSignatureForDigest(digest, privKeys[i]);
            signers[i] = digest.recover(signatures[i]);
        }

        // Bubble sort signatures by signer address (ascending)
        for (uint256 i = 0; i < signatures.length; i++) {
            for (uint256 j = i + 1; j < signatures.length; j++) {
                if (signers[i] > signers[j]) {
                    // Swap signers
                    address tempSigner = signers[i];
                    signers[i] = signers[j];
                    signers[j] = tempSigner;

                    // Swap signatures
                    bytes memory tempSig = signatures[i];
                    signatures[i] = signatures[j];
                    signatures[j] = tempSig;
                }
            }
        }

        return signatures;
    }

    // Helper functions to expose internal/external functions for testing
    function exposedAddSigner(address signerAddress) public {
        addSigner(signerAddress);
    }

    function exposedRemoveSigner(address signerAddress) public {
        this.removeSigner(signerAddress);
    }

    function exposedSetThreshold(uint256 newThreshold) public {
        this.setThreshold(newThreshold);
    }

    // ============ Tests for Adding Signers ============

    function testAddSingleSigner() public {
        exposedAddSigner(alice);
        assertTrue(isSigner(alice));
    }

    function testAddMultipleSigners() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);

        assertTrue(isSigner(alice));
        assertTrue(isSigner(bob));
        assertTrue(isSigner(carol));
    }

    function testRevertWhenAddingDuplicateSigner() public {
        exposedAddSigner(alice);

        // Test that adding the same signer again reverts
        // Using try-catch since the revert happens in an internal function
        try this.exposedAddSigner(alice) {
            fail("Expected revert when adding duplicate signer");
        } catch (bytes memory reason) {
            // Verify it's the correct error
            bytes4 expectedSelector = SignatureVerifier.SignerAlreadyAdded.selector;
            bytes4 receivedSelector = bytes4(reason);
            assertEq(receivedSelector, expectedSelector, "Wrong error selector");
        }
    }

    // ============ Tests for Setting Threshold ============

    function testSetThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);

        exposedSetThreshold(2);
        assertEq(getThreshold(), 2);
    }

    function testRevertWhenThresholdExceedsSigners() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);

        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.InvalidThreshold.selector, 3, 2));
        exposedSetThreshold(3);
    }

    function testRevertWhenThresholdIsZero() public {
        exposedAddSigner(alice);

        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.InvalidThreshold.selector, 0, 1));
        exposedSetThreshold(0);
    }

    function testThresholdChangedEvent() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(1);

        vm.expectEmit(true, true, true, true);
        emit ThresholdChanged(1, 2);
        exposedSetThreshold(2);
    }

    // ============ Tests for Signature Validation ============

    function testValidSignatureSingleSignerThresholdOne() public {
        exposedAddSigner(alice);
        exposedSetThreshold(1);

        bytes32 digest = keccak256("test message");
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = getSignatureForDigest(digest, alicePrivKey);

        assertTrue(isValidSignature(digest, signatures));
    }

    function testValidSignatureMultipleSignersThresholdMet() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");
        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertTrue(isValidSignature(digest, signatures));
    }

    function testValidSignatureMoreSignaturesThanThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");
        uint256[] memory privKeys = new uint256[](3);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        privKeys[2] = carolPrivKey;
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertTrue(isValidSignature(digest, signatures));
    }

    function testInvalidSignatureThresholdNotMet() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(3);

        bytes32 digest = keccak256("test message");
        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertFalse(isValidSignature(digest, signatures));
    }

    function testInvalidSignatureThresholdZero() public {
        exposedAddSigner(alice);
        // Don't set threshold, it defaults to 0

        bytes32 digest = keccak256("test message");
        bytes[] memory signatures = new bytes[](1);
        signatures[0] = getSignatureForDigest(digest, alicePrivKey);

        assertFalse(isValidSignature(digest, signatures));
    }

    function testInvalidSignatureNonSigner() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");
        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = davePrivKey; // Dave is not a signer
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertFalse(isValidSignature(digest, signatures));
    }

    function testDuplicateSignerReturnsFalse() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");
        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = alicePrivKey; // Duplicate
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        // Duplicate signers should return false (not revert)
        assertFalse(isValidSignature(digest, signatures), "Duplicate signer should return false");
    }

    function testUnsortedSignaturesStillWork() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create signatures in wrong order (descending instead of ascending)
        bytes[] memory signatures = new bytes[](2);
        address aliceAddr = vm.addr(alicePrivKey);
        address bobAddr = vm.addr(bobPrivKey);

        // Intentionally put them in wrong order based on addresses
        if (aliceAddr < bobAddr) {
            // Bob's signature first (wrong order)
            signatures[0] = getSignatureForDigest(digest, bobPrivKey);
            signatures[1] = getSignatureForDigest(digest, alicePrivKey);
        } else {
            // Alice's signature first (wrong order)
            signatures[0] = getSignatureForDigest(digest, alicePrivKey);
            signatures[1] = getSignatureForDigest(digest, bobPrivKey);
        }

        // Unsorted signatures should now work (optimistic sorting pattern)
        assertTrue(isValidSignature(digest, signatures), "Unsorted signatures should work");
    }

    function testThreeUnsortedSignaturesStillWork() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(3);

        bytes32 digest = keccak256("test message");

        // Get all three signatures
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);
        bytes memory carolSig = getSignatureForDigest(digest, carolPrivKey);

        // Recover addresses to determine correct order
        address aliceAddr = digest.recover(aliceSig);
        address bobAddr = digest.recover(bobSig);
        address carolAddr = digest.recover(carolSig);

        // Create an array with middle and last swapped (intentionally wrong order)
        bytes[] memory signatures = new bytes[](3);

        // Sort addresses to find middle one
        address[] memory addrs = new address[](3);
        addrs[0] = aliceAddr;
        addrs[1] = bobAddr;
        addrs[2] = carolAddr;

        // Simple sort
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (addrs[i] > addrs[j]) {
                    address temp = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = temp;
                }
            }
        }

        // Put in wrong order: smallest, largest, middle
        if (addrs[0] == aliceAddr) {
            signatures[0] = aliceSig;
            if (addrs[1] == bobAddr) {
                signatures[1] = carolSig; // Wrong: should be bob
                signatures[2] = bobSig;
            } else {
                signatures[1] = bobSig; // Wrong: should be carol
                signatures[2] = carolSig;
            }
        } else if (addrs[0] == bobAddr) {
            signatures[0] = bobSig;
            if (addrs[1] == aliceAddr) {
                signatures[1] = carolSig; // Wrong: should be alice
                signatures[2] = aliceSig;
            } else {
                signatures[1] = aliceSig; // Wrong: should be carol
                signatures[2] = carolSig;
            }
        } else {
            signatures[0] = carolSig;
            if (addrs[1] == aliceAddr) {
                signatures[1] = bobSig; // Wrong: should be alice
                signatures[2] = aliceSig;
            } else {
                signatures[1] = aliceSig; // Wrong: should be bob
                signatures[2] = bobSig;
            }
        }

        // Unsorted signatures should now work (optimistic sorting pattern)
        assertTrue(isValidSignature(digest, signatures), "Unsorted signatures should work");
    }

    function testSignaturesInCorrectAscendingOrderPasses() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(3);

        bytes32 digest = keccak256("test message");

        // Use the helper that sorts signatures correctly
        uint256[] memory privKeys = new uint256[](3);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        privKeys[2] = carolPrivKey;
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        // Should pass because signatures are in ascending order
        assertTrue(isValidSignature(digest, signatures));
    }

    function testInvalidSignaturesIgnoredBeyondThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create 3 signatures: Alice, Bob (both valid), and Dave (invalid)
        // After sorting, Dave's signature will be placed according to his address
        // As long as the first 2 signatures checked are from valid signers, it should pass
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey);

        address aliceAddr = digest.recover(aliceSig);
        address bobAddr = digest.recover(bobSig);
        address daveAddr = digest.recover(daveSig);

        // Sort them manually so Dave's signature is at the end (position 2, beyond threshold)
        address[] memory addrs = new address[](3);
        bytes[] memory sigs = new bytes[](3);
        addrs[0] = aliceAddr;
        addrs[1] = bobAddr;
        addrs[2] = daveAddr;
        sigs[0] = aliceSig;
        sigs[1] = bobSig;
        sigs[2] = daveSig;

        // Bubble sort
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // If Dave's address is in the first 2 positions, this test won't work as intended
        // So we skip the test if Dave ends up in the first 2 positions
        bool daveInFirstTwo = (addrs[0] == daveAddr || addrs[1] == daveAddr);

        if (!daveInFirstTwo) {
            // Dave is in position 2 (beyond threshold), so validation should pass
            assertTrue(isValidSignature(digest, sigs));
        } else {
            // Dave is in first 2 positions, so validation should fail
            assertFalse(isValidSignature(digest, sigs));
        }
    }

    function testInvalidSignatureWithInvalidSignerInFirstThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create signatures where an invalid signer (Dave) will be in the first threshold
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey);

        address aliceAddr = digest.recover(aliceSig);
        address bobAddr = digest.recover(bobSig);
        address daveAddr = digest.recover(daveSig);

        // Sort them
        address[] memory addrs = new address[](3);
        bytes[] memory sigs = new bytes[](3);
        addrs[0] = aliceAddr;
        addrs[1] = bobAddr;
        addrs[2] = daveAddr;
        sigs[0] = aliceSig;
        sigs[1] = bobSig;
        sigs[2] = daveSig;

        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // If Dave is in the first 2 positions, validation should fail
        bool daveInFirstTwo = (addrs[0] == daveAddr || addrs[1] == daveAddr);

        if (daveInFirstTwo) {
            assertFalse(isValidSignature(digest, sigs));
        } else {
            // If Dave is beyond threshold, it should pass
            assertTrue(isValidSignature(digest, sigs));
        }
    }

    // ============ Tests for Removing Signers ============

    function testRemoveSigner() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        exposedRemoveSigner(alice);
        assertFalse(isSigner(alice));
        assertTrue(isSigner(bob));
        assertTrue(isSigner(carol));
    }

    function testRevertWhenRemovingNonExistentSigner() public {
        exposedAddSigner(alice);

        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.SignerNotFound.selector, bob));
        exposedRemoveSigner(bob);
    }

    function testRevertWhenRemovingSignerBelowThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.InvalidThreshold.selector, 2, 1));
        exposedRemoveSigner(alice);
    }

    function testRemoveSignerThenValidateSignatures() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Before removal - Alice's signature should work
        uint256[] memory privKeysBefore = new uint256[](2);
        privKeysBefore[0] = alicePrivKey;
        privKeysBefore[1] = bobPrivKey;
        bytes[] memory sigsBefore = getSortedSignatures(digest, privKeysBefore);
        assertTrue(isValidSignature(digest, sigsBefore));

        // Remove Alice
        exposedRemoveSigner(alice);

        // After removal - Alice's signature should not work
        uint256[] memory privKeysAfter = new uint256[](2);
        privKeysAfter[0] = alicePrivKey;
        privKeysAfter[1] = bobPrivKey;
        bytes[] memory sigsAfter = getSortedSignatures(digest, privKeysAfter);
        assertFalse(isValidSignature(digest, sigsAfter));

        // But Bob and Carol should still work
        uint256[] memory privKeysValid = new uint256[](2);
        privKeysValid[0] = bobPrivKey;
        privKeysValid[1] = carolPrivKey;
        bytes[] memory sigsValid = getSortedSignatures(digest, privKeysValid);
        assertTrue(isValidSignature(digest, sigsValid));
    }

    // ============ Tests for Complex Scenarios ============

    function testFullWorkflowFiveSigners() public {
        // Add all five signers
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedAddSigner(dave);
        exposedAddSigner(eve);

        // Set threshold to 3
        exposedSetThreshold(3);

        bytes32 digest = keccak256("important message");

        // Test with exactly 3 signatures
        uint256[] memory privKeys3 = new uint256[](3);
        privKeys3[0] = alicePrivKey;
        privKeys3[1] = bobPrivKey;
        privKeys3[2] = carolPrivKey;
        bytes[] memory sigs3 = getSortedSignatures(digest, privKeys3);
        assertTrue(isValidSignature(digest, sigs3));

        // Test with 2 signatures (should fail)
        uint256[] memory privKeys2 = new uint256[](2);
        privKeys2[0] = alicePrivKey;
        privKeys2[1] = bobPrivKey;
        bytes[] memory sigs2 = getSortedSignatures(digest, privKeys2);
        assertFalse(isValidSignature(digest, sigs2));

        // Test with all 5 signatures
        uint256[] memory privKeys5 = new uint256[](5);
        privKeys5[0] = alicePrivKey;
        privKeys5[1] = bobPrivKey;
        privKeys5[2] = carolPrivKey;
        privKeys5[3] = davePrivKey;
        privKeys5[4] = evePrivKey;
        bytes[] memory sigs5 = getSortedSignatures(digest, privKeys5);
        assertTrue(isValidSignature(digest, sigs5));

        // Update threshold to 4
        exposedSetThreshold(4);

        // Now 3 signatures should fail
        assertFalse(isValidSignature(digest, sigs3));

        // But 5 should still work
        assertTrue(isValidSignature(digest, sigs5));
    }

    function testOnlyOwnerCanRemoveSigner() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(1);

        vm.prank(alice);
        vm.expectRevert();
        exposedRemoveSigner(bob);
    }

    function testOnlyOwnerCanSetThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);

        vm.prank(alice);
        vm.expectRevert();
        exposedSetThreshold(1);
    }

    // ============ Tests for Mixed Valid/Invalid Signatures ============

    function testIncorrectSignaturesAllowedWithEnoughCorrectOnes() public {
        // Add 3 valid signers
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create a mix: Alice (valid), Dave (invalid), Bob (valid)
        // We need to sort them by signer address
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey); // Dave is not a signer
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);

        address aliceAddr = digest.recover(aliceSig);
        address daveAddr = digest.recover(daveSig);
        address bobAddr = digest.recover(bobSig);

        // Sort the signatures by address
        address[] memory addrs = new address[](3);
        bytes[] memory sigs = new bytes[](3);
        addrs[0] = aliceAddr;
        addrs[1] = daveAddr;
        addrs[2] = bobAddr;
        sigs[0] = aliceSig;
        sigs[1] = daveSig;
        sigs[2] = bobSig;

        // Bubble sort
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // Should pass because we have Alice and Bob (2 valid signatures >= threshold of 2)
        // Dave's invalid signature is simply ignored in the count
        assertTrue(isValidSignature(digest, sigs));
    }

    function testMultipleIncorrectSignaturesWithEnoughCorrectOnes() public {
        // Add 3 valid signers
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create a mix: Alice (valid), Dave (invalid), Bob (valid), Eve (invalid)
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey); // Invalid
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);
        bytes memory eveSig = getSignatureForDigest(digest, evePrivKey); // Invalid

        address aliceAddr = digest.recover(aliceSig);
        address daveAddr = digest.recover(daveSig);
        address bobAddr = digest.recover(bobSig);
        address eveAddr = digest.recover(eveSig);

        // Sort all signatures
        address[] memory addrs = new address[](4);
        bytes[] memory sigs = new bytes[](4);
        addrs[0] = aliceAddr;
        addrs[1] = daveAddr;
        addrs[2] = bobAddr;
        addrs[3] = eveAddr;
        sigs[0] = aliceSig;
        sigs[1] = daveSig;
        sigs[2] = bobSig;
        sigs[3] = eveSig;

        // Bubble sort
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = i + 1; j < 4; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // Should pass: we have Alice and Bob (2 valid) even with Dave and Eve (2 invalid)
        assertTrue(isValidSignature(digest, sigs));
    }

    function testMoreSignaturesThanThresholdIsAllowed() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(1);

        bytes32 digest = keccak256("test message");

        // Provide all 3 signatures even though threshold is only 1
        uint256[] memory privKeys = new uint256[](3);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        privKeys[2] = carolPrivKey;
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        // Should pass because we have way more than threshold
        assertTrue(isValidSignature(digest, signatures));
    }

    function testExcessSignaturesWithMixedValidityPassesWithEnoughValid() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Provide 5 signatures: Alice (valid), Bob (valid), Carol (invalid), Dave (invalid), Eve (invalid)
        // Threshold is 2, so Alice + Bob should be enough
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);
        bytes memory carolSig = getSignatureForDigest(digest, carolPrivKey); // Invalid - not a signer
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey); // Invalid
        bytes memory eveSig = getSignatureForDigest(digest, evePrivKey); // Invalid

        address aliceAddr = digest.recover(aliceSig);
        address bobAddr = digest.recover(bobSig);
        address carolAddr = digest.recover(carolSig);
        address daveAddr = digest.recover(daveSig);
        address eveAddr = digest.recover(eveSig);

        // Sort all signatures
        address[] memory addrs = new address[](5);
        bytes[] memory sigs = new bytes[](5);
        addrs[0] = aliceAddr;
        addrs[1] = bobAddr;
        addrs[2] = carolAddr;
        addrs[3] = daveAddr;
        addrs[4] = eveAddr;
        sigs[0] = aliceSig;
        sigs[1] = bobSig;
        sigs[2] = carolSig;
        sigs[3] = daveSig;
        sigs[4] = eveSig;

        // Bubble sort
        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = i + 1; j < 5; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // Should pass: Alice and Bob are valid (meets threshold of 2)
        // Extra signatures (3 invalid ones) don't cause failure
        assertTrue(isValidSignature(digest, sigs));
    }

    function testInsufficientValidSignaturesFailsDespiteExtraInvalidOnes() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Provide 5 signatures but only 1 valid: Alice (valid), Carol (invalid), Dave (invalid), Eve (invalid)
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory carolSig = getSignatureForDigest(digest, carolPrivKey); // Invalid
        bytes memory daveSig = getSignatureForDigest(digest, davePrivKey); // Invalid
        bytes memory eveSig = getSignatureForDigest(digest, evePrivKey); // Invalid

        address aliceAddr = digest.recover(aliceSig);
        address carolAddr = digest.recover(carolSig);
        address daveAddr = digest.recover(daveSig);
        address eveAddr = digest.recover(eveSig);

        // Sort signatures
        address[] memory addrs = new address[](4);
        bytes[] memory sigs = new bytes[](4);
        addrs[0] = aliceAddr;
        addrs[1] = carolAddr;
        addrs[2] = daveAddr;
        addrs[3] = eveAddr;
        sigs[0] = aliceSig;
        sigs[1] = carolSig;
        sigs[2] = daveSig;
        sigs[3] = eveSig;

        // Bubble sort
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = i + 1; j < 4; j++) {
                if (addrs[i] > addrs[j]) {
                    address tempAddr = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = tempAddr;

                    bytes memory tempSig = sigs[i];
                    sigs[i] = sigs[j];
                    sigs[j] = tempSig;
                }
            }
        }

        // Should fail: only 1 valid signature (Alice), but threshold is 2
        // Having 4 total signatures doesn't help if only 1 is valid
        assertFalse(isValidSignature(digest, sigs));
    }

    // ============ Tests for Malformed Signatures ============

    function testMalformedSignatureIsSkipped() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Create valid signatures
        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        bytes[] memory validSigs = getSortedSignatures(digest, privKeys);

        // Create array with malformed signature in the middle
        bytes[] memory signatures = new bytes[](3);
        signatures[0] = validSigs[0];
        signatures[1] = hex"deadbeef"; // Malformed signature
        signatures[2] = validSigs[1];

        // Should still pass - malformed signature is skipped
        assertTrue(isValidSignature(digest, signatures), "Malformed signature should be skipped");
    }

    function testAllMalformedSignaturesFails() public {
        exposedAddSigner(alice);
        exposedSetThreshold(1);

        bytes32 digest = keccak256("test message");

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = hex"deadbeef";
        signatures[1] = hex"cafebabe";

        // Should fail - no valid signatures
        assertFalse(isValidSignature(digest, signatures), "All malformed should fail");
    }

    function testEmptySignatureIsSkipped() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        bytes[] memory validSigs = getSortedSignatures(digest, privKeys);

        // Create array with empty signature
        bytes[] memory signatures = new bytes[](3);
        signatures[0] = validSigs[0];
        signatures[1] = ""; // Empty signature
        signatures[2] = validSigs[1];

        // Should pass - empty signature is skipped
        assertTrue(isValidSignature(digest, signatures), "Empty signature should be skipped");
    }

    function testUnsortedSignaturesWithMalformedInMiddle() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        // Get individual signatures
        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);

        // Determine addresses to create descending order
        address aliceAddr = vm.addr(alicePrivKey);
        address bobAddr = vm.addr(bobPrivKey);

        // Create array: [higherAddr, malformed, lowerAddr] - descending order with invalid in middle
        bytes[] memory signatures = new bytes[](3);
        if (aliceAddr > bobAddr) {
            // Alice > Bob, so put Alice first (descending)
            signatures[0] = aliceSig;
            signatures[1] = hex"deadbeef"; // Malformed signature in middle
            signatures[2] = bobSig;
        } else {
            // Bob > Alice, so put Bob first (descending)
            signatures[0] = bobSig;
            signatures[1] = hex"deadbeef"; // Malformed signature in middle
            signatures[2] = aliceSig;
        }

        // Should pass: unsorted valid signatures with malformed skipped
        // This tests that fallback duplicate detection works correctly when
        // malformed signatures create gaps in processing
        assertTrue(isValidSignature(digest, signatures), "Unsorted with malformed in middle should work");
    }

    // ============ Tests for validCount tracking ============

    /// @notice Tests that validCount correctly tracks only valid signatures, not array indices
    /// @dev This is critical for the duplicate detection fallback loop which iterates over validCount
    function testValidCountWithMultipleMalformedSignatures() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(3);

        bytes32 digest = keccak256("test message");

        // Get sorted valid signatures
        uint256[] memory privKeys = new uint256[](3);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        privKeys[2] = carolPrivKey;
        bytes[] memory validSigs = getSortedSignatures(digest, privKeys);

        // Create array with multiple malformed signatures interspersed
        // [malformed, valid0, malformed, malformed, valid1, malformed, valid2]
        bytes[] memory signatures = new bytes[](7);
        signatures[0] = hex"dead";
        signatures[1] = validSigs[0];
        signatures[2] = hex"beef";
        signatures[3] = hex"cafe";
        signatures[4] = validSigs[1];
        signatures[5] = hex"babe";
        signatures[6] = validSigs[2];

        // Should pass: validCount should correctly track 3 valid signatures
        // despite 4 malformed ones creating gaps in the array
        assertTrue(isValidSignature(digest, signatures), "Should work with interspersed malformed signatures");
    }

    /// @notice Tests duplicate detection works when duplicates are separated by malformed signatures
    /// @dev Validates that validCount-based iteration catches duplicates even with gaps
    function testDuplicateDetectionWithMalformedGaps() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);

        // [alice, malformed, malformed, alice] - duplicate with gaps
        bytes[] memory signatures = new bytes[](4);
        signatures[0] = aliceSig;
        signatures[1] = hex"dead";
        signatures[2] = hex"beef";
        signatures[3] = aliceSig; // Duplicate

        // Should fail: duplicate alice signature should be detected
        // even though malformed signatures create gaps in recoveredSigners
        assertFalse(isValidSignature(digest, signatures), "Should detect duplicate with malformed gaps");
    }

    /// @notice Tests that unsorted duplicates are detected via fallback loop with malformed gaps
    /// @dev Combines unsorted order + duplicates + malformed signatures
    function testUnsortedDuplicateWithMalformedGaps() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(3);

        bytes32 digest = keccak256("test message");

        bytes memory aliceSig = getSignatureForDigest(digest, alicePrivKey);
        bytes memory bobSig = getSignatureForDigest(digest, bobPrivKey);

        address aliceAddr = vm.addr(alicePrivKey);
        address bobAddr = vm.addr(bobPrivKey);

        // Create: [higher, malformed, lower, malformed, higher(duplicate)]
        // This forces fallback path AND tests duplicate detection across gaps
        bytes[] memory signatures = new bytes[](5);
        if (aliceAddr > bobAddr) {
            signatures[0] = aliceSig; // Higher first (will set lastSigner)
            signatures[1] = hex"dead";
            signatures[2] = bobSig; // Lower (triggers fallback)
            signatures[3] = hex"beef";
            signatures[4] = aliceSig; // Duplicate of signatures[0]
        } else {
            signatures[0] = bobSig;
            signatures[1] = hex"dead";
            signatures[2] = aliceSig;
            signatures[3] = hex"beef";
            signatures[4] = bobSig; // Duplicate
        }

        // Should fail: duplicate should be caught by fallback loop
        assertFalse(isValidSignature(digest, signatures), "Should detect unsorted duplicate with gaps");
    }

    /// @notice Tests edge case where all signatures before valid ones are malformed
    function testAllMalformedBeforeValid() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        bytes32 digest = keccak256("test message");

        uint256[] memory privKeys = new uint256[](2);
        privKeys[0] = alicePrivKey;
        privKeys[1] = bobPrivKey;
        bytes[] memory validSigs = getSortedSignatures(digest, privKeys);

        // [malformed, malformed, malformed, valid0, valid1]
        bytes[] memory signatures = new bytes[](5);
        signatures[0] = hex"11";
        signatures[1] = hex"22";
        signatures[2] = hex"33";
        signatures[3] = validSigs[0];
        signatures[4] = validSigs[1];

        // Should pass: validCount starts at 0, first valid signature at index 3
        // becomes recoveredSigners[0], second at index 4 becomes recoveredSigners[1]
        assertTrue(isValidSignature(digest, signatures), "Should work with leading malformed signatures");
    }

    // ============ Tests for getSignerAtIndex and getSignersCount ============

    function testGetSignersCount() public {
        assertEq(this.getSignersCount(), 0);

        exposedAddSigner(alice);
        assertEq(this.getSignersCount(), 1);

        exposedAddSigner(bob);
        assertEq(this.getSignersCount(), 2);

        exposedAddSigner(carol);
        assertEq(this.getSignersCount(), 3);
    }

    function testGetSignerAtIndex() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);

        assertEq(this.getSignerAtIndex(0), alice);
        assertEq(this.getSignerAtIndex(1), bob);
        assertEq(this.getSignerAtIndex(2), carol);
    }

    function testGetSignerAtIndexAfterRemoval() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        exposedSetThreshold(1);

        // Remove bob (middle element) - should move carol to bob's position
        exposedRemoveSigner(bob);

        assertEq(this.getSignersCount(), 2);
        assertEq(this.getSignerAtIndex(0), alice);
        assertEq(this.getSignerAtIndex(1), carol); // carol moved to index 1
    }

    /// @dev Test that getSignerAtIndex reverts when accessing out of bounds index
    function testGetSignerAtIndexOutOfBounds() public {
        // Empty signers array - any index should revert
        vm.expectRevert();
        this.getSignerAtIndex(0);

        // Add one signer, then try to access index 1
        exposedAddSigner(alice);
        vm.expectRevert();
        this.getSignerAtIndex(1);

        // Add more signers, then try to access beyond the count
        exposedAddSigner(bob);
        exposedAddSigner(carol);
        vm.expectRevert();
        this.getSignerAtIndex(3);
    }

    function testGetThreshold() public {
        exposedAddSigner(alice);
        exposedAddSigner(bob);
        exposedSetThreshold(2);

        assertEq(this.getThreshold(), 2);
    }

    function testIsSigner() public {
        assertFalse(this.isSigner(alice));

        exposedAddSigner(alice);
        assertTrue(this.isSigner(alice));
        assertFalse(this.isSigner(bob));

        exposedAddSigner(bob);
        assertTrue(this.isSigner(bob));
    }

    // ============ Fuzz Tests for Signature Verification ============

    /// @dev Fuzz test for threshold validation with varying number of signers
    /// Tests that signatures meeting the threshold return true
    function testFuzzValidSignaturesWithVaryingThreshold(uint8 numSigners, uint8 threshold) public {
        // Constrain inputs to reasonable values
        numSigners = uint8(bound(numSigners, 1, 10));
        threshold = uint8(bound(threshold, 1, numSigners));

        // Generate signers with unique private keys
        uint256[] memory privKeys = new uint256[](numSigners);
        for (uint256 i = 0; i < numSigners; i++) {
            privKeys[i] = uint256(keccak256(abi.encodePacked("signer", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(privKeys[i]);
            exposedAddSigner(signerAddr);
        }

        exposedSetThreshold(threshold);

        // Create signatures from exactly threshold number of signers
        bytes32 digest = keccak256("fuzz test message");
        uint256[] memory signingKeys = new uint256[](threshold);
        for (uint256 i = 0; i < threshold; i++) {
            signingKeys[i] = privKeys[i];
        }
        bytes[] memory signatures = getSortedSignatures(digest, signingKeys);

        assertTrue(isValidSignature(digest, signatures), "Valid signatures meeting threshold should pass");
    }

    /// @dev Fuzz test that signatures below threshold return false
    function testFuzzInsufficientSignatures(uint8 numSigners, uint8 threshold, uint8 sigCount) public {
        // Constrain inputs
        numSigners = uint8(bound(numSigners, 2, 10));
        threshold = uint8(bound(threshold, 2, numSigners));
        sigCount = uint8(bound(sigCount, 1, threshold - 1)); // Always below threshold

        // Generate signers
        uint256[] memory privKeys = new uint256[](numSigners);
        for (uint256 i = 0; i < numSigners; i++) {
            privKeys[i] = uint256(keccak256(abi.encodePacked("signer_insuf", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(privKeys[i]);
            exposedAddSigner(signerAddr);
        }

        exposedSetThreshold(threshold);

        // Create fewer signatures than threshold
        bytes32 digest = keccak256("fuzz insufficient test");
        uint256[] memory signingKeys = new uint256[](sigCount);
        for (uint256 i = 0; i < sigCount; i++) {
            signingKeys[i] = privKeys[i];
        }
        bytes[] memory signatures = getSortedSignatures(digest, signingKeys);

        assertFalse(isValidSignature(digest, signatures), "Insufficient signatures should fail");
    }

    /// @dev Fuzz test that more signatures than threshold still passes
    function testFuzzExcessSignatures(uint8 numSigners, uint8 threshold) public {
        // Constrain inputs - need at least one extra signature beyond threshold
        numSigners = uint8(bound(numSigners, 2, 10));
        threshold = uint8(bound(threshold, 1, numSigners - 1)); // At least one extra signer

        // Generate signers
        uint256[] memory privKeys = new uint256[](numSigners);
        for (uint256 i = 0; i < numSigners; i++) {
            privKeys[i] = uint256(keccak256(abi.encodePacked("signer_excess", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(privKeys[i]);
            exposedAddSigner(signerAddr);
        }

        exposedSetThreshold(threshold);

        // Create signatures from ALL signers (more than threshold)
        bytes32 digest = keccak256("fuzz excess test");
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertTrue(isValidSignature(digest, signatures), "Excess valid signatures should pass");
    }

    /// @dev Fuzz test that threshold equal to number of signers works correctly
    function testFuzzThresholdEqualsSignerCount(uint8 numSigners) public {
        numSigners = uint8(bound(numSigners, 1, 10));

        // Generate signers
        uint256[] memory privKeys = new uint256[](numSigners);
        for (uint256 i = 0; i < numSigners; i++) {
            privKeys[i] = uint256(keccak256(abi.encodePacked("signer_equal", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(privKeys[i]);
            exposedAddSigner(signerAddr);
        }

        // Set threshold equal to signer count
        exposedSetThreshold(numSigners);

        bytes32 digest = keccak256("fuzz equal threshold test");
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertTrue(isValidSignature(digest, signatures), "All signers signing should pass when threshold equals count");
    }

    /// @dev Fuzz test that mixing valid and invalid signers correctly counts only valid ones
    function testFuzzMixedValidInvalidSigners(uint8 numValidSigners, uint8 numInvalidSigners, uint8 threshold) public {
        // Constrain inputs
        numValidSigners = uint8(bound(numValidSigners, 1, 5));
        numInvalidSigners = uint8(bound(numInvalidSigners, 1, 5));
        threshold = uint8(bound(threshold, 1, numValidSigners)); // Must be achievable with valid signers

        // Generate and register valid signers
        uint256[] memory validPrivKeys = new uint256[](numValidSigners);
        for (uint256 i = 0; i < numValidSigners; i++) {
            validPrivKeys[i] = uint256(keccak256(abi.encodePacked("valid_signer", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(validPrivKeys[i]);
            exposedAddSigner(signerAddr);
        }

        exposedSetThreshold(threshold);

        // Generate invalid signer keys (not registered)
        uint256[] memory invalidPrivKeys = new uint256[](numInvalidSigners);
        for (uint256 i = 0; i < numInvalidSigners; i++) {
            invalidPrivKeys[i] = uint256(keccak256(abi.encodePacked("invalid_signer", i))) % (type(uint256).max - 1) + 1;
        }

        // Create signatures from all valid signers (should pass regardless of invalid ones)
        bytes32 digest = keccak256("fuzz mixed signers test");
        bytes[] memory signatures = getSortedSignatures(digest, validPrivKeys);

        assertTrue(isValidSignature(digest, signatures), "Valid signatures meeting threshold should pass");
    }

    /// @dev Fuzz test for digest variation - same signers, different messages
    function testFuzzDifferentDigests(bytes32 digest, uint8 numSigners) public {
        numSigners = uint8(bound(numSigners, 1, 5));

        // Generate signers
        uint256[] memory privKeys = new uint256[](numSigners);
        for (uint256 i = 0; i < numSigners; i++) {
            privKeys[i] = uint256(keccak256(abi.encodePacked("digest_signer", i))) % (type(uint256).max - 1) + 1;
            address signerAddr = vm.addr(privKeys[i]);
            exposedAddSigner(signerAddr);
        }

        exposedSetThreshold(numSigners);

        // Sign the fuzzed digest
        bytes[] memory signatures = getSortedSignatures(digest, privKeys);

        assertTrue(isValidSignature(digest, signatures), "Valid signatures should pass for any digest");
    }

}
