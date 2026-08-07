// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IIncoLightning} from "../interfaces/IIncoLightning.sol";
/// forge-lint: disable-next-line(unused-import)
import {ETypes, elist, typeBitSize} from "../Types.sol";
import {euint256} from "../Types.sol";
import {IncoUtils, FEE, BIT_FEE} from "../periphery/IncoUtils.sol";

contract ElistTester is IncoUtils {

    /// forge-lint: disable-next-line(screaming-snake-case-immutable)
    IIncoLightning immutable inco;

    constructor(IIncoLightning _inco) {
        inco = _inco;
    }

    elist public list;
    elist public newRangeList;

    function newEList(bytes[] memory inputs, ETypes listType, address user)
        public
        payable
        refundUnspent
        returns (elist)
    {
        list = inco.newEList{value: FEE * inputs.length}(inputs, listType, user);
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listAppend(bytes memory ctValue) public payable refundUnspent returns (elist) {
        euint256 handle = inco.newEuint256{value: FEE}(ctValue, msg.sender);
        inco.allow(euint256.unwrap(handle), address(this));
        inco.allow(euint256.unwrap(handle), address(msg.sender));
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listAppend{value: (uint256(inco.lengthOf(elist.unwrap(list))) * typeBits + typeBits) * BIT_FEE}(
            list, euint256.unwrap(handle)
        );
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listGet(uint16 index) public returns (bytes32) {
        bytes32 res = inco.listGet(list, index);
        inco.allow(res, msg.sender);
        return res;
    }

    function newEList(bytes32[] memory handles, ETypes listType) public payable refundUnspent returns (elist) {
        list = inco.newEList{value: FEE * handles.length}(handles, listType);
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listGetOr(bytes memory ctIndex, bytes memory ctDefaultValue)
        public
        payable
        refundUnspent
        returns (bytes32)
    {
        euint256 index = inco.newEuint256{value: FEE}(ctIndex, msg.sender);
        euint256 defaultValue = inco.newEuint256{value: FEE}(ctDefaultValue, msg.sender);
        bytes32 res = inco.listGetOr(list, euint256.unwrap(index), euint256.unwrap(defaultValue));
        inco.allow(res, msg.sender);
        return res;
    }

    function listSet(bytes memory ctIndex, bytes memory ctValue) public payable refundUnspent returns (elist) {
        euint256 index = inco.newEuint256{value: FEE}(ctIndex, msg.sender);
        euint256 value = inco.newEuint256{value: FEE}(ctValue, msg.sender);
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listSet{value: uint256(inco.lengthOf(elist.unwrap(list))) * typeBits * BIT_FEE}(
            list, euint256.unwrap(index), euint256.unwrap(value)
        );
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listInsert(bytes memory ctIndex, bytes memory ctValue) public payable refundUnspent returns (elist) {
        euint256 index = inco.newEuint256{value: FEE}(ctIndex, msg.sender);
        euint256 value = inco.newEuint256{value: FEE}(ctValue, msg.sender);
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listInsert{value: (uint256(inco.lengthOf(elist.unwrap(list))) * typeBits + typeBits) * BIT_FEE}(
            list, euint256.unwrap(index), euint256.unwrap(value)
        );
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listConcat(bytes[] memory cts, ETypes listType, address user)
        public
        payable
        refundUnspent
        returns (elist)
    {
        elist rhs = inco.newEList{value: FEE * cts.length}(cts, listType, user);
        inco.allow(elist.unwrap(rhs), address(this));
        inco.allow(elist.unwrap(rhs), address(msg.sender));
        uint256 lhsBits =
            uint256(inco.lengthOf(elist.unwrap(list))) * typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        uint256 rhsBits =
            uint256(inco.lengthOf(elist.unwrap(rhs))) * typeBitSize(ETypes(uint8(uint256(elist.unwrap(rhs)) >> 16)));
        list = inco.listConcat{value: (lhsBits + rhsBits) * BIT_FEE}(list, rhs);
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listSlice(bytes memory ctStart, uint16 len, bytes memory ctDefaultValue)
        public
        payable
        refundUnspent
        returns (elist)
    {
        euint256 start = inco.newEuint256{value: FEE}(ctStart, msg.sender);
        euint256 defaultValue = inco.newEuint256{value: FEE}(ctDefaultValue, msg.sender);
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listSlice{value: uint256(len) * typeBits * BIT_FEE}(
            list, euint256.unwrap(start), len, euint256.unwrap(defaultValue)
        );
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listRange(uint16 start, uint16 end, ETypes listType) public payable returns (elist) {
        newRangeList =
            inco.listRange{value: uint256(end - start) * typeBitSize(listType) * BIT_FEE}(start, end, listType);
        inco.allow(elist.unwrap(newRangeList), address(this));
        inco.allow(elist.unwrap(newRangeList), address(msg.sender));
        return newRangeList;
    }

    function listGetRange(uint16 index) public returns (bytes32) {
        bytes32 res = inco.listGet(newRangeList, index);
        inco.allow(res, msg.sender);
        return res;
    }

    function listShuffle() public payable refundUnspent returns (elist) {
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listShuffle{value: uint256(inco.lengthOf(elist.unwrap(list))) * typeBits * BIT_FEE}(list);
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    function listReveal() public {
        inco.reveal(elist.unwrap(list));
    }

    function listReverse() public payable returns (elist) {
        uint256 typeBits = typeBitSize(ETypes(uint8(uint256(elist.unwrap(list)) >> 16)));
        list = inco.listReverse{value: uint256(inco.lengthOf(elist.unwrap(list))) * typeBits * BIT_FEE}(list);
        inco.allow(elist.unwrap(list), address(this));
        inco.allow(elist.unwrap(list), address(msg.sender));
        return list;
    }

    receive() external payable {
        // Allow contract to receive ETH
    }

}
