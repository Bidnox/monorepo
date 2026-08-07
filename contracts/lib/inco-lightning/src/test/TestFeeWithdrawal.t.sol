// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {inco} from "../Lib.sol";
import {IncoTest} from "./IncoTest.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Fee} from "../lightning-parts/Fee.sol";

contract RejectingContract {
    // Contract that rejects all Ether transfers

    }

contract TestFeeWithdrawal is IncoTest {

    function setUp() public override {
        super.setUp();
    }

    function testWithdrawFees_Succeeds() public {
        vm.deal(address(inco), 1 ether);
        vm.prank(owner);
        inco.withdrawFees();
        assertEq(address(inco).balance, 0);
        assertEq(address(owner).balance, 1 ether);
    }

    function testWithdrawFees_Reverts_NoFeesToWithdraw() public {
        vm.expectRevert(Fee.NoFeesToWithdraw.selector);
        vm.prank(owner);
        inco.withdrawFees();
    }

    function testWithdrawFees_Reverts_NotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        inco.withdrawFees();
    }

    function testWithdrawFees_Reverts_FeeWithdrawalFailed() public {
        // Deploy a contract that rejects Ether
        RejectingContract rejectingOwner = new RejectingContract();

        // Change owner to the rejecting contract
        vm.prank(owner);
        inco.transferOwnership(address(rejectingOwner));

        // Add fees to withdraw
        vm.deal(address(inco), 1 ether);

        // Expect the FeeWithdrawalFailed error
        vm.expectRevert(Fee.FeeWithdrawalFailed.selector);

        // Try to withdraw (will fail because rejectingOwner can't receive Ether)
        vm.prank(address(rejectingOwner));
        inco.withdrawFees();
    }

}
