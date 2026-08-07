// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "./IncoTest.sol";
import {inco} from "../Lib.sol";
import {EventCounter} from "../lightning-parts/primitives/EventCounter.sol";

/// @dev Test harness to expose internal getNewEventId() for coverage
contract EventCounterHarness is EventCounter {

    function exposed_getNewEventId() external returns (uint256) {
        return getNewEventId();
    }

}

contract TestEventCounter is IncoTest {

    /// @dev Tests the deprecated getEventCounter() function for coverage.
    /// getEventCounter() is deprecated in favor of getNextEventId().
    function testGetEventCounter_Deprecated() public view {
        // Both functions should return the same value
        uint256 counter = inco.getEventCounter();
        uint256 nextId = inco.getNextEventId();
        assertEq(counter, nextId, "getEventCounter should equal getNextEventId");
    }

    /// @dev Tests getNewEventId() which increments the counter and returns the new ID.
    /// This function is used by lightning-preview's EList operations.
    function testGetNewEventId() public {
        EventCounterHarness harness = new EventCounterHarness();

        uint256 firstId = harness.exposed_getNewEventId();
        assertEq(firstId, 0, "First event ID should be 0");

        uint256 secondId = harness.exposed_getNewEventId();
        assertEq(secondId, 1, "Second event ID should be 1");

        uint256 thirdId = harness.exposed_getNewEventId();
        assertEq(thirdId, 2, "Third event ID should be 2");
    }

}
