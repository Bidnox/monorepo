// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {Version} from "../version/Version.sol";

contract SomeContract is Version {

    constructor() Version(1, 2, 3, bytes32(uint256(12345678)), "SomeContract") {}

}

contract TestVersion is Test {

    SomeContract someContract;

    function setUp() public {
        someContract = new SomeContract();
    }

    function testVersion() public view {
        assertEq(someContract.majorVersion(), 1);
        assertEq(someContract.minorVersion(), 2);
        assertEq(someContract.patchVersion(), 3);
        assertEq(someContract.getName(), "SomeContract");
        assertEq(someContract.getVersion(), "1_2_3");
        assertEq(someContract.getVersionedName(), "SomeContract_1_2_3__12345678");
        assertEq(someContract.salt(), bytes32(uint256(12345678)));
    }

}
