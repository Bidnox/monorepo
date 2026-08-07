// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "./IncoTest.sol";
import {e, euint256, ebool, eaddress, inco} from "../Lib.sol";
import {SenderNotAllowedForHandle, UnsupportedType, ETypes, UnexpectedType, typeToBitMask} from "../Types.sol";
import {TEELifecycle} from "../lightning-parts/TEELifecycle.sol";
import {Td10ReportBody, MINIMUM_QUOTE_LENGTH} from "../interfaces/automata-interfaces/Types.sol";

contract TakesEInput is IncoTest {

    using e for bytes;
    using e for euint256;

    euint256 public a;
    ebool public b;
    eaddress public c;
    uint256 public decryptedA;

    function setA(bytes memory uint256EInput) external {
        a = uint256EInput.newEuint256(msg.sender);
        a.allowThis();
    }

    function setB(bytes memory boolEInput) external {
        b = boolEInput.newEbool(msg.sender);
    }

    function setC(bytes memory addressEInput) external {
        c = addressEInput.newEaddress(msg.sender);
    }

}

// its meta: this is testing correct behavior of our testing infrastructure
contract TestFakeInfra is IncoTest {

    using e for euint256;
    using e for ebool;
    using e for uint256;
    using e for bool;
    using e for address;
    using e for eaddress;

    function testTrivialEncrypt() public {
        euint256 a = e.asEuint256(3);
        assertEq(getUint256Value(a), 0); // operations not processed yet
        processAllOperations();
        assertEq(getUint256Value(a), 3);
        ebool b = e.asEbool(true);
        processAllOperations();
        assertEq(getBoolValue(b), true);
        eaddress c = e.asEaddress(address(0xdeadbeef));
        processAllOperations();
        assertEq(getAddressValue(c), address(0xdeadbeef));
    }

    function testEAdd() public {
        euint256 a = e.asEuint256(3);
        euint256 b = e.asEuint256(4);
        euint256 c = a.add(b);
        processAllOperations();
        assertEq(getUint256Value(c), 7);
    }

    function testEAddScalar() public {
        euint256 a = e.asEuint256(3);
        euint256 c = a.add(uint256(4));
        euint256 c256 = uint256(4).add(a);
        processAllOperations();
        assertEq(getUint256Value(c), 7);
        assertEq(getUint256Value(c256), 7);
    }

    function testESub() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.sub(b);
        processAllOperations();
        assertEq(getUint256Value(c), 6);
    }

    function testEMul() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.mul(b);
        processAllOperations();
        assertEq(getUint256Value(c), 40);
    }

    function testEDiv() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.div(b);
        processAllOperations();
        assertEq(getUint256Value(c), 2);
    }

    function testEDiv_DivisionByZeroReturnsMaxUint256() public {
        euint256 a = e.asEuint256(10);
        euint256 zero = e.asEuint256(0);
        euint256 c = a.div(zero);
        processAllOperations();
        assertEq(getUint256Value(c), type(uint256).max);
    }

    function testERem() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.rem(b);
        processAllOperations();
        assertEq(getUint256Value(c), 2);
    }

    function testERem_RemainderByZeroReturnsLhs() public {
        euint256 a = e.asEuint256(10);
        euint256 zero = e.asEuint256(0);
        euint256 c = a.rem(zero);
        processAllOperations();
        assertEq(getUint256Value(c), 10);
    }

    function testEAnd() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.and(b);
        processAllOperations();
        assertEq(getUint256Value(c), 0);
    }

    function testEOr() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.or(b);
        processAllOperations();
        assertEq(getUint256Value(c), 14);
    }

    function testEXor() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.xor(b);
        processAllOperations();
        assertEq(getUint256Value(c), 14);
    }

    function testEShl() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.shl(b);
        processAllOperations();
        assertEq(getUint256Value(c), 160);
    }

    function testEShr() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);

        euint256 c = a.shr(b);
        processAllOperations();
        assertEq(getUint256Value(c), 0);
    }

    function testERotl() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.rotl(b);
        processAllOperations();
        assertEq(getUint256Value(c), 160);
    }

    function testERotr() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.rotr(b);
        processAllOperations();
        assertEq(getUint256Value(c), 72370055773322622139731865630429942408293740416025352524660990004945706024960);
    }

    function testEEq() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.eq(b);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testENe() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.ne(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEGe() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.ge(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testEGt() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.gt(b);
        processAllOperations();
        assertEq(getBoolValue(c), true);
    }

    function testELe() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.le(b);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testELt() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        ebool c = a.lt(b);
        processAllOperations();
        assertEq(getBoolValue(c), false);
    }

    function testEMin() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.min(b);
        processAllOperations();
        assertEq(getUint256Value(c), 4);
    }

    function testEMax() public {
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 c = a.max(b);
        processAllOperations();
        assertEq(getUint256Value(c), 10);
    }

    function testENot() public {
        ebool a = e.asEbool(true);
        ebool b = a.not();
        processAllOperations();
        assertEq(getBoolValue(b), false);
    }

    function testERand() public {
        euint256 a = e.rand();
        processAllOperations();
        assertEq(getUint256Value(a), 1);
    }

    function testERandBounded() public {
        euint256 a = e.randBounded(10);
        processAllOperations();
        assertEq(getUint256Value(a), 1);
    }

    function testERandBoundedWithEuint256() public {
        euint256 bound = e.asEuint256(100);
        processAllOperations();
        euint256 a = e.randBounded(bound);
        processAllOperations();
        assertEq(getUint256Value(a), 1);
    }

    // ============ FEE CACHING TESTS ============

    // The fee slot used by the library
    bytes32 constant FEE_SLOT = keccak256("inco.fee");

    function testFeeCachingOnRand() public {
        // Verify the slot is empty before any operation
        bytes32 cachedFeeBefore = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // Call rand which should cache the fee
        euint256 a = e.rand();
        processAllOperations();
        assertEq(getUint256Value(a), 1);

        // Verify the fee is now cached
        bytes32 cachedFeeAfter = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeAfter), inco.getFee(), "Cached fee should match inco.getFee()");
    }

    function testFeeCachingPersistsAcrossOperations() public {
        // Verify the slot is empty before any operation
        bytes32 cachedFeeBefore = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // First operation caches the fee
        e.rand();
        processAllOperations();

        // Get the cached fee
        bytes32 cachedFeeFirst = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeFirst), inco.getFee(), "Fee should be cached after first operation");

        // Second operation should use cached fee
        e.rand();
        processAllOperations();

        // Verify fee is still the same (wasn't re-fetched)
        bytes32 cachedFeeSecond = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeFirst), uint256(cachedFeeSecond), "Cached fee should persist across operations");
    }

    function testFeeCachingOnRandBounded() public {
        // Verify the slot is empty before any operation
        bytes32 cachedFeeBefore = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // Call randBounded which should cache the fee
        euint256 a = e.randBounded(100);
        processAllOperations();
        assertEq(getUint256Value(a), 1);

        // Verify the fee is now cached
        bytes32 cachedFeeAfter = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(cachedFeeAfter), inco.getFee(), "Cached fee should match inco.getFee()");
    }

    function testFeeCachingOnNewEuint256() public {
        // Create a contract that will use e.newEuint256
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // Verify the slot is empty in the input contract before operation
        bytes32 cachedFeeBefore = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // Call setA which uses e.newEuint256 internally
        address self = address(this);
        bytes memory ciphertext = fakePrepareEuint256Ciphertext(42, self, address(inputContract));
        inputContract.setA(ciphertext);
        processAllOperations();

        // Verify the fee is now cached in the input contract
        bytes32 cachedFeeAfter = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeAfter), inco.getFee(), "Cached fee should match inco.getFee()");
    }

    function testFeeCachingOnNewEbool() public {
        // Create a contract that will use e.newEbool
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // Verify the slot is empty in the input contract before operation
        bytes32 cachedFeeBefore = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // Call setB which uses e.newEbool internally
        address self = address(this);
        bytes memory ciphertext = fakePrepareEboolCiphertext(true, self, address(inputContract));
        inputContract.setB(ciphertext);
        processAllOperations();

        // Verify the fee is now cached in the input contract
        bytes32 cachedFeeAfter = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeAfter), inco.getFee(), "Cached fee should match inco.getFee()");
    }

    function testFeeCachingOnEAddress() public {
        // Create a contract that will use e.newEaddress
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // Verify the slot is empty in the input contract before operation
        bytes32 cachedFeeBefore = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeBefore), 0, "Fee should not be cached initially");

        // Call setC which uses e.newEaddress internally
        address self = address(this);
        bytes memory ciphertext = fakePrepareEaddressCiphertext(alice, self, address(inputContract));
        inputContract.setC(ciphertext);
        processAllOperations();

        // Verify the fee is now cached in the input contract
        bytes32 cachedFeeAfter = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(cachedFeeAfter), inco.getFee(), "Cached fee should match inco.getFee()");
    }

    function testFeeRetryWithStaleCachedFee() public {
        // First, cache a valid fee by calling rand
        e.rand();
        processAllOperations();

        // Now manually set the cached fee to a wrong value
        // This simulates a fee increase after caching
        vm.store(address(this), FEE_SLOT, bytes32(uint256(1)));

        // Verify the stale fee is set
        bytes32 staleFee = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(staleFee), 1, "Stale fee should be 1 wei");

        // Call rand again - the first call with stale fee should fail,
        // but retry with fresh fee should succeed (no revert = success)
        euint256 a = e.rand();
        processAllOperations();

        // Verify we got a valid handle (non-zero)
        assertTrue(euint256.unwrap(a) != bytes32(0), "Should return a valid handle");

        // Verify the fee cache was updated to the correct value
        bytes32 updatedFee = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(updatedFee), inco.getFee(), "Fee should be updated after retry");
    }

    function testFeeRetryOnRandBounded() public {
        // Cache a valid fee first
        e.rand();
        processAllOperations();

        // Set stale fee
        vm.store(address(this), FEE_SLOT, bytes32(uint256(1)));

        // randBounded should also retry successfully (no revert = success)
        euint256 a = e.randBounded(100);
        processAllOperations();

        // Verify we got a valid handle (non-zero)
        assertTrue(euint256.unwrap(a) != bytes32(0), "Should return a valid handle");

        // Verify fee was updated
        bytes32 updatedFee = vm.load(address(this), FEE_SLOT);
        assertEq(uint256(updatedFee), inco.getFee(), "Fee should be updated after retry");
    }

    function testFeeRetryOnNewEuint256() public {
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // First call to cache the fee
        address self = address(this);
        bytes memory ciphertext1 = fakePrepareEuint256Ciphertext(42, self, address(inputContract));
        inputContract.setA(ciphertext1);
        processAllOperations();

        // Verify first value was stored correctly
        assertEq(getUint256Value(inputContract.a()), 42, "First value should be 42");

        // Set stale fee in the input contract
        vm.store(address(inputContract), FEE_SLOT, bytes32(uint256(1)));

        // Second call should retry and succeed
        bytes memory ciphertext2 = fakePrepareEuint256Ciphertext(99, self, address(inputContract));
        inputContract.setA(ciphertext2);
        processAllOperations();

        // Verify the retried value was stored correctly
        assertEq(getUint256Value(inputContract.a()), 99, "Retried value should be 99");

        // Verify fee was updated
        bytes32 updatedFee = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(updatedFee), inco.getFee(), "Fee should be updated after retry");
    }

    function testFeeRetryOnNewEbool() public {
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // First call to cache the fee
        address self = address(this);
        bytes memory ciphertext1 = fakePrepareEboolCiphertext(true, self, address(inputContract));
        inputContract.setB(ciphertext1);
        processAllOperations();

        // Verify first value was stored correctly
        assertEq(getBoolValue(inputContract.b()), true, "First value should be true");

        // Set stale fee
        vm.store(address(inputContract), FEE_SLOT, bytes32(uint256(1)));

        // Second call should retry and succeed
        bytes memory ciphertext2 = fakePrepareEboolCiphertext(false, self, address(inputContract));
        inputContract.setB(ciphertext2);
        processAllOperations();

        // Verify the retried value was stored correctly
        assertEq(getBoolValue(inputContract.b()), false, "Retried value should be false");

        // Verify fee was updated
        bytes32 updatedFee = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(updatedFee), inco.getFee(), "Fee should be updated after retry");
    }

    function testFeeRetryOnNewEaddress() public {
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);

        // First call to cache the fee
        address self = address(this);
        bytes memory ciphertext1 = fakePrepareEaddressCiphertext(alice, self, address(inputContract));
        inputContract.setC(ciphertext1);
        processAllOperations();

        // Verify first value was stored correctly
        assertEq(getAddressValue(inputContract.c()), alice, "First value should be alice");

        // Set stale fee
        vm.store(address(inputContract), FEE_SLOT, bytes32(uint256(1)));

        // Second call should retry and succeed
        bytes memory ciphertext2 = fakePrepareEaddressCiphertext(bob, self, address(inputContract));
        inputContract.setC(ciphertext2);
        processAllOperations();

        // Verify the retried value was stored correctly
        assertEq(getAddressValue(inputContract.c()), bob, "Retried value should be bob");

        // Verify fee was updated
        bytes32 updatedFee = vm.load(address(inputContract), FEE_SLOT);
        assertEq(uint256(updatedFee), inco.getFee(), "Fee should be updated after retry");
    }

    function testEIfThenElse() public {
        ebool controlA = e.asEbool(true);
        ebool controlB = e.asEbool(false);
        euint256 a = e.asEuint256(10);
        euint256 b = e.asEuint256(4);
        euint256 resA = controlA.select(a, b);
        euint256 resB = controlB.select(a, b);
        processAllOperations();
        assertEq(getUint256Value(resA), 10);
        assertEq(getUint256Value(resB), 4);
    }

    function testECastToEBoolRevert() public {
        euint256 a = e.asEuint256(1);
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Bool));
        inco.eCast(euint256.unwrap(a), ETypes.Bool);
    }

    function testECastToFromEBool() public {
        ebool a = e.asEbool(true);
        euint256 b = a.asEuint256();
        processAllOperations();
        assertEq(getUint256Value(b), 1);
    }

    function testEInput() public {
        TakesEInput inputContract = new TakesEInput();
        vm.deal(address(inputContract), 1 ether);
        address self = address(this);
        bytes memory ciphertext = fakePrepareEuint256Ciphertext(12, self, address(inputContract));
        inputContract.setA(ciphertext);
        inputContract.setB(fakePrepareEboolCiphertext(true, self, address(inputContract)));
        processAllOperations();
        assertEq(getUint256Value(inputContract.a()), 12);
        assertEq(getBoolValue(inputContract.b()), true);
    }

    function testUninitializedHandleIsDisallowed_Add() public {
        bytes32 randomHandle = keccak256("random handle");
        euint256 a = e.asEuint256(12);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.add(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Sub() public {
        bytes32 randomHandle = keccak256("random handle");
        euint256 a = e.asEuint256(12);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.sub(euint256.wrap(randomHandle));
    }

    function testECastAllowed() public {
        bytes32 invalidHandle = keccak256("invalid handle");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, invalidHandle, address(this)));
        ebool.wrap(invalidHandle).asEuint256();
    }

    function testUninitializedHandleIsDisallowed_Add_Lhs() public {
        bytes32 randomHandle = keccak256("random handle add lhs");
        euint256 b = e.asEuint256(4);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).add(b);
    }

    function testUninitializedHandleIsDisallowed_Sub_Lhs() public {
        bytes32 randomHandle = keccak256("random handle sub lhs");
        euint256 b = e.asEuint256(4);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).sub(b);
    }

    function testUninitializedHandleIsDisallowed_Mul_Lhs() public {
        bytes32 randomHandle = keccak256("random handle mul lhs");
        euint256 b = e.asEuint256(4);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).mul(b);
    }

    function testUninitializedHandleIsDisallowed_Mul_Rhs() public {
        bytes32 randomHandle = keccak256("random handle mul rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.mul(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Div_Lhs() public {
        bytes32 randomHandle = keccak256("random handle div lhs");
        euint256 b = e.asEuint256(4);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).div(b);
    }

    function testUninitializedHandleIsDisallowed_Div_Rhs() public {
        bytes32 randomHandle = keccak256("random handle div rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.div(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Rem_Lhs() public {
        bytes32 randomHandle = keccak256("random handle rem lhs");
        euint256 b = e.asEuint256(4);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).rem(b);
    }

    function testUninitializedHandleIsDisallowed_Rem_Rhs() public {
        bytes32 randomHandle = keccak256("random handle rem rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.rem(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_And_Lhs() public {
        bytes32 randomHandle = keccak256("random handle and lhs");
        euint256 b = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).and(b);
    }

    function testUninitializedHandleIsDisallowed_And_Rhs() public {
        bytes32 randomHandle = keccak256("random handle and rhs");
        euint256 a = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.and(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Or_Lhs() public {
        // Craft handle with valid Uint256 type byte (8) at bits 8-15
        bytes32 randomHandle =
            bytes32((uint256(keccak256("random handle or lhs")) & ~(uint256(0xFF) << 8)) | (uint256(8) << 8));
        euint256 b = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).or(b);
    }

    function testUninitializedHandleIsDisallowed_Or_Rhs() public {
        // Craft handle with valid Uint256 type byte (8) at bits 8-15
        bytes32 randomHandle =
            bytes32((uint256(keccak256("random handle or rhs")) & ~(uint256(0xFF) << 8)) | (uint256(8) << 8));
        euint256 a = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.or(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Xor_Lhs() public {
        // Craft handle with valid Uint256 type byte (8) at bits 8-15
        bytes32 randomHandle =
            bytes32((uint256(keccak256("random handle xor lhs")) & ~(uint256(0xFF) << 8)) | (uint256(8) << 8));
        euint256 b = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).xor(b);
    }

    function testUninitializedHandleIsDisallowed_Xor_Rhs() public {
        bytes32 randomHandle = keccak256("random handle xor rhs");
        euint256 a = e.asEuint256(0xFF);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.xor(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Shl_Lhs() public {
        bytes32 randomHandle = keccak256("random handle shl lhs");
        euint256 b = e.asEuint256(2);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).shl(b);
    }

    function testUninitializedHandleIsDisallowed_Shl_Rhs() public {
        bytes32 randomHandle = keccak256("random handle shl rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.shl(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Shr_Lhs() public {
        bytes32 randomHandle = keccak256("random handle shr lhs");
        euint256 b = e.asEuint256(2);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).shr(b);
    }

    function testUninitializedHandleIsDisallowed_Shr_Rhs() public {
        bytes32 randomHandle = keccak256("random handle shr rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.shr(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Rotl_Lhs() public {
        bytes32 randomHandle = keccak256("random handle rotl lhs");
        euint256 b = e.asEuint256(2);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).rotl(b);
    }

    function testUninitializedHandleIsDisallowed_Rotl_Rhs() public {
        bytes32 randomHandle = keccak256("random handle rotl rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.rotl(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Rotr_Lhs() public {
        bytes32 randomHandle = keccak256("random handle rotr lhs");
        euint256 b = e.asEuint256(2);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).rotr(b);
    }

    function testUninitializedHandleIsDisallowed_Rotr_Rhs() public {
        bytes32 randomHandle = keccak256("random handle rotr rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.rotr(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Eq_Lhs() public {
        bytes32 randomHandle = keccak256("random handle eq lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).eq(b);
    }

    function testUninitializedHandleIsDisallowed_Eq_Rhs() public {
        bytes32 randomHandle = keccak256("random handle eq rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.eq(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Ne_Lhs() public {
        bytes32 randomHandle = keccak256("random handle ne lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).ne(b);
    }

    function testUninitializedHandleIsDisallowed_Ne_Rhs() public {
        bytes32 randomHandle = keccak256("random handle ne rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.ne(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Ge_Lhs() public {
        bytes32 randomHandle = keccak256("random handle ge lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).ge(b);
    }

    function testUninitializedHandleIsDisallowed_Ge_Rhs() public {
        bytes32 randomHandle = keccak256("random handle ge rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.ge(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Gt_Lhs() public {
        bytes32 randomHandle = keccak256("random handle gt lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).gt(b);
    }

    function testUninitializedHandleIsDisallowed_Gt_Rhs() public {
        bytes32 randomHandle = keccak256("random handle gt rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.gt(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Le_Lhs() public {
        bytes32 randomHandle = keccak256("random handle le lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).le(b);
    }

    function testUninitializedHandleIsDisallowed_Le_Rhs() public {
        bytes32 randomHandle = keccak256("random handle le rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.le(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Lt_Lhs() public {
        bytes32 randomHandle = keccak256("random handle lt lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).lt(b);
    }

    function testUninitializedHandleIsDisallowed_Lt_Rhs() public {
        bytes32 randomHandle = keccak256("random handle lt rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.lt(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Min_Lhs() public {
        bytes32 randomHandle = keccak256("random handle min lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).min(b);
    }

    function testUninitializedHandleIsDisallowed_Min_Rhs() public {
        bytes32 randomHandle = keccak256("random handle min rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.min(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_Max_Lhs() public {
        bytes32 randomHandle = keccak256("random handle max lhs");
        euint256 b = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).max(b);
    }

    function testUninitializedHandleIsDisallowed_Max_Rhs() public {
        bytes32 randomHandle = keccak256("random handle max rhs");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.max(euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_AsEuint256FromEbool() public {
        bytes32 randomHandle = keccak256("random handle ebool to euint256");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).asEuint256();
    }

    function testUninitializedHandleIsDisallowed_Not() public {
        bytes32 randomHandle = keccak256("random handle not");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).not();
    }

    function testUninitializedHandleIsDisallowed_EboolAnd_Lhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool and lhs")) & ~(uint256(0xFF) << 8));
        ebool b = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).and(b);
    }

    function testUninitializedHandleIsDisallowed_EboolAnd_Rhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool and rhs")) & ~(uint256(0xFF) << 8));
        ebool a = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.and(ebool.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_EboolOr_Lhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool or lhs")) & ~(uint256(0xFF) << 8));
        ebool b = e.asEbool(false);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).or(b);
    }

    function testUninitializedHandleIsDisallowed_EboolOr_Rhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool or rhs")) & ~(uint256(0xFF) << 8));
        ebool a = e.asEbool(false);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.or(ebool.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_EboolXor_Lhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool xor lhs")) & ~(uint256(0xFF) << 8));
        ebool b = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).xor(b);
    }

    function testUninitializedHandleIsDisallowed_EboolXor_Rhs() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle ebool xor rhs")) & ~(uint256(0xFF) << 8));
        ebool a = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.xor(ebool.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_EaddressEq_Lhs() public {
        bytes32 randomHandle = keccak256("random handle eaddress eq lhs");
        eaddress b = e.asEaddress(address(0xdeadbeef));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        eaddress.wrap(randomHandle).eq(b);
    }

    function testUninitializedHandleIsDisallowed_EaddressEq_Rhs() public {
        bytes32 randomHandle = keccak256("random handle eaddress eq rhs");
        eaddress a = e.asEaddress(address(0xdeadbeef));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.eq(eaddress.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_EaddressNe_Lhs() public {
        bytes32 randomHandle = keccak256("random handle eaddress ne lhs");
        eaddress b = e.asEaddress(address(0xdeadbeef));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        eaddress.wrap(randomHandle).ne(b);
    }

    function testUninitializedHandleIsDisallowed_EaddressNe_Rhs() public {
        bytes32 randomHandle = keccak256("random handle eaddress ne rhs");
        eaddress a = e.asEaddress(address(0xdeadbeef));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.ne(eaddress.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_SelectEuint256_Control() public {
        bytes32 randomHandle = keccak256("random handle select euint256 control");
        euint256 ifTrue = e.asEuint256(10);
        euint256 ifFalse = e.asEuint256(20);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).select(ifTrue, ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEuint256_IfTrue() public {
        // Craft handle with valid Uint256 type byte (8) at bits 8-15
        bytes32 randomHandle = bytes32(
            (uint256(keccak256("random handle select euint256 iftrue")) & ~(uint256(0xFF) << 8)) | (uint256(8) << 8)
        );
        ebool control = e.asEbool(true);
        euint256 ifFalse = e.asEuint256(20);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(euint256.wrap(randomHandle), ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEuint256_IfFalse() public {
        // Craft handle with valid Uint256 type byte (8) at bits 8-15
        bytes32 randomHandle = bytes32(
            (uint256(keccak256("random handle select euint256 iffalse")) & ~(uint256(0xFF) << 8)) | (uint256(8) << 8)
        );
        ebool control = e.asEbool(false);
        euint256 ifTrue = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(ifTrue, euint256.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_SelectEbool_Control() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle select ebool control")) & ~(uint256(0xFF) << 8));
        ebool ifTrue = e.asEbool(true);
        ebool ifFalse = e.asEbool(false);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).select(ifTrue, ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEbool_IfTrue() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle select ebool iftrue")) & ~(uint256(0xFF) << 8));
        ebool control = e.asEbool(true);
        ebool ifFalse = e.asEbool(false);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(ebool.wrap(randomHandle), ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEbool_IfFalse() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle select ebool iffalse")) & ~(uint256(0xFF) << 8));
        ebool control = e.asEbool(false);
        ebool ifTrue = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(ifTrue, ebool.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_SelectEaddress_Control() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15 for control
        bytes32 randomHandle =
            bytes32(uint256(keccak256("random handle select eaddress control")) & ~(uint256(0xFF) << 8));
        eaddress ifTrue = e.asEaddress(address(0x1));
        eaddress ifFalse = e.asEaddress(address(0x2));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).select(ifTrue, ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEaddress_IfTrue() public {
        // Craft handle with valid AddressOrUint160OrBytes20 type byte (7) at bits 8-15
        bytes32 randomHandle = bytes32(
            (uint256(keccak256("random handle select eaddress iftrue")) & ~(uint256(0xFF) << 8)) | (uint256(7) << 8)
        );
        ebool control = e.asEbool(true);
        eaddress ifFalse = e.asEaddress(address(0x2));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(eaddress.wrap(randomHandle), ifFalse);
    }

    function testUninitializedHandleIsDisallowed_SelectEaddress_IfFalse() public {
        // Craft handle with valid AddressOrUint160OrBytes20 type byte (7) at bits 8-15
        bytes32 randomHandle = bytes32(
            (uint256(keccak256("random handle select eaddress iffalse")) & ~(uint256(0xFF) << 8)) | (uint256(7) << 8)
        );
        ebool control = e.asEbool(false);
        eaddress ifTrue = e.asEaddress(address(0x1));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        control.select(ifTrue, eaddress.wrap(randomHandle));
    }

    function testUninitializedHandleIsDisallowed_AllowEuint256() public {
        bytes32 randomHandle = keccak256("random handle allow euint256");
        address recipient = address(0x1234);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).allow(recipient);
    }

    function testUninitializedHandleIsDisallowed_AllowEbool() public {
        bytes32 randomHandle = keccak256("random handle allow ebool");
        address recipient = address(0x1234);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).allow(recipient);
    }

    function testUninitializedHandleIsDisallowed_AllowEaddress() public {
        bytes32 randomHandle = keccak256("random handle allow eaddress");
        address recipient = address(0x1234);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        eaddress.wrap(randomHandle).allow(recipient);
    }

    function testUninitializedHandleIsDisallowed_AllowThisEuint256() public {
        bytes32 randomHandle = keccak256("random handle allowThis euint256");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).allowThis();
    }

    function testUninitializedHandleIsDisallowed_AllowThisEbool() public {
        bytes32 randomHandle = keccak256("random handle allowThis ebool");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).allowThis();
    }

    function testUninitializedHandleIsDisallowed_AllowThisEaddress() public {
        bytes32 randomHandle = keccak256("random handle allowThis eaddress");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        eaddress.wrap(randomHandle).allowThis();
    }

    function testUninitializedHandleIsDisallowed_RevealEuint256() public {
        bytes32 randomHandle = keccak256("random handle reveal euint256");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        euint256.wrap(randomHandle).reveal();
    }

    function testUninitializedHandleIsDisallowed_RevealEbool() public {
        bytes32 randomHandle = keccak256("random handle reveal ebool");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        ebool.wrap(randomHandle).reveal();
    }

    function testUninitializedHandleIsDisallowed_RevealEaddress() public {
        bytes32 randomHandle = keccak256("random handle reveal eaddress");
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        eaddress.wrap(randomHandle).reveal();
    }

    function testUninitializedHandleIsDisallowed_SanitizeEuint256() public {
        bytes32 randomHandle = keccak256("random handle sanitize euint256");
        euint256 a = e.asEuint256(10);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.add(euint256.wrap(randomHandle).s());
    }

    function testUninitializedHandleIsDisallowed_SanitizeEbool() public {
        // Craft handle with valid Bool type byte (0) at bits 8-15
        bytes32 randomHandle = bytes32(uint256(keccak256("random handle sanitize ebool")) & ~(uint256(0xFF) << 8));
        ebool a = e.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.and(ebool.wrap(randomHandle).s());
    }

    function testUninitializedHandleIsDisallowed_SanitizeEaddress() public {
        bytes32 randomHandle = keccak256("random handle sanitize eaddress");
        eaddress a = e.asEaddress(address(0x1));
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, randomHandle, address(this)));
        a.eq(eaddress.wrap(randomHandle).s());
    }

    function testCreateQuote() public view {
        bytes memory mrtd =
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
        address signer = address(0x1234567890123456789012345678901234567890);
        bytes memory quote = createQuote(mrtd, signer);
        TEELifecycle lifecycle = TEELifecycle(address(inco.incoVerifier()));
        Td10ReportBody memory tdReport = lifecycle.parseTd10ReportBody(quote);
        (address reportDataSigner, bytes32 reportMrAggregated) = lifecycle.parseReport(tdReport);
        assertEq(reportDataSigner, signer);
        assertEq(
            reportMrAggregated,
            lifecycle.computeMrAggregated(tdReport.mrTd, tdReport.rtMr0, tdReport.rtMr1, tdReport.rtMr2)
        );
        assertEq(quote.length, MINIMUM_QUOTE_LENGTH);
    }

    function testRandBoundedUpperBoundLargerThanRandType() public {
        euint256 upperBound = e.asEuint256(type(uint256).max);
        uint256 fee = inco.getFee();
        vm.expectRevert(
            abi.encodeWithSelector(
                UnexpectedType.selector, ETypes.Uint256, typeToBitMask(ETypes.AddressOrUint160OrBytes20)
            )
        );
        inco.eRandBounded{value: fee}(euint256.unwrap(upperBound), ETypes.AddressOrUint160OrBytes20);
    }

}
