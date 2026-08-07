// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {BaseAccessControlList} from "../BaseAccessControlList.sol";
import {VerifierAddressGetter} from "../../primitives/VerifierAddressGetter.sol";
import {euint256, inco} from "../../../Lib.sol";
import {SenderNotAllowedForHandle} from "../../../Types.sol";
import {IncoTest} from "../../../test/IncoTest.sol";

contract TestBaseAccessControl is BaseAccessControlList, IncoTest {

    constructor() VerifierAddressGetter(address(0)) {}

    function testHandleZeroIsDisallowed() public view {
        bytes32 handle = bytes32(0);
        assert(!isAllowed(handle, alice));
    }

    function testReveal() public {
        euint256 secret = inco.asEuint256(1337);
        assert(inco.isAllowed(euint256.unwrap(secret), address(this)));
        assert(!inco.isAllowed(euint256.unwrap(secret), alice));

        inco.reveal(euint256.unwrap(secret));
        assert(inco.isAllowed(euint256.unwrap(secret), address(this)));
        assert(inco.isAllowed(euint256.unwrap(secret), alice));
    }

    // ============ allowTransient Tests ============

    function testAllowTransient() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Initially bob is not allowed
        assertFalse(inco.isAllowed(handle, bob));

        // Allow transient access from this contract (which is allowed)
        inco.allowTransient(handle, bob);

        // Bob should now have transient access
        assertTrue(inco.allowedTransient(handle, bob));
        assertTrue(inco.isAllowed(handle, bob));
    }

    function testAllowTransient_RevertsWhenSenderNotAllowed() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Try to allow transient from an account that doesn't have access
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, handle, bob));
        inco.allowTransient(handle, carol);
    }

    // ============ allowedTransient Direct Call Tests ============

    function testAllowedTransient_DirectCall() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Direct call should return false initially
        assertFalse(inco.allowedTransient(handle, bob));

        // After allowing, direct call should return true
        inco.allowTransient(handle, bob);
        assertTrue(inco.allowedTransient(handle, bob));
    }

    // ============ isRevealed Direct Call Tests ============

    function testIsRevealed_DirectCall() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Direct call should return false initially
        assertFalse(inco.isRevealed(handle));

        // After reveal, direct call should return true
        inco.reveal(handle);
        assertTrue(inco.isRevealed(handle));
    }

    // ============ allow Revert Tests ============

    function testAllow_RevertsWhenSenderNotAllowed() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Try to allow from an account that doesn't have access
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, handle, bob));
        inco.allow(handle, carol);
    }

    // ============ reveal Revert Tests ============

    function testReveal_RevertsWhenSenderNotAllowed() public {
        euint256 secret = inco.asEuint256(42);
        bytes32 handle = euint256.unwrap(secret);

        // Try to reveal from an account that doesn't have access
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, handle, bob));
        inco.reveal(handle);
    }

    // ============ Fuzz Tests for isAllowed ============

    /// @dev Fuzz test that isAllowed returns true when handle is revealed (regardless of account)
    function testFuzzIsAllowedWhenRevealed(bytes32 randomSeed, address randomAccount) public {
        vm.assume(randomAccount != address(0));

        // Create a unique handle using the random seed
        euint256 secret = inco.asEuint256(uint256(randomSeed));
        bytes32 handle = euint256.unwrap(secret);

        // Initially, random account should not have access (unless it's this contract)
        if (randomAccount != address(this)) {
            assertFalse(inco.isAllowed(handle, randomAccount));
        }

        // Reveal the handle
        inco.reveal(handle);

        // Now any account should have access
        assertTrue(inco.isAllowed(handle, randomAccount));
        assertTrue(inco.isRevealed(handle));
    }

    /// @dev Fuzz test that isAllowed returns true when persistAllowed is set
    function testFuzzIsAllowedWhenPersisted(bytes32 randomSeed, address allowedAccount) public {
        vm.assume(allowedAccount != address(0));
        vm.assume(allowedAccount != address(this));

        // Create a unique handle
        euint256 secret = inco.asEuint256(uint256(randomSeed));
        bytes32 handle = euint256.unwrap(secret);

        // Initially not allowed
        assertFalse(inco.isAllowed(handle, allowedAccount));

        // Allow the account (from this contract which has access)
        inco.allow(handle, allowedAccount);

        // Now should be allowed
        assertTrue(inco.isAllowed(handle, allowedAccount));
        assertTrue(inco.persistAllowed(handle, allowedAccount));
    }

    /// @dev Fuzz test that isAllowed returns true when transient access is granted
    function testFuzzIsAllowedWhenTransient(bytes32 randomSeed, address allowedAccount) public {
        vm.assume(allowedAccount != address(0));
        vm.assume(allowedAccount != address(this));

        // Create a unique handle
        euint256 secret = inco.asEuint256(uint256(randomSeed));
        bytes32 handle = euint256.unwrap(secret);

        // Initially not allowed
        assertFalse(inco.isAllowed(handle, allowedAccount));

        // Allow transient access
        inco.allowTransient(handle, allowedAccount);

        // Should be allowed via transient
        assertTrue(inco.isAllowed(handle, allowedAccount));
        assertTrue(inco.allowedTransient(handle, allowedAccount));
        // But not persisted
        assertFalse(inco.persistAllowed(handle, allowedAccount));
    }

    /// @dev Fuzz test the OR logic: isAllowed = transient OR persisted OR revealed
    function testFuzzIsAllowedOrLogic(bytes32 randomSeed, uint8 accessMode) public {
        // Create a unique handle
        euint256 secret = inco.asEuint256(uint256(randomSeed));
        bytes32 handle = euint256.unwrap(secret);

        // accessMode determines which access type to grant:
        // 0 = none, 1 = transient, 2 = persisted, 3 = revealed, 4+ = combinations
        uint8 mode = accessMode % 8;

        bool grantTransient = (mode & 1) != 0;
        bool grantPersisted = (mode & 2) != 0;
        bool grantRevealed = (mode & 4) != 0;

        // Initially bob has no access
        assertFalse(inco.isAllowed(handle, bob));

        // Grant access based on mode
        if (grantTransient) {
            inco.allowTransient(handle, bob);
        }
        if (grantPersisted) {
            inco.allow(handle, bob);
        }
        if (grantRevealed) {
            inco.reveal(handle);
        }

        // isAllowed should be true if ANY access was granted
        bool expectedAllowed = grantTransient || grantPersisted || grantRevealed;
        assertEq(inco.isAllowed(handle, bob), expectedAllowed);
    }

    /// @dev Fuzz test multiple accounts with different access levels
    function testFuzzMultipleAccountsAccessLevels(bytes32 randomSeed) public {
        euint256 secret = inco.asEuint256(uint256(randomSeed));
        bytes32 handle = euint256.unwrap(secret);

        // Grant different access types to different accounts
        inco.allowTransient(handle, bob);
        inco.allow(handle, carol);
        // dave gets no access

        // Verify access levels
        assertTrue(inco.isAllowed(handle, bob));
        assertTrue(inco.allowedTransient(handle, bob));
        assertFalse(inco.persistAllowed(handle, bob));

        assertTrue(inco.isAllowed(handle, carol));
        assertFalse(inco.allowedTransient(handle, carol));
        assertTrue(inco.persistAllowed(handle, carol));

        assertFalse(inco.isAllowed(handle, dave));
        assertFalse(inco.allowedTransient(handle, dave));
        assertFalse(inco.persistAllowed(handle, dave));
    }

}
