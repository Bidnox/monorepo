// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "./IncoTest.sol";
import {e, euint256, ebool, eaddress, inco} from "../Lib.sol";
import {FEE} from "../lightning-parts/Fee.sol";
import {
    ETypes,
    elist,
    HandleMismatch,
    IndexOutOfRange,
    InvalidRange,
    InvalidTEEAttestation,
    SliceOutOfRange,
    UnexpectedDecryptedValue,
    UnsupportedListType,
    UnsupportedType
} from "../Types.sol";
import {EncryptedOperations} from "../lightning-parts/EncryptedOperations.sol";
import {DecryptionAttestation, ElementAttestationWithProof} from "../lightning-parts/DecryptionAttester.types.sol";

/// @notice Wrapper to expose internal requireEqual as an external call so vm.expectRevert works
contract RequireEqualCaller {

    function callEbool(ebool handle, bool expected, DecryptionAttestation memory decryption, bytes[] memory signatures)
        external
        view
    {
        e.requireEqual(handle, expected, decryption, signatures);
    }

    function callEuint256(
        euint256 handle,
        uint256 expected,
        DecryptionAttestation memory decryption,
        bytes[] memory signatures
    ) external view {
        e.requireEqual(handle, expected, decryption, signatures);
    }

}

/// @notice Tests for Lib.sol library functions to achieve 100% coverage
/// @dev This file tests all the scalar variants and uncovered branches in the library
contract TestLib is IncoTest {

    using e for euint256;
    using e for ebool;
    using e for uint256;
    using e for bool;
    using e for address;
    using e for eaddress;
    using e for bytes;
    using e for elist;

    function setUp() public virtual override {
        super.setUp();
        vm.deal(address(this), 100 ether);
    }

    // ============ ELIST FEE HELPERS ============

    function _listRange(uint16 start, uint16 end, ETypes listType) internal returns (elist) {
        return inco.listRange{value: inco.getEListFee(end - start, listType)}(start, end, listType);
    }

    function _newEList(bytes32[] memory handles, ETypes listType) internal returns (elist) {
        return inco.newEList{value: inco.getEListFee(uint16(handles.length), listType)}(handles, listType);
    }

    function _listAppend(elist list, bytes32 value) internal returns (elist) {
        return inco.listAppend{value: inco.getEListFee(e.length(list) + 1, e.listTypeOf(list))}(list, value);
    }

    function _listConcat(elist a, elist b) internal returns (elist) {
        return inco.listConcat{value: inco.getEListFee(e.length(a) + e.length(b), e.listTypeOf(a))}(a, b);
    }

    function _listReverse(elist list) internal returns (elist) {
        return inco.listReverse{value: inco.getEListFee(e.length(list), e.listTypeOf(list))}(list);
    }

    // ============ SANITIZE BRANCH TESTS ============

    function testSanitizeEuint256Zero() public {
        // Test sanitize with zero handle - should return asEuint256(0)
        euint256 zero = euint256.wrap(bytes32(0));
        euint256 sanitized = e.s(zero);
        processAllOperations();
        // After sanitize, a zero handle should become a valid encrypted 0
        assertEq(getUint256Value(sanitized), 0);
    }

    function testSanitizeEboolZero() public {
        // Test sanitize with zero handle - should return asEbool(false)
        ebool zero = ebool.wrap(bytes32(0));
        ebool sanitized = e.s(zero);
        processAllOperations();
        // After sanitize, a zero handle should become a valid encrypted false
        assertEq(getBoolValue(sanitized), false);
    }

    function testSanitizeEaddress() public {
        // Test sanitize(eaddress) with non-zero - just returns input
        eaddress addr = e.asEaddress(address(0xdeadbeef));
        processAllOperations();
        eaddress sanitized = e.s(addr);
        processAllOperations();
        assertEq(getAddressValue(sanitized), address(0xdeadbeef));
    }

    function testSanitizeEaddressZero() public {
        // Test sanitize with zero handle - should return asEaddress(0)
        eaddress zero = eaddress.wrap(bytes32(0));
        eaddress sanitized = e.s(zero);
        processAllOperations();
        // After sanitize, a zero handle should become a valid encrypted address(0)
        assertEq(getAddressValue(sanitized), address(0));
    }

    // ============ SUB SCALAR VARIANTS ============

    function testSubEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        euint256 c = a.sub(uint256(4));
        processAllOperations();
        assertEq(getUint256Value(c), 6);
    }

    function testSubUint256Euint256() public {
        euint256 b = e.asEuint256(4);
        euint256 c = uint256(10).sub(b);
        processAllOperations();
        assertEq(getUint256Value(c), 6);
    }

    // ============ MUL SCALAR VARIANTS ============

    function testMulEuint256Uint256() public {
        euint256 a = e.asEuint256(5);
        euint256 c = a.mul(uint256(3));
        processAllOperations();
        assertEq(getUint256Value(c), 15);
    }

    function testMulUint256Euint256() public {
        euint256 b = e.asEuint256(3);
        euint256 c = uint256(5).mul(b);
        processAllOperations();
        assertEq(getUint256Value(c), 15);
    }

    // ============ DIV SCALAR VARIANTS ============

    function testDivEuint256Uint256() public {
        euint256 a = e.asEuint256(20);
        euint256 c = a.div(uint256(4));
        processAllOperations();
        assertEq(getUint256Value(c), 5);
    }

    function testDivUint256Euint256() public {
        euint256 b = e.asEuint256(4);
        euint256 c = uint256(20).div(b);
        processAllOperations();
        assertEq(getUint256Value(c), 5);
    }

    // ============ REM SCALAR VARIANTS ============

    function testRemEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        euint256 c = a.rem(uint256(3));
        processAllOperations();
        assertEq(getUint256Value(c), 1);
    }

    function testRemUint256Euint256() public {
        euint256 b = e.asEuint256(3);
        euint256 c = uint256(10).rem(b);
        processAllOperations();
        assertEq(getUint256Value(c), 1);
    }

    // ============ AND SCALAR/EBOOL VARIANTS ============

    function testAndEuint256Uint256() public {
        euint256 a = e.asEuint256(0xFF);
        euint256 c = a.and(uint256(0x0F));
        processAllOperations();
        assertEq(getUint256Value(c), 0x0F);
    }

    function testAndUint256Euint256() public {
        euint256 b = e.asEuint256(0x0F);
        euint256 c = uint256(0xFF).and(b);
        processAllOperations();
        assertEq(getUint256Value(c), 0x0F);
    }

    function testAndEboolEbool() public {
        ebool a = e.asEbool(true);
        ebool b = e.asEbool(false);
        ebool c = a.and(b);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testAndEboolBool() public {
        ebool a = e.asEbool(true);
        ebool c = a.and(false);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testAndBoolEbool() public {
        ebool b = e.asEbool(true);
        ebool c = true.and(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ OR SCALAR/EBOOL VARIANTS ============

    function testOrEuint256Uint256() public {
        euint256 a = e.asEuint256(0xF0);
        euint256 c = a.or(uint256(0x0F));
        processAllOperations();
        assertEq(getUint256Value(c), 0xFF);
    }

    function testOrUint256Euint256() public {
        euint256 b = e.asEuint256(0x0F);
        euint256 c = uint256(0xF0).or(b);
        processAllOperations();
        assertEq(getUint256Value(c), 0xFF);
    }

    function testOrEboolEbool() public {
        ebool a = e.asEbool(false);
        ebool b = e.asEbool(true);
        ebool c = a.or(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testOrEboolBool() public {
        ebool a = e.asEbool(false);
        ebool c = a.or(true);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testOrBoolEbool() public {
        ebool b = e.asEbool(false);
        ebool c = true.or(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ XOR SCALAR/EBOOL VARIANTS ============

    function testXorEuint256Uint256() public {
        euint256 a = e.asEuint256(0xFF);
        euint256 c = a.xor(uint256(0x0F));
        processAllOperations();
        assertEq(getUint256Value(c), 0xF0);
    }

    function testXorUint256Euint256() public {
        euint256 b = e.asEuint256(0x0F);
        euint256 c = uint256(0xFF).xor(b);
        processAllOperations();
        assertEq(getUint256Value(c), 0xF0);
    }

    function testXorEboolEbool() public {
        ebool a = e.asEbool(true);
        ebool b = e.asEbool(true);
        ebool c = a.xor(b);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testXorEboolBool() public {
        ebool a = e.asEbool(true);
        ebool c = a.xor(false);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testXorBoolEbool() public {
        ebool b = e.asEbool(false);
        ebool c = true.xor(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ SHL SCALAR VARIANTS ============

    function testShlEuint256Uint256() public {
        euint256 a = e.asEuint256(1);
        euint256 c = a.shl(uint256(4));
        processAllOperations();
        assertEq(getUint256Value(c), 16);
    }

    function testShlUint256Euint256() public {
        euint256 b = e.asEuint256(4);
        euint256 c = uint256(1).shl(b);
        processAllOperations();
        assertEq(getUint256Value(c), 16);
    }

    // ============ SHR SCALAR VARIANTS ============

    function testShrEuint256Uint256() public {
        euint256 a = e.asEuint256(16);
        euint256 c = a.shr(uint256(2));
        processAllOperations();
        assertEq(getUint256Value(c), 4);
    }

    function testShrUint256Euint256() public {
        euint256 b = e.asEuint256(2);
        euint256 c = uint256(16).shr(b);
        processAllOperations();
        assertEq(getUint256Value(c), 4);
    }

    // ============ ROTL SCALAR VARIANTS ============

    function testRotlEuint256Uint256() public {
        euint256 a = e.asEuint256(1);
        euint256 c = a.rotl(uint256(4));
        processAllOperations();
        assertEq(getUint256Value(c), 16);
    }

    function testRotlUint256Euint256() public {
        euint256 b = e.asEuint256(4);
        euint256 c = uint256(1).rotl(b);
        processAllOperations();
        assertEq(getUint256Value(c), 16);
    }

    // ============ ROTR SCALAR VARIANTS ============

    function testRotrEuint256Uint256() public {
        euint256 a = e.asEuint256(16);
        euint256 c = a.rotr(uint256(4));
        processAllOperations();
        assertEq(getUint256Value(c), 1);
    }

    function testRotrUint256Euint256() public {
        euint256 b = e.asEuint256(4);
        euint256 c = uint256(16).rotr(b);
        processAllOperations();
        assertEq(getUint256Value(c), 1);
    }

    // ============ EQ SCALAR/EADDRESS VARIANTS ============

    function testEqEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        ebool c = a.eq(uint256(10));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEqUint256Euint256() public {
        euint256 b = e.asEuint256(10);
        ebool c = uint256(10).eq(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEqEaddressAddress() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        ebool c = a.eq(alice);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEqEaddressEaddress() public {
        eaddress a = e.asEaddress(alice);
        eaddress b = e.asEaddress(alice);
        processAllOperations();
        ebool c = a.eq(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEqAddressEaddress() public {
        eaddress b = e.asEaddress(alice);
        processAllOperations();
        ebool c = alice.eq(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ NE SCALAR/EADDRESS VARIANTS ============

    function testNeEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        ebool c = a.ne(uint256(5));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testNeUint256Euint256() public {
        euint256 b = e.asEuint256(5);
        ebool c = uint256(10).ne(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testNeEaddressEaddress() public {
        eaddress a = e.asEaddress(alice);
        eaddress b = e.asEaddress(bob);
        processAllOperations();
        ebool c = a.ne(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testNeEaddressAddress() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        ebool c = a.ne(bob);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testNeAddressEaddress() public {
        eaddress b = e.asEaddress(bob);
        processAllOperations();
        ebool c = alice.ne(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ GE SCALAR VARIANTS ============

    function testGeEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        ebool c = a.ge(uint256(10));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testGeUint256Euint256() public {
        euint256 b = e.asEuint256(5);
        ebool c = uint256(10).ge(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ GT SCALAR VARIANTS ============

    function testGtEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        ebool c = a.gt(uint256(5));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testGtUint256Euint256() public {
        euint256 b = e.asEuint256(5);
        ebool c = uint256(10).gt(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ LE SCALAR VARIANTS ============

    function testLeEuint256Uint256() public {
        euint256 a = e.asEuint256(5);
        ebool c = a.le(uint256(10));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testLeUint256Euint256() public {
        euint256 b = e.asEuint256(10);
        ebool c = uint256(5).le(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ LT SCALAR VARIANTS ============

    function testLtEuint256Uint256() public {
        euint256 a = e.asEuint256(5);
        ebool c = a.lt(uint256(10));
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testLtUint256Euint256() public {
        euint256 b = e.asEuint256(10);
        ebool c = uint256(5).lt(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    // ============ MIN SCALAR VARIANTS ============

    function testMinEuint256Uint256() public {
        euint256 a = e.asEuint256(10);
        euint256 c = a.min(uint256(5));
        processAllOperations();
        assertEq(getUint256Value(c), 5);
    }

    function testMinUint256Euint256() public {
        euint256 b = e.asEuint256(5);
        euint256 c = uint256(10).min(b);
        processAllOperations();
        assertEq(getUint256Value(c), 5);
    }

    // ============ MAX SCALAR VARIANTS ============

    function testMaxEuint256Uint256() public {
        euint256 a = e.asEuint256(5);
        euint256 c = a.max(uint256(10));
        processAllOperations();
        assertEq(getUint256Value(c), 10);
    }

    function testMaxUint256Euint256() public {
        euint256 b = e.asEuint256(10);
        euint256 c = uint256(5).max(b);
        processAllOperations();
        assertEq(getUint256Value(c), 10);
    }

    // ============ NEW ENCRYPTED TYPE (msg.sender variant) ============

    function testNewEuint256MsgSender() public {
        // Use a helper contract to test the msg.sender variant
        LibTestHelper helper = new LibTestHelper();
        vm.deal(address(helper), 1 ether);

        bytes memory ciphertext = fakePrepareEuint256Ciphertext(42, address(helper), address(helper));
        vm.prank(address(helper));
        helper.callNewEuint256(ciphertext);
        processAllOperations();

        assertEq(getUint256Value(helper.storedEuint256()), 42);
    }

    function testNewEboolMsgSender() public {
        LibTestHelper helper = new LibTestHelper();
        vm.deal(address(helper), 1 ether);

        bytes memory ciphertext = fakePrepareEboolCiphertext(true, address(helper), address(helper));
        vm.prank(address(helper));
        helper.callNewEbool(ciphertext);
        processAllOperations();

        assertEq(getBoolValue(helper.storedEbool()), true);
    }

    function testNewEaddressMsgSender() public {
        LibTestHelper helper = new LibTestHelper();
        vm.deal(address(helper), 1 ether);

        bytes memory ciphertext = fakePrepareEaddressCiphertext(alice, address(helper), address(helper));
        vm.prank(address(helper));
        helper.callNewEaddress(ciphertext);
        processAllOperations();

        assertEq(getAddressValue(helper.storedEaddress()), alice);
    }

    // ============ ALLOW/REVEAL VARIANTS ============
    // Note: When creating encrypted values (e.g., e.asEbool()), the caller (msg.sender)
    // automatically receives TRANSIENT access via allowTransientInternal().
    // isAllowed() returns true if transient OR persistent access is granted.
    // The allow/allowThis functions grant PERSISTENT access (stored in contract storage).
    // These tests verify persistent access by checking persistAllowed().

    function testAllowEbool() public {
        ebool a = e.asEbool(true);
        processAllOperations();
        // Creator has transient access but not persistent access
        assertFalse(inco.persistAllowed(ebool.unwrap(a), alice));
        e.allow(a, alice);
        assertTrue(inco.persistAllowed(ebool.unwrap(a), alice));
    }

    function testAllowEaddress() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        assertFalse(inco.persistAllowed(eaddress.unwrap(a), bob));
        e.allow(a, bob);
        assertTrue(inco.persistAllowed(eaddress.unwrap(a), bob));
    }

    function testRevealEuint256() public {
        euint256 a = e.asEuint256(42);
        processAllOperations();
        assertFalse(inco.isRevealed(euint256.unwrap(a)));
        e.reveal(a);
        assertTrue(inco.isRevealed(euint256.unwrap(a)));
    }

    function testRevealEbool() public {
        ebool a = e.asEbool(true);
        processAllOperations();
        assertFalse(inco.isRevealed(ebool.unwrap(a)));
        e.reveal(a);
        assertTrue(inco.isRevealed(ebool.unwrap(a)));
    }

    function testRevealEaddress() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        assertFalse(inco.isRevealed(eaddress.unwrap(a)));
        e.reveal(a);
        assertTrue(inco.isRevealed(eaddress.unwrap(a)));
    }

    function testAllowThisEbool() public {
        ebool a = e.asEbool(true);
        processAllOperations();
        // Creator has transient access but not persistent access yet
        assertFalse(inco.persistAllowed(ebool.unwrap(a), address(this)));
        e.allowThis(a);
        assertTrue(inco.persistAllowed(ebool.unwrap(a), address(this)));
    }

    function testAllowThisEaddress() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        // Creator has transient access but not persistent access yet
        assertFalse(inco.persistAllowed(eaddress.unwrap(a), address(this)));
        e.allowThis(a);
        assertTrue(inco.persistAllowed(eaddress.unwrap(a), address(this)));
    }

    function testAllowElist() public {
        elist list = _listRange(0, 3, ETypes.Uint256);
        assertFalse(inco.persistAllowed(elist.unwrap(list), alice));
        e.allow(list, alice);
        assertTrue(inco.persistAllowed(elist.unwrap(list), alice));
    }

    function testRevealElist() public {
        elist list = _listRange(0, 3, ETypes.Uint256);
        assertFalse(inco.isRevealed(elist.unwrap(list)));
        e.reveal(list);
        assertTrue(inco.isRevealed(elist.unwrap(list)));
    }

    function testAllowThisElist() public {
        elist list = _listRange(0, 3, ETypes.Uint256);
        assertFalse(inco.persistAllowed(elist.unwrap(list), address(this)));
        e.allowThis(list);
        assertTrue(inco.persistAllowed(elist.unwrap(list), address(this)));
    }

    function testIsAllowed() public {
        euint256 a = e.asEuint256(42);
        processAllOperations();
        e.allow(a, alice);
        // isAllowed should return true for allowed address
        bool allowed = e.isAllowed(alice, a);
        assertTrue(allowed);
    }

    // ============ SELECT VARIANTS ============

    function testSelectEboolEboolEbool() public {
        ebool control = e.asEbool(true);
        ebool ifTrue = e.asEbool(true);
        ebool ifFalse = e.asEbool(false);
        ebool result = control.select(ifTrue, ifFalse);
        processAllOperations();
        assertEq(getBoolValue(result), true);
    }

    function testSelectEboolEaddressEaddress() public {
        ebool control = e.asEbool(false);
        eaddress ifTrue = e.asEaddress(alice);
        eaddress ifFalse = e.asEaddress(bob);
        processAllOperations();
        eaddress result = control.select(ifTrue, ifFalse);
        processAllOperations();
        assertEq(getAddressValue(result), bob);
    }

    // ============ SELECT WITH EUINT256 ============

    function testSelectEboolEuint256Euint256() public {
        ebool control = e.asEbool(true);
        euint256 ifTrue = e.asEuint256(42);
        euint256 ifFalse = e.asEuint256(100);
        euint256 result = control.select(ifTrue, ifFalse);
        processAllOperations();
        assertEq(getUint256Value(result), 42);
    }

    function testSelectEboolEuint256Euint256False() public {
        ebool control = e.asEbool(false);
        euint256 ifTrue = e.asEuint256(42);
        euint256 ifFalse = e.asEuint256(100);
        euint256 result = control.select(ifTrue, ifFalse);
        processAllOperations();
        assertEq(getUint256Value(result), 100);
    }

    // ============ CAST OPERATIONS ============

    function testCastEuint256ToEboolRevert() public {
        euint256 a = e.asEuint256(1);
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Bool));
        inco.eCast(euint256.unwrap(a), ETypes.Bool);
    }

    function testCastEboolToEuint256True() public {
        ebool a = e.asEbool(true);
        euint256 b = e.asEuint256(a);
        processAllOperations();
        assertEq(getUint256Value(b), 1);
    }

    function testCastEboolToEuint256False() public {
        ebool a = e.asEbool(false);
        euint256 b = e.asEuint256(a);
        processAllOperations();
        assertEq(getUint256Value(b), 0);
    }

    // ============ EADDRESS CAST OPERATIONS (via inco.eCast directly) ============
    // These test the underlying eCast functionality for eaddress conversions

    function testCastEuint256ToEaddress() public {
        euint256 a = e.asEuint256(uint256(uint160(alice)));
        eaddress b = eaddress.wrap(inco.eCast(euint256.unwrap(a), ETypes.AddressOrUint160OrBytes20));
        processAllOperations();
        assertEq(getAddressValue(b), alice);
    }

    function testCastEuint256ToEaddressZero() public {
        euint256 a = e.asEuint256(0);
        eaddress b = eaddress.wrap(inco.eCast(euint256.unwrap(a), ETypes.AddressOrUint160OrBytes20));
        processAllOperations();
        assertEq(getAddressValue(b), address(0));
    }

    function testCastEboolToEaddressTrue() public {
        ebool a = e.asEbool(true);
        eaddress b = eaddress.wrap(inco.eCast(ebool.unwrap(a), ETypes.AddressOrUint160OrBytes20));
        processAllOperations();
        assertEq(getAddressValue(b), address(1));
    }

    function testCastEboolToEaddressFalse() public {
        ebool a = e.asEbool(false);
        eaddress b = eaddress.wrap(inco.eCast(ebool.unwrap(a), ETypes.AddressOrUint160OrBytes20));
        processAllOperations();
        assertEq(getAddressValue(b), address(0));
    }

    function testCastEaddressToEuint256() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        euint256 b = euint256.wrap(inco.eCast(eaddress.unwrap(a), ETypes.Uint256));
        processAllOperations();
        assertEq(getUint256Value(b), uint256(uint160(alice)));
    }

    function testCastEaddressToEuint256Zero() public {
        eaddress a = e.asEaddress(address(0));
        processAllOperations();
        euint256 b = euint256.wrap(inco.eCast(eaddress.unwrap(a), ETypes.Uint256));
        processAllOperations();
        assertEq(getUint256Value(b), 0);
    }

    function testCastEaddressToEboolNonZeroRevert() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Bool));
        ebool.wrap(inco.eCast(eaddress.unwrap(a), ETypes.Bool));
    }

    function testCastEaddressToEboolZeroRevert() public {
        eaddress a = e.asEaddress(address(0));
        processAllOperations();
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Bool));
        ebool.wrap(inco.eCast(eaddress.unwrap(a), ETypes.Bool));
    }

    function testCastEboolToEboolZeroRevert() public {
        ebool a = e.asEbool(true);
        processAllOperations();
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Bool));
        ebool.wrap(inco.eCast(ebool.unwrap(a), ETypes.Bool));
    }

    function testCastEuint256ToEuint256Revert() public {
        euint256 a = e.asEuint256(10);
        processAllOperations();
        vm.expectRevert(abi.encodeWithSelector(EncryptedOperations.SameTypeCast.selector, ETypes.Uint256));
        euint256.wrap(inco.eCast(euint256.unwrap(a), ETypes.Uint256));
    }

    function testCastEaddressToEaddressRevert() public {
        eaddress a = e.asEaddress(alice);
        processAllOperations();
        vm.expectRevert(
            abi.encodeWithSelector(EncryptedOperations.SameTypeCast.selector, ETypes.AddressOrUint160OrBytes20)
        );
        eaddress.wrap(inco.eCast(eaddress.unwrap(a), ETypes.AddressOrUint160OrBytes20));
    }

    // ============ NOT OPERATION ============

    function testNotEboolTrue() public {
        ebool a = e.asEbool(true);
        ebool b = a.not();
        processAllOperations();
        assertEq(getBoolValue(b), false);
    }

    function testNotEboolFalse() public {
        ebool a = e.asEbool(false);
        ebool b = a.not();
        processAllOperations();
        assertEq(getBoolValue(b), true);
    }

    // ============ RANDOM OPERATIONS ============

    function testRand() public {
        vm.deal(address(this), 1 ether);
        euint256 r = e.rand();
        processAllOperations();
        // Just verify it returns a valid handle (non-zero after processing)
        assertTrue(euint256.unwrap(r) != bytes32(0));
    }

    function testRandBoundedPlaintext() public {
        vm.deal(address(this), 1 ether);
        euint256 r = e.randBounded(uint256(100));
        processAllOperations();
        // Verify result is less than bound
        uint256 value = getUint256Value(r);
        assertTrue(value < 100);
    }

    function testRandBoundedEncrypted() public {
        vm.deal(address(this), 1 ether);
        euint256 bound = e.asEuint256(50);
        euint256 r = e.randBounded(bound);
        processAllOperations();
        // Verify result is less than bound
        uint256 value = getUint256Value(r);
        assertTrue(value < 50);
    }

    // ============ VERIFY DECRYPTION TESTS ============

    function testVerifyDecryption_Euint256_ValidAttestation() public {
        // Create an encrypted value
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        // Get a valid decryption attestation
        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        // Verify the decryption
        bool isValid = e.verifyDecryption(encrypted, uint256(attestation.value), signatures);
        assertTrue(isValid, "Valid attestation should return true");
    }

    function testVerifyDecryption_Euint256_InvalidValue() public {
        // Create an encrypted value
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        // Get a valid decryption attestation
        (, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        // Try to verify with wrong value
        bool isValid = e.verifyDecryption(encrypted, 99999, signatures);
        assertFalse(isValid, "Invalid value should return false");
    }

    function testVerifyDecryption_Euint256_InvalidTEEAttestations() public {
        // Create an encrypted value
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        // Create empty/invalid signatures
        bytes[] memory invalidSignatures = new bytes[](0);

        // Verify with invalid signatures should return false
        bool isValid = e.verifyDecryption(encrypted, 12345, invalidSignatures);
        assertFalse(isValid, "Invalid signatures should return false");
    }

    function testVerifyDecryption_Ebool_ValidAttestation_True() public {
        // Create an encrypted bool (true)
        ebool encrypted = e.asEbool(true);
        processAllOperations();

        // Get a valid decryption attestation
        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        // Verify the decryption
        bool decryptedValue = uint256(attestation.value) != 0;
        bool isValid = e.verifyDecryption(encrypted, decryptedValue, signatures);
        assertTrue(isValid, "Valid attestation for true should return true");
    }

    function testVerifyDecryption_Ebool_ValidAttestation_False() public {
        // Create an encrypted bool (false)
        ebool encrypted = e.asEbool(false);
        processAllOperations();

        // Get a valid decryption attestation
        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        // Verify the decryption
        bool decryptedValue = uint256(attestation.value) != 0;
        bool isValid = e.verifyDecryption(encrypted, decryptedValue, signatures);
        assertTrue(isValid, "Valid attestation for false should return true");
    }

    function testVerifyDecryption_Ebool_InvalidValue() public {
        // Create an encrypted bool (true)
        ebool encrypted = e.asEbool(true);
        processAllOperations();

        // Get a valid decryption attestation for true
        (, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        // Try to verify with wrong value (false instead of true)
        bool isValid = e.verifyDecryption(encrypted, false, signatures);
        assertFalse(isValid, "Invalid bool value should return false");
    }

    // ============ REQUIRE EQUAL TESTS ============

    function testRequireEqual_Ebool_ValidAttestation_True() public {
        ebool encrypted = e.asEbool(true);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        e.requireEqual(encrypted, true, attestation, signatures);
    }

    function testRequireEqual_Ebool_ValidAttestation_False() public {
        ebool encrypted = e.asEbool(false);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        e.requireEqual(encrypted, false, attestation, signatures);
    }

    function testRequireEqual_Ebool_WrongValue() public {
        ebool encrypted = e.asEbool(true);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(UnexpectedDecryptedValue.selector));
        caller.callEbool(encrypted, false, attestation, signatures);
    }

    function testRequireEqual_Ebool_HandleMismatch() public {
        ebool encryptedA = e.asEbool(true);
        ebool encryptedB = e.asEbool(false);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encryptedA), proof: _emptyAllowanceProof()})
        );

        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(HandleMismatch.selector));
        caller.callEbool(encryptedB, true, attestation, signatures);
    }

    function testRequireEqual_Ebool_InvalidTEEAttestations() public {
        ebool encrypted = e.asEbool(true);
        processAllOperations();

        (DecryptionAttestation memory attestation,) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: ebool.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        bytes[] memory invalidSignatures = new bytes[](0);
        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(InvalidTEEAttestation.selector));
        caller.callEbool(encrypted, true, attestation, invalidSignatures);
    }

    function testRequireEqual_Euint256_ValidAttestation() public {
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        e.requireEqual(encrypted, uint256(attestation.value), attestation, signatures);
    }

    function testRequireEqual_Euint256_WrongValue() public {
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(UnexpectedDecryptedValue.selector));
        caller.callEuint256(encrypted, 99999, attestation, signatures);
    }

    function testRequireEqual_Euint256_HandleMismatch() public {
        euint256 encryptedA = e.asEuint256(111);
        euint256 encryptedB = e.asEuint256(222);
        processAllOperations();

        (DecryptionAttestation memory attestation, bytes[] memory signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encryptedA), proof: _emptyAllowanceProof()})
        );

        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(HandleMismatch.selector));
        caller.callEuint256(encryptedB, uint256(attestation.value), attestation, signatures);
    }

    function testRequireEqual_Euint256_InvalidTEEAttestations() public {
        euint256 encrypted = e.asEuint256(12345);
        processAllOperations();

        (DecryptionAttestation memory attestation,) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(encrypted), proof: _emptyAllowanceProof()})
        );

        bytes[] memory invalidSignatures = new bytes[](0);
        RequireEqualCaller caller = new RequireEqualCaller();
        vm.expectRevert(abi.encodeWithSelector(InvalidTEEAttestation.selector));
        caller.callEuint256(encrypted, uint256(attestation.value), attestation, invalidSignatures);
    }

    // ============ ELIST PURE FUNCTION TESTS ============
    // Note: Most EList functions in Lib.sol are thin wrappers around inco.* calls.

    function testEList_ListTypeOf_Uint256() public {
        elist list = _listRange(0, 5, ETypes.Uint256);

        // Test listTypeOf - this is a pure function that extracts type from handle
        ETypes listType = e.listTypeOf(list);
        assertEq(uint8(listType), uint8(ETypes.Uint256), "Range creates Uint256 list");
    }

    function testEList_Length_Empty() public {
        elist list = inco.newEList(new bytes32[](0), ETypes.Uint256); // empty list, fee = 0

        // Test length function
        uint16 len = e.length(list);
        assertEq(len, 0, "Empty list should have length 0");
    }

    function testEList_Length_NonEmpty() public {
        elist list = _listRange(0, 5, ETypes.Uint256);

        // Test length function
        uint16 len = e.length(list);
        assertEq(len, 5, "Range(0,5) should have length 5");
    }

    function testEList_Length_AfterAppend() public {
        elist list = _listRange(0, 3, ETypes.Uint256);

        // Get a handle to append
        bytes32 valueHandle = inco.listGet(list, 0);

        elist newList = _listAppend(list, valueHandle);

        assertEq(e.length(newList), 4, "After append, length should be 4");
    }

    function testEList_Length_AfterConcat() public {
        elist list1 = _listRange(0, 3, ETypes.Uint256);
        elist list2 = _listRange(10, 15, ETypes.Uint256);

        elist combined = _listConcat(list1, list2);

        assertEq(e.length(combined), 8, "Combined list should have length 8");
    }

    function testEList_Length_AfterReverse() public {
        // Create a list
        elist list = _listRange(0, 7, ETypes.Uint256);

        // Reverse using inco directly
        elist reversed = _listReverse(list);

        // Verify length unchanged
        assertEq(e.length(reversed), 7, "Reversed list should have same length");
    }

    LibEListHelper elistHelper;

    function _setupEListHelper() internal {
        if (address(elistHelper) == address(0)) {
            elistHelper = new LibEListHelper();
            vm.deal(address(elistHelper), 10 ether);
        }
    }

    function _allowHelperForList(elist list) internal {
        inco.allow(elist.unwrap(list), address(elistHelper));
        // Also allow individual elements
        uint16 len = e.length(list);
        for (uint16 i = 0; i < len; i++) {
            bytes32 handle = inco.listGet(list, i);
            inco.allow(handle, address(elistHelper));
        }
    }

    function testEListWrapper_NewEListEmpty() public {
        _setupEListHelper();
        elist list = elistHelper.callNewEListEmpty(ETypes.Uint256);
        assertEq(e.length(list), 0);
    }

    function testEListWrapper_NewEListFromHandles() public {
        _setupEListHelper();

        elist rangeList = _listRange(0, 3, ETypes.Uint256);
        bytes32[] memory handles = new bytes32[](3);
        handles[0] = inco.listGet(rangeList, 0);
        handles[1] = inco.listGet(rangeList, 1);
        handles[2] = inco.listGet(rangeList, 2);
        // Grant permissions
        inco.allow(handles[0], address(elistHelper));
        inco.allow(handles[1], address(elistHelper));
        inco.allow(handles[2], address(elistHelper));

        elist list = elistHelper.callNewEListFromHandles(handles, ETypes.Uint256);
        assertEq(e.length(list), 3);
    }

    function testEListWrapper_NewEListFromCiphertexts() public {
        _setupEListHelper();

        // Create ciphertexts for the list
        bytes[] memory ciphertexts = new bytes[](3);
        ciphertexts[0] = fakePrepareEuint256Ciphertext(10, address(elistHelper), address(elistHelper));
        ciphertexts[1] = fakePrepareEuint256Ciphertext(20, address(elistHelper), address(elistHelper));
        ciphertexts[2] = fakePrepareEuint256Ciphertext(30, address(elistHelper), address(elistHelper));

        // Calculate fee: uses elist bit fee
        uint256 fee = inco.getEListFee(uint16(ciphertexts.length), ETypes.Uint256);

        // Create the list from ciphertexts
        elist list =
            elistHelper.callNewEListFromCiphertexts{value: fee}(ciphertexts, ETypes.Uint256, address(elistHelper));

        // Verify the list was created with correct length
        assertEq(e.length(list), 3);
    }

    function testEListWrapper_AppendEuint256() public {
        _setupEListHelper();
        // Create a list and get a handle
        elist list = _listRange(0, 3, ETypes.Uint256);
        bytes32 valueHandle = inco.listGet(list, 0);
        euint256 value = euint256.wrap(valueHandle);
        // Grant permissions
        _allowHelperForList(list);

        elist newList = elistHelper.callAppendEuint256(list, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_AppendEbool() public {
        _setupEListHelper();
        // Create a list and get a handle
        elist list = _listRange(0, 3, ETypes.Uint256);
        bytes32 valueHandle = inco.listGet(list, 0);
        ebool value = ebool.wrap(valueHandle);
        // Grant permissions
        _allowHelperForList(list);

        elist newList = elistHelper.callAppendEbool(list, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_SetHiddenIndexEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 0)); // Use element as index
        euint256 value = euint256.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callSetHiddenIndexEuint256(list, idx, value);
        assertEq(e.length(newList), 3);
    }

    function testEListWrapper_SetHiddenIndexEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 0));
        ebool value = ebool.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callSetHiddenIndexEbool(list, idx, value);
        assertEq(e.length(newList), 3);
    }

    function testEListWrapper_SetPlaintextIndexEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 value = euint256.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callSetPlaintextIndexEuint256(list, 0, value);
        assertEq(e.length(newList), 3);
    }

    function testEListWrapper_SetPlaintextIndexEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        ebool value = ebool.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callSetPlaintextIndexEbool(list, 0, value);
        assertEq(e.length(newList), 3);
    }

    function testEListWrapper_GetOrEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 1));
        euint256 defaultValue = euint256.wrap(inco.listGet(list, 0));

        euint256 result = elistHelper.callGetOrEuint256(list, idx, defaultValue);
        assertTrue(euint256.unwrap(result) != bytes32(0));
    }

    function testEListWrapper_GetOrEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 1));
        ebool defaultValue = ebool.wrap(inco.listGet(list, 0));

        ebool result = elistHelper.callGetOrEbool(list, idx, defaultValue);
        assertTrue(ebool.unwrap(result) != bytes32(0));
    }

    function testEListWrapper_GetEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);

        euint256 result = elistHelper.callGetEuint256(list, 2);
        assertTrue(euint256.unwrap(result) != bytes32(0));
    }

    function testEListWrapper_GetEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);

        ebool result = elistHelper.callGetEbool(list, 2);
        assertTrue(ebool.unwrap(result) != bytes32(0));
    }

    function testEListWrapper_InsertHiddenIndexEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 0));
        euint256 value = euint256.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callInsertHiddenIndexEuint256(list, idx, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_InsertHiddenIndexEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 idx = euint256.wrap(inco.listGet(list, 0));
        ebool value = ebool.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callInsertHiddenIndexEbool(list, idx, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_InsertPlaintextIndexEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 value = euint256.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callInsertPlaintextIndexEuint256(list, 1, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_InsertPlaintextIndexEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        ebool value = ebool.wrap(inco.listGet(list, 1));

        elist newList = elistHelper.callInsertPlaintextIndexEbool(list, 1, value);
        assertEq(e.length(newList), 4);
    }

    function testEListWrapper_Concat() public {
        _setupEListHelper();
        elist list1 = _listRange(0, 3, ETypes.Uint256);
        elist list2 = _listRange(10, 13, ETypes.Uint256);
        _allowHelperForList(list1);
        _allowHelperForList(list2);

        elist combined = elistHelper.callConcat(list1, list2);
        assertEq(e.length(combined), 6);
    }

    function testEListWrapper_Slice() public {
        _setupEListHelper();
        elist list = _listRange(0, 10, ETypes.Uint256);
        _allowHelperForList(list);

        elist sliced = elistHelper.callSlice(list, 2, 7);
        assertEq(e.length(sliced), 5);
    }

    function testEListWrapper_SliceLenEuint256() public {
        _setupEListHelper();
        elist list = _listRange(0, 10, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 start = euint256.wrap(inco.listGet(list, 1));
        euint256 defaultValue = euint256.wrap(inco.listGet(list, 0));

        elist sliced = elistHelper.callSliceLenEuint256(list, start, 3, defaultValue);
        assertEq(e.length(sliced), 3);
    }

    function testEListWrapper_SliceLenEbool() public {
        _setupEListHelper();
        elist list = _listRange(0, 10, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 start = euint256.wrap(inco.listGet(list, 1));
        ebool defaultValue = ebool.wrap(inco.listGet(list, 0));

        elist sliced = elistHelper.callSliceLenEbool(list, start, 3, defaultValue);
        assertEq(e.length(sliced), 3);
    }

    function testEListWrapper_Range() public {
        _setupEListHelper();
        elist list = elistHelper.callRange(5, 15);
        assertEq(e.length(list), 10);
    }

    function testEListWrapper_Reverse() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);

        elist reversed = elistHelper.callReverse(list);
        assertEq(e.length(reversed), 5);
    }

    function testEListWrapper_Shuffle() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        _allowHelperForList(list);

        elist shuffled = elistHelper.callShuffle(list);
        assertEq(e.length(shuffled), 5);
    }

    function testEListWrapper_ShuffledRange() public {
        _setupEListHelper();
        elist list = elistHelper.callShuffledRange(0, 10);
        assertEq(e.length(list), 10);
    }

    function testEListWrapper_Length() public {
        _setupEListHelper();
        elist list = _listRange(0, 7, ETypes.Uint256);
        assertEq(elistHelper.callLength(list), 7);
    }

    function testEListWrapper_ListTypeOf() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256);
        assertEq(uint8(elistHelper.callListTypeOf(list)), uint8(ETypes.Uint256));
    }

    // ============ ELIST REQUIRE/REVERT TESTS ============

    function testEListWrapper_SetPlaintextIndexEuint256_RevertsOnOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256); // length 3, valid indices 0-2
        _allowHelperForList(list);
        euint256 value = euint256.wrap(inco.listGet(list, 0));

        // Index 3 is out of range for a list of length 3
        vm.expectRevert(abi.encodeWithSelector(IndexOutOfRange.selector, 3, 3));
        elistHelper.callSetPlaintextIndexEuint256(list, 3, value);
    }

    function testEListWrapper_SetPlaintextIndexEbool_RevertsOnOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        ebool value = ebool.wrap(inco.listGet(list, 0));

        vm.expectRevert(abi.encodeWithSelector(IndexOutOfRange.selector, 5, 3));
        elistHelper.callSetPlaintextIndexEbool(list, 5, value);
    }

    function testEListWrapper_InsertPlaintextIndexEbool_RevertsOnOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        ebool value = ebool.wrap(inco.listGet(list, 0));

        vm.expectRevert(abi.encodeWithSelector(IndexOutOfRange.selector, 10, 3));
        elistHelper.callInsertPlaintextIndexEbool(list, 10, value);
    }

    function testEListWrapper_InsertPlaintextIndexEuint256_RevertsOnOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 3, ETypes.Uint256);
        _allowHelperForList(list);
        euint256 value = euint256.wrap(inco.listGet(list, 0));

        vm.expectRevert(abi.encodeWithSelector(IndexOutOfRange.selector, 3, 3));
        elistHelper.callInsertPlaintextIndexEuint256(list, 3, value);
    }

    function testEListWrapper_Slice_RevertsOnInvalidRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 10, ETypes.Uint256);
        _allowHelperForList(list);

        // end < start is invalid
        vm.expectRevert(abi.encodeWithSelector(InvalidRange.selector, 5, 3));
        elistHelper.callSlice(list, 5, 3);
    }

    function testEListWrapper_Slice_RevertsOnEndOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256); // length 5
        _allowHelperForList(list);

        // end > length is out of range
        vm.expectRevert(abi.encodeWithSelector(SliceOutOfRange.selector, 2, 10, 5));
        elistHelper.callSlice(list, 2, 10);
    }

    function testEListWrapper_Slice_RevertsOnStartOutOfRange() public {
        _setupEListHelper();
        elist list = _listRange(0, 5, ETypes.Uint256); // length 5
        _allowHelperForList(list);

        // start >= length is out of range
        vm.expectRevert(abi.encodeWithSelector(SliceOutOfRange.selector, 5, 5, 5));
        elistHelper.callSlice(list, 5, 5);
    }

    function testEListWrapper_Slice_WorksWithEboolList() public {
        _setupEListHelper();

        ebool val1 = e.asEbool(true);
        ebool val2 = e.asEbool(false);
        ebool val3 = e.asEbool(true);
        processAllOperations();

        bytes32[] memory handles = new bytes32[](3);
        handles[0] = ebool.unwrap(val1);
        handles[1] = ebool.unwrap(val2);
        handles[2] = ebool.unwrap(val3);
        inco.allow(handles[0], address(elistHelper));
        inco.allow(handles[1], address(elistHelper));
        inco.allow(handles[2], address(elistHelper));

        elist boolList = _newEList(handles, ETypes.Bool);
        _allowHelperForList(boolList);

        // Slice should work and use ebool default value branch
        elist sliced = elistHelper.callSlice(boolList, 0, 2);
        assertEq(e.length(sliced), 2);
    }

    function testEListWrapper_Slice_RevertsOnUnsupportedListType() public {
        _setupEListHelper();

        eaddress addr1 = e.asEaddress(address(0x1));
        eaddress addr2 = e.asEaddress(address(0x2));
        eaddress addr3 = e.asEaddress(address(0x3));
        processAllOperations();

        bytes32[] memory handles = new bytes32[](3);
        handles[0] = eaddress.unwrap(addr1);
        handles[1] = eaddress.unwrap(addr2);
        handles[2] = eaddress.unwrap(addr3);
        inco.allow(handles[0], address(elistHelper));
        inco.allow(handles[1], address(elistHelper));
        inco.allow(handles[2], address(elistHelper));

        elist unsupportedList = _newEList(handles, ETypes.AddressOrUint160OrBytes20);
        _allowHelperForList(unsupportedList);

        // Slice should revert with UnsupportedListType
        vm.expectRevert(abi.encodeWithSelector(UnsupportedListType.selector, ETypes.AddressOrUint160OrBytes20));
        elistHelper.callSlice(unsupportedList, 0, 2);
    }

    // ============ VERIFY ELIST DECRYPTION TEST ============

    function testEListWrapper_VerifyEListDecryption() public {
        _setupEListHelper();

        elist list = _listRange(0, 3, ETypes.Uint256);

        // Create empty proof elements (for basic verification test)
        ElementAttestationWithProof[] memory proofElements = new ElementAttestationWithProof[](0);
        bytes32 proof = bytes32(0);
        bytes[] memory signatures = new bytes[](0);

        // This should return false with empty/invalid data
        bool result = elistHelper.callVerifyEListDecryption(list, proofElements, proof, signatures);
        assertFalse(result, "Empty proof should fail verification");
    }

    // ============ ELIST ALLOW / REVEAL / ALLOWTHIS WRAPPER TESTS ============

    function testEListWrapper_Allow() public {
        _setupEListHelper();
        elist list = elistHelper.callRange(0, 3);

        assertFalse(inco.persistAllowed(elist.unwrap(list), alice));
        elistHelper.callAllowElist(list, alice);
        assertTrue(inco.persistAllowed(elist.unwrap(list), alice));
    }

    function testEListWrapper_Reveal() public {
        _setupEListHelper();
        elist list = elistHelper.callRange(0, 3);

        assertFalse(inco.isRevealed(elist.unwrap(list)));
        elistHelper.callRevealElist(list);
        assertTrue(inco.isRevealed(elist.unwrap(list)));
    }

    function testEListWrapper_AllowThis() public {
        _setupEListHelper();
        // elistHelper must create the list so it has transient access, which is required to call allow
        elist list = elistHelper.callRange(0, 3);

        assertFalse(inco.persistAllowed(elist.unwrap(list), address(elistHelper)));
        elistHelper.callAllowThisElist(list);
        assertTrue(inco.persistAllowed(elist.unwrap(list), address(elistHelper)));
    }

}

/// @notice Helper contract for testing msg.sender variants
contract LibTestHelper {

    using e for bytes;

    euint256 public storedEuint256;
    ebool public storedEbool;
    eaddress public storedEaddress;

    function callNewEuint256(bytes memory ciphertext) external {
        storedEuint256 = ciphertext.newEuint256();
    }

    function callNewEbool(bytes memory ciphertext) external {
        storedEbool = ciphertext.newEbool();
    }

    function callNewEaddress(bytes memory ciphertext) external {
        storedEaddress = ciphertext.newEaddress();
    }

}

/// @notice Helper contract for testing e.* EList wrapper functions
/// @dev Uses inco.* to create handles, then calls e.* wrappers with non-zero handles
contract LibEListHelper {

    using e for euint256;
    using e for ebool;
    using e for elist;

    elist public storedList;
    euint256 public storedEuint256;
    ebool public storedEbool;

    // ============ newEList wrappers ============

    function callNewEListEmpty(ETypes listType) external returns (elist) {
        storedList = e.newEList(listType);
        return storedList;
    }

    function callNewEListFromHandles(bytes32[] memory handles, ETypes listType) external returns (elist) {
        storedList = e.newEList(handles, listType);
        return storedList;
    }

    function callNewEListFromCiphertexts(bytes[] memory ciphertexts, ETypes listType, address user)
        external
        payable
        returns (elist)
    {
        storedList = e.newEList(ciphertexts, listType, user);
        return storedList;
    }

    // ============ append wrappers ============

    function callAppendEuint256(elist list, euint256 value) external returns (elist) {
        storedList = e.append(list, value);
        return storedList;
    }

    function callAppendEbool(elist list, ebool value) external returns (elist) {
        storedList = e.append(list, value);
        return storedList;
    }

    // ============ set wrappers ============

    function callSetHiddenIndexEuint256(elist list, euint256 idx, euint256 value) external returns (elist) {
        storedList = e.set(list, idx, value);
        return storedList;
    }

    function callSetHiddenIndexEbool(elist list, euint256 idx, ebool value) external returns (elist) {
        storedList = e.set(list, idx, value);
        return storedList;
    }

    function callSetPlaintextIndexEuint256(elist list, uint16 idx, euint256 value) external returns (elist) {
        storedList = e.set(list, idx, value);
        return storedList;
    }

    function callSetPlaintextIndexEbool(elist list, uint16 idx, ebool value) external returns (elist) {
        storedList = e.set(list, idx, value);
        return storedList;
    }

    // ============ getOr wrappers ============

    function callGetOrEuint256(elist list, euint256 idx, euint256 defaultValue) external returns (euint256) {
        storedEuint256 = e.getOr(list, idx, defaultValue);
        return storedEuint256;
    }

    function callGetOrEbool(elist list, euint256 idx, ebool defaultValue) external returns (ebool) {
        storedEbool = e.getOr(list, idx, defaultValue);
        return storedEbool;
    }

    // ============ get wrappers ============

    function callGetEuint256(elist list, uint16 idx) external returns (euint256) {
        storedEuint256 = e.getEuint256(list, idx);
        return storedEuint256;
    }

    function callGetEbool(elist list, uint16 idx) external returns (ebool) {
        storedEbool = e.getEbool(list, idx);
        return storedEbool;
    }

    // ============ insert wrappers ============

    function callInsertHiddenIndexEuint256(elist list, euint256 idx, euint256 value) external returns (elist) {
        storedList = e.insert(list, idx, value);
        return storedList;
    }

    function callInsertHiddenIndexEbool(elist list, euint256 idx, ebool value) external returns (elist) {
        storedList = e.insert(list, idx, value);
        return storedList;
    }

    function callInsertPlaintextIndexEuint256(elist list, uint16 idx, euint256 value) external returns (elist) {
        storedList = e.insert(list, idx, value);
        return storedList;
    }

    function callInsertPlaintextIndexEbool(elist list, uint16 idx, ebool value) external returns (elist) {
        storedList = e.insert(list, idx, value);
        return storedList;
    }

    // ============ other list operations ============

    function callConcat(elist list1, elist list2) external returns (elist) {
        storedList = e.concat(list1, list2);
        return storedList;
    }

    function callSlice(elist list, uint16 start, uint16 end) external returns (elist) {
        storedList = e.slice(list, start, end);
        return storedList;
    }

    function callSliceLenEuint256(elist list, euint256 start, uint16 len, euint256 defaultValue)
        external
        returns (elist)
    {
        storedList = e.sliceLen(list, start, len, defaultValue);
        return storedList;
    }

    function callSliceLenEbool(elist list, euint256 start, uint16 len, ebool defaultValue) external returns (elist) {
        storedList = e.sliceLen(list, start, len, defaultValue);
        return storedList;
    }

    function callRange(uint16 start, uint16 end) external returns (elist) {
        storedList = e.range(start, end, ETypes.Uint256);
        return storedList;
    }

    function callShuffle(elist list) external returns (elist) {
        storedList = e.shuffle(list);
        return storedList;
    }

    function callShuffledRange(uint16 start, uint16 end) external returns (elist) {
        storedList = e.shuffledRange(start, end, ETypes.Uint256);
        return storedList;
    }

    function callReverse(elist list) external returns (elist) {
        storedList = e.reverse(list);
        return storedList;
    }

    function callLength(elist list) external pure returns (uint16) {
        return e.length(list);
    }

    function callListTypeOf(elist list) external pure returns (ETypes) {
        return e.listTypeOf(list);
    }

    function callVerifyEListDecryption(
        elist elistHandle,
        ElementAttestationWithProof[] memory proofElements,
        bytes32 proof,
        bytes[] memory signatures
    ) external view returns (bool) {
        return e.verifyEListDecryption(elistHandle, proofElements, proof, signatures);
    }

    // ============ allow / reveal / allowThis wrappers ============

    function callAllowElist(elist list, address to) external {
        e.allow(list, to);
    }

    function callRevealElist(elist list) external {
        e.reveal(list);
    }

    function callAllowThisElist(elist list) external {
        e.allowThis(list);
    }

}
