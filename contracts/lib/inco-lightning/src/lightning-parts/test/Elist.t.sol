// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "../../test/IncoTest.sol";
import {ElistTester} from "../../test/EListTester.sol";
import {ETypes, ListRangeExceedsType, ListTooLong, elist, typeBitSize} from "../../Types.sol";
import {inco} from "../../Lib.sol";
import {FEE, BIT_FEE, Fee} from "../Fee.sol";
import {EList, MAX_LIST_LENGTH} from "../EList.sol";
import {VerifierAddressGetter} from "../primitives/VerifierAddressGetter.sol";
import {stdError} from "forge-std/StdError.sol";

contract ElistFeeTester is EList {

    constructor() VerifierAddressGetter(address(0)) {}

}

contract TestEList is IncoTest {

    ElistTester tester;
    ElistFeeTester feeTester;

    function setUp() public virtual override {
        super.setUp();
        tester = new ElistTester(inco);
        vm.deal(address(tester), 100 ether);
        vm.deal(address(this), 100 ether);
        feeTester = new ElistFeeTester();
        vm.deal(address(feeTester), 100 ether);
    }

    function _listRange(uint16 start, uint16 end, ETypes listType) internal returns (elist) {
        return inco.listRange{value: uint256(end - start) * typeBitSize(listType) * BIT_FEE}(start, end, listType);
    }

    function _listAppend(elist list, bytes32 value) internal returns (elist) {
        uint256 typeBits = typeBitSize(ETypes.Uint256);
        return inco.listAppend{value: (uint256(inco.lengthOf(elist.unwrap(list))) * typeBits + typeBits) * BIT_FEE}(
            list, value
        );
    }

    function _listInsert(elist list, bytes32 idx, bytes32 val) internal returns (elist) {
        uint256 typeBits = typeBitSize(ETypes.Uint256);
        return inco.listInsert{value: (uint256(inco.lengthOf(elist.unwrap(list))) * typeBits + typeBits) * BIT_FEE}(
            list, idx, val
        );
    }

    function _listConcat(elist a, elist b) internal returns (elist) {
        uint256 bitsA = uint256(inco.lengthOf(elist.unwrap(a))) * typeBitSize(ETypes.Uint256);
        uint256 bitsB = uint256(inco.lengthOf(elist.unwrap(b))) * typeBitSize(ETypes.Uint256);
        return inco.listConcat{value: (bitsA + bitsB) * BIT_FEE}(a, b);
    }

    function _newEList(bytes32[] memory handles, ETypes listType) internal returns (elist) {
        return inco.newEList{value: uint256(handles.length) * typeBitSize(listType) * BIT_FEE}(handles, listType);
    }

    function testNewElistFromInputs() public {
        createList();
        // todo test read the created list
    }

    function testListAppend() public {
        createList();
        bytes memory ctValue = fakePrepareEuint256Ciphertext(40, address(this), address(tester));
        tester.listAppend(ctValue);
    }

    function createList() internal returns (elist list) {
        bytes[] memory inputs = new bytes[](3);
        inputs[0] = fakePrepareEuint256Ciphertext(10, address(this), address(tester));
        inputs[1] = fakePrepareEuint256Ciphertext(20, address(this), address(tester));
        inputs[2] = fakePrepareEuint256Ciphertext(30, address(this), address(tester));
        list = tester.newEList(inputs, ETypes.Uint256, address(this));
    }

    function testRevertsOnBadFeeAmount() public {
        // Construct a handle with length=1, type=Uint256 so fee = 1 * 256 * BIT_FEE
        elist nonZeroList = elist.wrap(bytes32((uint256(1) << 24) | (uint256(uint8(ETypes.Uint256)) << 16)));
        uint256 correctFee = 256 * BIT_FEE;

        // should fail if no fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.listShuffle(nonZeroList);

        // should fail if not enough fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.listShuffle{value: correctFee - 1}(nonZeroList);

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.listShuffle{value: correctFee + 1}(nonZeroList);

        // newEList(inputs): uses payingElistFee, so 3 * 256 * BIT_FEE needed, sending less
        vm.expectRevert(Fee.FeeNotPaid.selector);
        bytes[] memory inputs = new bytes[](3);
        feeTester.newEList{value: 3 * 256 * BIT_FEE - 1}(inputs, ETypes.Uint256, address(this));
    }

    function testListAppend_SucceedsAtMaxLength() public {
        elist almostMaxList = _listRange(0, MAX_LIST_LENGTH - 1, ETypes.Uint256);

        bytes32 validHandle = inco.listGet(almostMaxList, 0);

        elist result = _listAppend(almostMaxList, validHandle);
        assert(elist.unwrap(result) != bytes32(0));
    }

    function testListInsert_SucceedsAtMaxLength() public {
        elist almostMaxList = _listRange(0, MAX_LIST_LENGTH - 1, ETypes.Uint256);

        // Get valid handles from the list (listGet returns handles with transient permissions)
        bytes32 validIndex = inco.listGet(almostMaxList, 0);
        bytes32 validValue = inco.listGet(almostMaxList, 1);

        elist result = _listInsert(almostMaxList, validIndex, validValue);
        assert(elist.unwrap(result) != bytes32(0));
    }

    function testListConcat_SucceedsAtMaxLength() public {
        uint16 half = MAX_LIST_LENGTH / 2;
        uint16 otherHalf = MAX_LIST_LENGTH - half;
        elist list1 = _listRange(0, half, ETypes.Uint256);
        elist list2 = _listRange(0, otherHalf, ETypes.Uint256);

        // Should succeed
        elist combined = _listConcat(list1, list2);
        assert(elist.unwrap(combined) != bytes32(0));
    }

    function testListRange_SucceedsAtMaxLength() public {
        elist maxList = _listRange(0, MAX_LIST_LENGTH, ETypes.Uint256);
        assert(elist.unwrap(maxList) != bytes32(0));
    }

    // Range values [start, end) must fit within listType's bit width.
    // Bool fits values 0..1; end=3 would include value 2 which doesn't fit.
    function testListRange_RevertsOnBoolEndExceedsBitWidth() public {
        vm.expectRevert(abi.encodeWithSelector(ListRangeExceedsType.selector, uint16(3), ETypes.Bool));
        _listRange(0, 3, ETypes.Bool);
    }

    // Range values [start, end) must fit within listType's bit width.
    // end=2 produces {0, 1} — both fit in 1 bit.
    function testListRange_BoolBoundaryAccepted() public {
        elist boolList = _listRange(0, 2, ETypes.Bool);
        assert(elist.unwrap(boolList) != bytes32(0));
    }

    // Range values [start, end) must fit within listType's bit width.
    // Empty range with end at the type's max-exclusive boundary stays valid.
    function testListRange_BoolEmptyRangeAtMaxAccepted() public {
        elist empty = _listRange(2, 2, ETypes.Bool);
        assert(elist.unwrap(empty) != bytes32(0));
    }

    // Range values [start, end) must fit within listType's bit width.
    // uint16 always fits in 160 bits; the new check must not narrow this path.
    function testListRange_Uint160LargeEndAccepted() public {
        elist list = _listRange(0, MAX_LIST_LENGTH, ETypes.AddressOrUint160OrBytes20);
        assert(elist.unwrap(list) != bytes32(0));
    }

    // ==================== Overflow Tests ====================
    // These tests verify that exceeding MAX_LIST_LENGTH reverts appropriately.
    // Operations use uint16 arithmetic which auto-reverts on overflow in Solidity 0.8+.

    function testListAppend_RevertsOnOverflow() public {
        elist maxList = _listRange(0, MAX_LIST_LENGTH, ETypes.Uint256);

        bytes32 validHandle = inco.listGet(maxList, 0);

        // Appending to a max-length list should revert with arithmetic overflow
        // Fee: (65535*256 + 256) * BIT_FEE = 65536*32*FEE
        uint256 typeBits = typeBitSize(ETypes.Uint256);
        vm.expectRevert(stdError.arithmeticError);
        inco.listAppend{value: (uint256(MAX_LIST_LENGTH) * typeBits + typeBits) * BIT_FEE}(maxList, validHandle);
    }

    function testListInsert_RevertsOnOverflow() public {
        elist maxList = _listRange(0, MAX_LIST_LENGTH, ETypes.Uint256);

        bytes32 validIndex = inco.listGet(maxList, 0);
        bytes32 validValue = inco.listGet(maxList, 1);

        // Inserting into a max-length list should revert with arithmetic overflow
        uint256 typeBits = typeBitSize(ETypes.Uint256);
        vm.expectRevert(stdError.arithmeticError);
        inco.listInsert{value: (uint256(MAX_LIST_LENGTH) * typeBits + typeBits) * BIT_FEE}(
            maxList, validIndex, validValue
        );
    }

    function testListConcat_RevertsOnOverflow() public {
        uint16 half = MAX_LIST_LENGTH / 2 + 1;
        elist list1 = _listRange(0, half, ETypes.Uint256);
        elist list2 = _listRange(0, half, ETypes.Uint256);

        // Concatenating should revert with arithmetic overflow
        uint256 bitsPerList = uint256(half) * typeBitSize(ETypes.Uint256);
        vm.expectRevert(stdError.arithmeticError);
        inco.listConcat{value: (bitsPerList + bitsPerList) * BIT_FEE}(list1, list2);
    }

    function testNewEList_RevertsOnTooManyHandles() public {
        uint256 tooMany = uint256(MAX_LIST_LENGTH) + 1;
        bytes32[] memory handles = new bytes32[](tooMany);

        // Fee check runs before length check, so we must pay the required fee
        uint256 requiredFee = tooMany * typeBitSize(ETypes.Uint256) * BIT_FEE;

        // Should revert with ListTooLong error
        vm.expectRevert(abi.encodeWithSelector(ListTooLong.selector, uint32(tooMany), MAX_LIST_LENGTH));
        inco.newEList{value: requiredFee}(handles, ETypes.Uint256);
    }

    function testNewEList_RevertsOnTooManyInputs() public {
        uint256 tooMany = uint256(MAX_LIST_LENGTH) + 1;
        bytes[] memory inputs = new bytes[](tooMany);

        // Fee check runs before length check, so we must pay the required fee
        uint256 requiredFee = tooMany * typeBitSize(ETypes.Uint256) * BIT_FEE;

        // Should revert with ListTooLong error
        vm.expectRevert(abi.encodeWithSelector(ListTooLong.selector, uint32(tooMany), MAX_LIST_LENGTH));
        inco.newEList{value: requiredFee}(inputs, ETypes.Uint256, address(this));
    }

    function testNewEListFromHandles() public {
        elist sourceList = _listRange(0, 3, ETypes.Uint256);

        // Extract handles from the source list
        bytes32[] memory handles = new bytes32[](3);
        handles[0] = inco.listGet(sourceList, 0);
        handles[1] = inco.listGet(sourceList, 1);
        handles[2] = inco.listGet(sourceList, 2);

        // Create a new list from these handles
        elist newList = _newEList(handles, ETypes.Uint256);
        assert(elist.unwrap(newList) != bytes32(0));
    }

}
