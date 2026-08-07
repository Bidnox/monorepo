// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Vm} from "forge-std/Test.sol";
import {inco} from "../../Lib.sol";
import {ebool, euint256, ETypes, EOps} from "../../Types.sol";
import {FakeComputeServer} from "./FakeComputeServer.sol";
import {FakeIncoInfraBase} from "./FakeIncoInfraBase.sol";
import {asBytes32} from "../../shared/TypeUtils.sol";
import {getOpForSelector} from "./getOpForSelector.sol";

contract MockOpHandler is FakeIncoInfraBase, FakeComputeServer {

    function processAllOperations() internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(inco)) {
                handleIncoLog(logs[i]);
            }
        }
    }

    function handleIncoLog(Vm.Log memory log) internal {
        bytes32 eventSelector = log.topics[0];
        EOps op = getOpForSelector(eventSelector);
        if (op == EOps.TrivialEncrypt) {
            bytes32 result = log.topics[1];
            (bytes32 plainTextBytes,,) = abi.decode(log.data, (bytes32, ETypes, uint256));
            handleTrivialEncryption(result, plainTextBytes);
        } else if (isBinaryUintOp(op)) {
            bytes32 lhs = log.topics[1];
            bytes32 rhs = log.topics[2];
            bytes32 result = log.topics[3];
            set(result, computeBinaryOp(get(lhs), get(rhs), op));
        } else if (op == EOps.IfThenElse) {
            bytes memory logData = log.data;
            ebool control;
            bytes32 ifTrue = log.topics[1];
            bytes32 ifFalse = log.topics[2];
            bytes32 result = log.topics[3];
            assembly {
                control := mload(add(logData, 0x20))
            }
            handleIfThenElse(control, ifTrue, ifFalse, result);
        } else if (op == EOps.Not) {
            ebool value = ebool.wrap(log.topics[1]);
            ebool result = ebool.wrap(log.topics[2]);
            handleENot(value, result);
        } else if (op == EOps.RandBounded) {
            uint256 counter = uint256(log.topics[1]);
            euint256 upperBound = euint256.wrap(log.topics[2]);
            euint256 result = euint256.wrap(log.topics[3]);
            handleERandBounded(counter, upperBound, result);
        } else if (op == EOps.Cast) {
            bytes32 ct = log.topics[1];
            uint8 toType = uint8(uint256(log.topics[2]));
            bytes32 result = log.topics[3];
            handleECast(ct, toType, result);
        } else if (op == EOps.NewInput) {
            bytes32 result = log.topics[1];
            // contractAddress and user topics are ignored
            (, bytes memory ciphertext,) = abi.decode(log.data, (int32, bytes, uint256));
            handleEInput(result, ciphertext);
        }
    }

    function handleEInput(bytes32 result, bytes memory ciphertext) private {
        ETypes inputType = typeOf(result);
        if (inputType == ETypes.Uint256) {
            set(result, bytes32(fakeDecryptEuint256Ciphertext(ciphertext)));
        } else if (inputType == ETypes.Bool) {
            set(result, asBytes32(fakeDecryptEboolCiphertext(ciphertext)));
        } else if (inputType == ETypes.AddressOrUint160OrBytes20) {
            set(result, bytes32(uint256(fakeDecryptEuint160Ciphertext(ciphertext))));
        } else {
            revert UnsupportedTypeInput(inputType);
        }
    }

    function handleENot(ebool value, ebool result) private {
        set(ebool.unwrap(result), asBytes32(!getBoolValue(value)));
    }

    function handleERandBounded(uint256 counter, euint256 upperBound, euint256 result) private {
        uint256 bound = getUint256Value(upperBound);
        if (bound == 0) {
            // upperBound of 0 means unbounded (used by rand())
            set(euint256.unwrap(result), bytes32(counter));
        } else {
            set(euint256.unwrap(result), bytes32(counter % bound));
        }
    }

    function handleIfThenElse(ebool control, bytes32 lhs, bytes32 rhs, bytes32 result) private {
        set(result, bytes32(getBoolValue(control) ? get(lhs) : get(rhs)));
    }

    function handleECast(bytes32 handle, uint8 toType, bytes32 result) private {
        ETypes _toType = ETypes(toType);
        if (_toType == ETypes.Bool || _toType == ETypes.Uint256 || _toType == ETypes.AddressOrUint160OrBytes20) {
            set(result, get(handle));
        } else {
            revert UnsupportedTypeInput(ETypes(toType));
        }
    }

    function handleTrivialEncryption(bytes32 result, bytes32 plainTextBytes) private {
        set(result, plainTextBytes);
    }

}
