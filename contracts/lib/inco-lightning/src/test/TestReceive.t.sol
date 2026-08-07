// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {inco} from "../Lib.sol";
import {IncoTest} from "./IncoTest.sol";
import {IIncoLightning} from "../interfaces/IIncoLightning.sol";

contract TestReceive is IncoTest {

    function setUp() public override {
        super.setUp();
    }

    function testReceive_Reverts() public {
        uint256 sendAmount = 1 ether;
        vm.deal(alice, sendAmount);
        vm.prank(alice);
        (bool success, bytes memory returnData) = address(inco).call{value: sendAmount}("");

        assertFalse(success, "ETH transfer should revert");
        bytes4 expectedSelector = IIncoLightning.EthInboundTransferUnsupported.selector;
        bytes4 actualSelector;
        assembly {
            actualSelector := mload(add(returnData, 32))
        }
        assertEq(actualSelector, expectedSelector, "Should revert with EthInboundTransferUnsupported");
    }

    function testReceive_ZeroValue_Reverts() public {
        vm.prank(alice);
        (bool success, bytes memory returnData) = address(inco).call{value: 0}("");

        assertFalse(success, "Zero value transfer should also revert");
        bytes4 expectedSelector = IIncoLightning.EthInboundTransferUnsupported.selector;
        bytes4 actualSelector;
        assembly {
            actualSelector := mload(add(returnData, 32))
        }
        assertEq(actualSelector, expectedSelector, "Should revert with EthInboundTransferUnsupported");
    }

}
