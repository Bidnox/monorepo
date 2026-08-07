// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {inco} from "../Lib.sol";
import {euint256, ebool} from "../Types.sol";
import {IncoTest} from "./IncoTest.sol";
import {AddTwo} from "./AddTwo.sol";

contract TestAddTwo is IncoTest {

    AddTwo addTwo;

    function setUp() public override {
        super.setUp();
        addTwo = new AddTwo(inco);
        vm.deal(address(addTwo), 1 ether);
        vm.label(address(addTwo), "addTwo");
    }

    function testAddTwo() public {
        euint256 a = inco.asEuint256(3);
        inco.allow(euint256.unwrap(a), address(addTwo));
        euint256 b = addTwo.addTwo(a);
        processAllOperations();
        assertEq(getUint256Value(b), 5);
    }

    function testAddTwoEoaAndPublicReveal() public {
        (euint256 result, euint256 revealedResult) =
            addTwo.addTwoEoa(fakePrepareEuint256Ciphertext(3, address(this), address(addTwo)));
        processAllOperations();
        assertEq(getUint256Value(result), 5);
        assertEq(getUint256Value(revealedResult), 5);
        assertFalse(inco.isAllowed(euint256.unwrap(result), bob));
        assertTrue(inco.isAllowed(euint256.unwrap(revealedResult), bob));
    }

    function testTrueHandleReveal() public {
        ebool trueVal = addTwo.getTrue();
        processAllOperations();
        assertEq(getBoolValue(trueVal), true);
        assertTrue(inco.isAllowed(ebool.unwrap(trueVal), bob));
    }

}
