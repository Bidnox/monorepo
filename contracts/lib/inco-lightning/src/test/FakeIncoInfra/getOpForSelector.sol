// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {BaseAccessControlList} from "../../lightning-parts/AccessControl/BaseAccessControlList.sol";
import {EncryptedOperations} from "../../lightning-parts/EncryptedOperations.sol";
import {TrivialEncryption} from "../../lightning-parts/TrivialEncryption.sol";
import {EncryptedInput} from "../../lightning-parts/EncryptedInput.sol";
import {EOps} from "../../Types.sol";

// letting this func alone in its file as multiple of this type gets unreadable fast
function getOpForSelector(bytes32 opEventSelector) pure returns (EOps) {
    if (opEventSelector == EncryptedOperations.EAdd.selector) {
        return EOps.Add;
    } else if (opEventSelector == EncryptedOperations.ESub.selector) {
        return EOps.Sub;
    } else if (opEventSelector == EncryptedOperations.EMul.selector) {
        return EOps.Mul;
    } else if (opEventSelector == EncryptedOperations.EDiv.selector) {
        return EOps.Div;
    } else if (opEventSelector == EncryptedOperations.ERem.selector) {
        return EOps.Rem;
    } else if (opEventSelector == EncryptedOperations.EBitAnd.selector) {
        return EOps.BitAnd;
    } else if (opEventSelector == EncryptedOperations.EBitOr.selector) {
        return EOps.BitOr;
    } else if (opEventSelector == EncryptedOperations.EBitXor.selector) {
        return EOps.BitXor;
    } else if (opEventSelector == EncryptedOperations.EShl.selector) {
        return EOps.Shl;
    } else if (opEventSelector == EncryptedOperations.EShr.selector) {
        return EOps.Shr;
    } else if (opEventSelector == EncryptedOperations.ERotl.selector) {
        return EOps.Rotl;
    } else if (opEventSelector == EncryptedOperations.ERotr.selector) {
        return EOps.Rotr;
    } else if (opEventSelector == EncryptedOperations.EEq.selector) {
        return EOps.Eq;
    } else if (opEventSelector == EncryptedOperations.ENe.selector) {
        return EOps.Ne;
    } else if (opEventSelector == EncryptedOperations.EGe.selector) {
        return EOps.Ge;
    } else if (opEventSelector == EncryptedOperations.EGt.selector) {
        return EOps.Gt;
    } else if (opEventSelector == EncryptedOperations.ELe.selector) {
        return EOps.Le;
    } else if (opEventSelector == EncryptedOperations.ELt.selector) {
        return EOps.Lt;
    } else if (opEventSelector == EncryptedOperations.EMin.selector) {
        return EOps.Min;
    } else if (opEventSelector == EncryptedOperations.EMax.selector) {
        return EOps.Max;
    } else if (opEventSelector == EncryptedOperations.ENot.selector) {
        return EOps.Not;
    } else if (opEventSelector == EncryptedInput.NewInput.selector) {
        return EOps.NewInput;
    } else if (opEventSelector == EncryptedOperations.ECast.selector) {
        return EOps.Cast;
    } else if (opEventSelector == TrivialEncryption.TrivialEncrypt.selector) {
        return EOps.TrivialEncrypt;
    } else if (opEventSelector == EncryptedOperations.EIfThenElse.selector) {
        return EOps.IfThenElse;
    } else if (opEventSelector == EncryptedOperations.ERandBounded.selector) {
        return EOps.RandBounded;
    } else if (opEventSelector == BaseAccessControlList.Allow.selector) {
        return EOps.Allow;
    } else if (opEventSelector == BaseAccessControlList.Reveal.selector) {
        return EOps.Reveal;
    } else {
        revert("getOpForSelector: Unsupported selector");
    }
}
