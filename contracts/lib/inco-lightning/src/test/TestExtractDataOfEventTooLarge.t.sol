// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Test, Vm, console} from "forge-std/Test.sol";

event EventTooLarge( // can't index >3 fields
    bytes32 control,
    bytes32 indexed ifTrue,
    bytes32 indexed ifFalse,
    bytes32 indexed result,
    uint256 eventId
);

contract Emitter {

    function emitEventTooLarge() external {
        emit EventTooLarge(bytes32(uint256(1)), bytes32(uint256(2)), bytes32(uint256(3)), bytes32(uint256(4)), 5);
    }

}

contract TestExtractDataOfEventTooLarge is Test {

    function testEmit() public {
        Emitter emitter = new Emitter();
        vm.recordLogs();
        emitter.emitEventTooLarge();
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.logBytes(logs[0].data);
        bytes32 first32Bytes;
        bytes32 second32Bytes;
        bytes memory logData = logs[0].data;
        assembly {
            first32Bytes := mload(add(logData, 0x20))
            second32Bytes := mload(add(logData, 0x40))
        }
        assertEq(first32Bytes, bytes32(uint256(1)));
        assertEq(second32Bytes, bytes32(uint256(5)));
    }

}
