// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {FEE, Fee} from "../Fee.sol";
import {IncoTest} from "../../test/IncoTest.sol";
import {inco} from "../../Lib.sol";

contract TestInputsFee is IncoTest {

    function testPayOnInputs() public {
        // should fail if no fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        inco.newEuint256{value: 0}(fakePrepareEuint256Ciphertext(12, address(0), address(this)), address(0));

        // should fail if not enough fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        inco.newEuint256{value: FEE - 1}(fakePrepareEuint256Ciphertext(12, address(0), address(this)), address(0));

        // should fail if too much fee
        vm.expectRevert(Fee.FeeNotPaid.selector);
        inco.newEuint256{value: FEE + 1}(fakePrepareEuint256Ciphertext(12, address(0), address(this)), address(0));

        // should work with exact fee
        inco.newEuint256{value: FEE}(fakePrepareEuint256Ciphertext(12, address(0), address(this)), address(0));
    }

    function testPayForNewEbool() public {
        // should work with exact fee
        inco.newEbool{value: FEE}(fakePrepareEboolCiphertext(true, address(0), address(this)), address(0));
    }

    function testPayForNewEaddress() public {
        // should work with exact fee
        inco.newEaddress{value: FEE}(fakePrepareEaddressCiphertext(address(0), address(0), address(this)), address(0));
    }

}
