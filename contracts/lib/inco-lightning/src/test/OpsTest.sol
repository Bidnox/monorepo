// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoLightning} from "../IncoLightning.sol";
import {euint256, ebool, eaddress, ETypes} from "../Types.sol";
import {Fee} from "../lightning-parts/Fee.sol";

contract OpsTest is Fee {

    IncoLightning inco;

    constructor(IncoLightning _inco) {
        inco = _inco;
    }

    // ============ ARITHMETIC OPERATIONS ============

    function testAdd(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eAdd(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testAddScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eAdd(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testSub(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eSub(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testSubScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eSub(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testMul(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eMul(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testMulScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eMul(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testDiv(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eDiv(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testDivScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eDiv(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRem(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eRem(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRemScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eRem(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    // ============ BITWISE OPERATIONS ============

    function testAnd(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitAnd(euint256.unwrap(a), euint256.unwrap(b)));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testAndScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitAnd(euint256.unwrap(a), euint256.unwrap(inco.asEuint256(b))));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testAndBool(ebool a, ebool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitAnd(ebool.unwrap(a), ebool.unwrap(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testAndBoolScalar(ebool a, bool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitAnd(ebool.unwrap(a), ebool.unwrap(inco.asEbool(b))));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testOr(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitOr(euint256.unwrap(a), euint256.unwrap(b)));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testOrScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitOr(euint256.unwrap(a), euint256.unwrap(inco.asEuint256(b))));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testOrBool(ebool a, ebool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitOr(ebool.unwrap(a), ebool.unwrap(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testOrBoolScalar(ebool a, bool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitOr(ebool.unwrap(a), ebool.unwrap(inco.asEbool(b))));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testXor(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitXor(euint256.unwrap(a), euint256.unwrap(b)));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testXorScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = euint256.wrap(inco.eBitXor(euint256.unwrap(a), euint256.unwrap(inco.asEuint256(b))));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testXorBool(ebool a, ebool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitXor(ebool.unwrap(a), ebool.unwrap(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testXorBoolScalar(ebool a, bool b) external returns (ebool) {
        ebool result = ebool.wrap(inco.eBitXor(ebool.unwrap(a), ebool.unwrap(inco.asEbool(b))));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testShl(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eShl(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testShlScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eShl(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testShr(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eShr(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testShrScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eShr(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRotl(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eRotl(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRotlScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eRotl(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRotr(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eRotr(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRotrScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eRotr(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    // ============ COMPARISON OPERATIONS ============

    function testEq(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eEq(euint256.unwrap(a), euint256.unwrap(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testEqScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eEq(euint256.unwrap(a), euint256.unwrap(inco.asEuint256(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testEqAddress(eaddress a, eaddress b) external returns (ebool) {
        ebool result = inco.eEq(eaddress.unwrap(a), eaddress.unwrap(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testEqAddressScalar(eaddress a, address b) external returns (ebool) {
        ebool result = inco.eEq(eaddress.unwrap(a), eaddress.unwrap(inco.asEaddress(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testNe(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eNe(euint256.unwrap(a), euint256.unwrap(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testNeScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eNe(euint256.unwrap(a), euint256.unwrap(inco.asEuint256(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testNeAddress(eaddress a, eaddress b) external returns (ebool) {
        ebool result = inco.eNe(eaddress.unwrap(a), eaddress.unwrap(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testNeAddressScalar(eaddress a, address b) external returns (ebool) {
        ebool result = inco.eNe(eaddress.unwrap(a), eaddress.unwrap(inco.asEaddress(b)));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testGe(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eGe(a, b);
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testGeScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eGe(a, inco.asEuint256(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testGt(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eGt(a, b);
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testGtScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eGt(a, inco.asEuint256(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testLe(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eLe(a, b);
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testLeScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eLe(a, inco.asEuint256(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testLt(euint256 a, euint256 b) external returns (ebool) {
        ebool result = inco.eLt(a, b);
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testLtScalar(euint256 a, uint256 b) external returns (ebool) {
        ebool result = inco.eLt(a, inco.asEuint256(b));
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    function testMin(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eMin(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testMinScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eMin(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testMax(euint256 a, euint256 b) external returns (euint256) {
        euint256 result = inco.eMax(a, b);
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testMaxScalar(euint256 a, uint256 b) external returns (euint256) {
        euint256 result = inco.eMax(a, inco.asEuint256(b));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    // ============ LOGICAL OPERATIONS ============

    function testNot(ebool a) external returns (ebool) {
        ebool result = inco.eNot(a);
        inco.allow(ebool.unwrap(result), address(this));
        inco.allow(ebool.unwrap(result), msg.sender);
        return result;
    }

    // ============ RANDOM NUMBER GENERATION ============

    function testRandUnbounded() external payable returns (euint256) {
        euint256 result =
            euint256.wrap(inco.eRandBounded{value: getFee()}(euint256.unwrap(inco.asEuint256(0)), ETypes.Uint256));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRandBounded(uint256 upperBound) external payable returns (euint256) {
        euint256 result = euint256.wrap(
            inco.eRandBounded{value: getFee()}(euint256.unwrap(inco.asEuint256(upperBound)), ETypes.Uint256)
        );
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    function testRandBoundedEncrypted(euint256 upperBound) external payable returns (euint256) {
        euint256 result = euint256.wrap(inco.eRandBounded{value: getFee()}(euint256.unwrap(upperBound), ETypes.Uint256));
        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);
        return result;
    }

    // ============ ENCRYPTED INPUT CREATION ============

    function testNewEuint256(bytes memory ciphertext, address user) external payable returns (euint256) {
        euint256 encryptedUint256 = inco.newEuint256{value: getFee()}(ciphertext, user);
        inco.allow(euint256.unwrap(encryptedUint256), address(this));
        inco.allow(euint256.unwrap(encryptedUint256), user);
        return encryptedUint256;
    }

    function testNewEbool(bytes memory ciphertext, address user) external payable returns (ebool) {
        ebool encryptedBool = inco.newEbool{value: getFee()}(ciphertext, user);
        inco.allow(ebool.unwrap(encryptedBool), address(this));
        inco.allow(ebool.unwrap(encryptedBool), user);
        return encryptedBool;
    }

    function testNewEaddress(bytes memory ciphertext, address user) external payable returns (eaddress) {
        eaddress encryptedAddress = inco.newEaddress{value: getFee()}(ciphertext, user);
        inco.allow(eaddress.unwrap(encryptedAddress), address(this));
        inco.allow(eaddress.unwrap(encryptedAddress), user);
        return encryptedAddress;
    }

    // ============ CAST OPERATIONS ============

    function testCast(bytes32 a, ETypes to) external returns (bytes32) {
        bytes32 result = inco.eCast(a, to);
        inco.allow(result, address(this));
        inco.allow(result, msg.sender);
        return result;
    }

}
