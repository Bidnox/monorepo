// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {Fee, FEE} from "../Fee.sol";

contract FeeTester is Fee {

    function costOneFee() public payable paying {
        // do nothing
    }

    function costMultipleVariableFees(uint256 nbOfFees) public payable payingMultiple(nbOfFees) {
        // do nothing
    }

    function costMultipleFixedFees() public payable payingMultiple(3) {
        // do nothing
    }

}

contract TestFee is Test {

    FeeTester feeTester;

    function setUp() public {
        feeTester = new FeeTester();
    }

    function testGetFee() public view {
        uint256 fee = feeTester.getFee();
        assertEq(fee, FEE);
    }

    function testPaying() public {
        // should fail if no fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costOneFee{value: 0}();

        // should fail if not enough fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costOneFee{value: FEE - 1}();

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costOneFee{value: FEE + 1}();

        // should work with exact fee
        feeTester.costOneFee{value: FEE}();
    }

    function testPayingMultiple() public {
        // should fail if no fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costMultipleVariableFees{value: 0}(3);

        // should fail if not enough fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costMultipleVariableFees{value: FEE * 3 - 1}(3);

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costMultipleVariableFees{value: FEE * 3 + 1}(3);

        // should work with exact fee
        feeTester.costMultipleVariableFees{value: FEE * 3}(3);

        // should work with exact fee for fixed number of fees
        feeTester.costMultipleFixedFees{value: FEE * 3}();
    }

    function testPayingMultipleZero() public {
        feeTester.costMultipleVariableFees{value: 0}(0);

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costMultipleVariableFees{value: FEE + 1}(0);

        // should work with exact fee
        feeTester.costMultipleVariableFees{value: 0}(0);
    }

    function testFuzzPayingMultipleVariableFees(uint8 nbOfFees) public {
        uint256 expectedValue = FEE * nbOfFees;

        // should work with exact fee
        feeTester.costMultipleVariableFees{value: expectedValue}(nbOfFees);

        // should fail if not enough fee (unless expectedValue is 0)
        if (expectedValue > 0) {
            vm.expectRevert(Fee.FeeNotPaid.selector);
            feeTester.costMultipleVariableFees{value: expectedValue - 1}(nbOfFees);
        }

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        feeTester.costMultipleVariableFees{value: expectedValue + 1}(nbOfFees);
    }

}
