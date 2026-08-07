// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Test} from "forge-std/Test.sol";
import {IncoUtils} from "../periphery/IncoUtils.sol";

/// @dev Helper contract that inherits IncoUtils and rejects ETH refunds
contract RejectingContract is IncoUtils {

    // No receive() function - will reject ETH transfers

    function callWithRefund() external payable refundUnspent {
        // Does nothing, should trigger refund which will fail because this contract can't receive ETH
    }

}

/// @dev Helper contract that sends ETH to the target during execution
contract EthSenderDuringExecution {

    function sendTo(address target, uint256 amount) external {
        payable(target).transfer(amount);
    }

    receive() external payable {}

}

/// @dev Attacker contract that tries to re-enter on receiving refund
contract ReentrantAttacker {

    TestIncoUtils target;
    uint256 public attackCount;

    constructor(TestIncoUtils _target) {
        target = _target;
    }

    function attack() external payable {
        target.mockFunctionNoSpend{value: msg.value}();
    }

    receive() external payable {
        attackCount++;
        if (attackCount < 3) {
            // Try to re-enter
            target.mockFunctionNoSpend{value: msg.value}();
        }
    }

}

contract TestIncoUtils is Test, IncoUtils {

    EthSenderDuringExecution sender;

    function setUp() public {
        sender = new EthSenderDuringExecution();
    }

    // Mock functions to test the modifier
    function mockFunctionNoSpend() external payable refundUnspent {
        // Does nothing, no ETH spent
    }

    function mockFunctionPartialSpend(uint256 amount) external payable refundUnspent {
        // Send ETH to simulate spending
        payable(address(0)).transfer(amount);
    }

    function mockFunctionFullSpend() external payable refundUnspent {
        // Send all msg.value to simulate full spending
        payable(address(0)).transfer(msg.value);
    }

    /// @dev Mock function that receives ETH during execution (simulates external deposit)
    function mockFunctionReceivesEthDuringExecution(address payable ethSender, uint256 incomingAmount)
        external
        payable
        refundUnspent
    {
        // Trigger external contract to send us ETH during execution
        EthSenderDuringExecution(ethSender).sendTo(address(this), incomingAmount);
    }

    receive() external payable {}

    function testRefundUnspentWhenNoSpend() public {
        uint256 msgValue = 1 ether;

        // Set up balance for the call (vm.deal overwrites, not adds)
        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // Call function that doesn't spend any ETH
        this.mockFunctionNoSpend{value: msgValue}();

        // Check that full amount was refunded (balance unchanged)
        assertEq(address(this).balance, balanceBefore);
    }

    function testRefundUnspentWhenPartialSpend() public {
        uint256 msgValue = 1 ether;
        uint256 spendAmount = 0.3 ether;

        // Set up balance for the call
        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // Call function that spends partial amount
        this.mockFunctionPartialSpend{value: msgValue}(spendAmount);

        // Check that correct amount was refunded (only spendAmount was consumed)
        assertEq(address(this).balance, balanceBefore - spendAmount);
    }

    function testRefundUnspentWhenFullSpend() public {
        uint256 msgValue = 1 ether;

        // Set up balance for the call
        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // Call function that spends full amount
        this.mockFunctionFullSpend{value: msgValue}();

        // Check that no refund occurred (all was spent)
        assertEq(address(this).balance, balanceBefore - msgValue);
    }

    function testRefundUnspentWhenOverSpend() public {
        uint256 msgValue = 0.5 ether;
        uint256 spendAmount = 1 ether;

        // Add extra balance to contract beyond what we'll send
        vm.deal(address(this), spendAmount + msgValue);
        uint256 balanceBefore = address(this).balance;

        // Call function that spends more than msg.value (uses contract's existing balance)
        this.mockFunctionPartialSpend{value: msgValue}(spendAmount);

        // Check that no refund occurred (spent more than msg.value, so nothing to refund)
        assertEq(address(this).balance, balanceBefore - spendAmount);
    }

    function testRefundFailedReverts() public {
        uint256 msgValue = 1 ether;

        // Create a contract that cannot receive ETH refunds (no receive function)
        RejectingContract rejecter = new RejectingContract();
        vm.deal(address(rejecter), msgValue);

        // Call from rejecter itself so msg.sender (rejecter) cannot receive the refund
        vm.prank(address(rejecter));
        vm.expectRevert(IncoUtils.RefundFailed.selector);
        rejecter.callWithRefund{value: msgValue}();
    }

    function testRefundUnspentWithZeroMsgValue() public {
        // Set up some initial balance
        vm.deal(address(this), 1 ether);
        uint256 balanceBefore = address(this).balance;

        // Call with zero msg.value - should not revert and no refund needed
        this.mockFunctionNoSpend{value: 0}();

        // Balance should be unchanged
        assertEq(address(this).balance, balanceBefore);
    }

    function testRefundUnspentWithWeiPrecision() public {
        uint256 msgValue = 1000 wei;
        uint256 spendAmount = 333 wei;

        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        this.mockFunctionPartialSpend{value: msgValue}(spendAmount);

        // Check exact wei-level precision
        assertEq(address(this).balance, balanceBefore - spendAmount);
    }

    function testRefundUnspentWhenContractReceivesEthDuringExecution() public {
        uint256 msgValue = 1 ether;
        uint256 incomingEth = 0.5 ether;

        // Fund the sender contract
        vm.deal(address(sender), incomingEth);
        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // During execution, sender will send us 0.5 ETH
        // This means balanceAfter > balanceBefore, so spent = 0
        // Refund should be capped at msg.value (1 ETH)
        this.mockFunctionReceivesEthDuringExecution{value: msgValue}(payable(address(sender)), incomingEth);

        // We sent 1 ETH, received 0.5 ETH during execution, and got 1 ETH refunded
        // Final: balanceBefore - msgValue + incomingEth + msgValue = balanceBefore + incomingEth
        assertEq(address(this).balance, balanceBefore + incomingEth);
    }

    function testRefundUnspentWhenSpendingExactlyMsgValue() public {
        // Edge case: spend exactly msg.value (boundary condition)
        // This is similar to testRefundUnspentWhenFullSpend but uses mockFunctionPartialSpend
        uint256 msgValue = 1 ether;

        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // Spend exactly msg.value using partial spend function
        this.mockFunctionPartialSpend{value: msgValue}(msgValue);

        // No refund should occur - spent exactly what was sent
        assertEq(address(this).balance, balanceBefore - msgValue);
    }

    function testRefundUnspentReentrancyProtection() public {
        ReentrantAttacker attacker = new ReentrantAttacker(this);
        vm.deal(address(attacker), 2 ether);

        // When the attacker tries to re-enter, ReentrantCall() is thrown inside the receive()
        // This causes the receive() to revert, which fails the refund .call(), surfacing RefundFailed()
        vm.prank(address(attacker));
        vm.expectRevert(IncoUtils.RefundFailed.selector);
        attacker.attack{value: 1 ether}();
    }

    function testFuzzRefundUnspent(uint256 msgValue, uint256 spendAmount) public {
        // Bound to reasonable values
        msgValue = bound(msgValue, 0, 10 ether);
        spendAmount = bound(spendAmount, 0, msgValue);

        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        this.mockFunctionPartialSpend{value: msgValue}(spendAmount);

        assertEq(address(this).balance, balanceBefore - spendAmount);
    }

    /// @notice Test reentrancy guard catches direct reentrant call from function body
    function testRefundUnspentReentrancyFromFunctionBody() public {
        vm.expectRevert(IncoUtils.ReentrantCall.selector);
        this.mockFunctionThatReenters{value: 1 ether}();
    }

    function mockFunctionThatReenters() external payable refundUnspent {
        // Try to call another protected function while inside the first one
        this.mockFunctionNoSpend();
    }

    /// @notice Test refund=0 when msg.value equals spent exactly
    function testRefundUnspentWhenMsgValueEqualsSpent() public {
        // This explicitly tests the refund=0 branch when msg.value == spent
        uint256 msgValue = 1 ether;

        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // Spend exactly msg.value, so refund = msg.value - spent = 0
        this.mockFunctionPartialSpend{value: msgValue}(msgValue);

        // All ETH was spent, no refund
        assertEq(address(this).balance, balanceBefore - msgValue);
    }

    /// @notice Test when contract receives more ETH during execution than was sent
    /// This triggers the balanceAfter > balanceBefore branch (spent = 0)
    function testRefundUnspentWhenReceivingMoreThanSent() public {
        uint256 msgValue = 0.5 ether;
        uint256 incomingEth = 1 ether; // More than msg.value

        vm.deal(address(sender), incomingEth);
        vm.deal(address(this), msgValue);
        uint256 balanceBefore = address(this).balance;

        // During execution, we receive 1 ETH (more than we sent)
        this.mockFunctionReceivesEthDuringExecution{value: msgValue}(payable(address(sender)), incomingEth);

        // Execution trace:
        // 1. balanceBefore (modifier) = 0.5 ETH (self-call doesn't change balance)
        // 2. Sender sends 1 ETH during execution
        // 3. balanceAfter (modifier) = 0.5 + 1 = 1.5 ETH
        // 4. spent = balanceBefore > balanceAfter ? ... : 0 = 0 (since 0.5 < 1.5)
        // 5. refund = msg.value - spent = 0.5 - 0 = 0.5 ETH
        // 6. Refund sent to msg.sender (this contract) = self-transfer, no balance change
        // 7. Final balance = 1.5 ETH = balanceBefore (test) + incomingEth
        assertEq(address(this).balance, balanceBefore + incomingEth);
    }

}
