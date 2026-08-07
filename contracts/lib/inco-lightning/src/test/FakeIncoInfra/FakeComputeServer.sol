// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {EOps, ETypes} from "../../Types.sol";
import {asBytes32} from "../../shared/TypeUtils.sol";

contract FakeComputeServer {

    function computeBinaryUintOp(uint256 lhs, uint256 rhs, EOps op) internal pure returns (uint256) {
        if (op == EOps.Add) {
            return lhs + rhs;
        } else if (op == EOps.Sub) {
            return lhs - rhs;
        } else if (op == EOps.Mul) {
            return lhs * rhs;
        } else if (op == EOps.Div) {
            return rhs == 0 ? type(uint256).max : lhs / rhs;
        } else if (op == EOps.Rem) {
            return rhs == 0 ? lhs : lhs % rhs;
        } else if (op == EOps.Min) {
            return lhs < rhs ? lhs : rhs;
        } else if (op == EOps.Max) {
            return lhs > rhs ? lhs : rhs;
        } else if (op == EOps.BitAnd) {
            return lhs & rhs;
        } else if (op == EOps.BitOr) {
            return lhs | rhs;
        } else if (op == EOps.BitXor) {
            return lhs ^ rhs;
        } else if (op == EOps.Shl) {
            return lhs << rhs;
        } else if (op == EOps.Shr) {
            return lhs >> rhs;
        } else if (op == EOps.Rotl) {
            return (lhs << rhs) | (lhs >> (256 - rhs));
        } else if (op == EOps.Rotr) {
            return (lhs >> rhs) | (lhs << (256 - rhs));
        } else {
            revert("computeBinaryUintOp Invalid binary uint op");
        }
    }

    function computeBinaryUintToBoolOp(uint256 lhs, uint256 rhs, EOps op) internal pure returns (bool) {
        if (op == EOps.Eq) {
            return lhs == rhs;
        } else if (op == EOps.Ne) {
            return lhs != rhs;
        } else if (op == EOps.Ge) {
            return lhs >= rhs;
        } else if (op == EOps.Gt) {
            return lhs > rhs;
        } else if (op == EOps.Le) {
            return lhs <= rhs;
        } else if (op == EOps.Lt) {
            return lhs < rhs;
        } else {
            revert("computeBinaryUintToBoolOp Invalid binary uint to bool op");
        }
    }

    function isBinaryUintToUintOp(EOps op) internal pure returns (bool) {
        return op == EOps.Add || op == EOps.Sub || op == EOps.Mul || op == EOps.Div || op == EOps.Rem || op == EOps.Min
            || op == EOps.Max || op == EOps.BitAnd || op == EOps.BitOr || op == EOps.BitXor || op == EOps.Shl
            || op == EOps.Shr || op == EOps.Rotl || op == EOps.Rotr;
    }

    function isBinaryUintToBoolOp(EOps op) internal pure returns (bool) {
        return op == EOps.Eq || op == EOps.Ne || op == EOps.Ge || op == EOps.Gt || op == EOps.Le || op == EOps.Lt;
    }

    function opToResultType(EOps op) internal pure returns (ETypes) {
        if (isBinaryUintToUintOp(op)) {
            return ETypes.Uint256;
        } else if (isBinaryUintToBoolOp(op)) {
            return ETypes.Bool;
        } else {
            revert("opToResultType Invalid op");
        }
    }

    function isBinaryUintOp(EOps op) internal pure returns (bool) {
        return isBinaryUintToUintOp(op) || isBinaryUintToBoolOp(op);
    }

    function computeBinaryOp(bytes32 encodedLhs, bytes32 encodedRhs, EOps op) internal pure returns (bytes32) {
        if (isBinaryUintToUintOp(op)) {
            return bytes32(computeBinaryUintOp(uint256(encodedLhs), uint256(encodedRhs), op));
        } else if (isBinaryUintToBoolOp(op)) {
            return asBytes32(computeBinaryUintToBoolOp(uint256(encodedLhs), uint256(encodedRhs), op));
        } else {
            revert("computeBinaryOp Invalid binary op");
        }
    }

}
