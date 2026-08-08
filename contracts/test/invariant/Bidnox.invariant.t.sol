// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {ComplianceGate} from "../../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../../src/ReceivableRegistry.sol";
import {BidnoxHandler} from "./BidnoxHandler.sol";

contract BidnoxInvariantTest is Test {
    ComplianceGate internal gate;
    ReceivableRegistry internal registry;
    BidnoxHandler internal handler;

    address internal admin = makeAddr("admin");
    ERC20Mock internal token;
    address internal aUSDC;

    uint256 internal complianceSignerKey = 0xC0FFEE;
    uint256 internal buyerKey = 0xB0B;

    address internal seller = vm.addr(0xA11CE);
    address internal lender = vm.addr(0x1111);

    function setUp() public {
        token = new ERC20Mock();
        aUSDC = address(token);
        gate = new ComplianceGate(admin, vm.addr(complianceSignerKey), aUSDC);
        registry = new ReceivableRegistry(admin, gate);

        handler = new BidnoxHandler(gate, registry, aUSDC, complianceSignerKey, seller, buyerKey, lender);

        token.mint(lender, type(uint128).max);
        token.mint(vm.addr(buyerKey), type(uint128).max);

        vm.startPrank(admin);
        gate.setConsumer(address(registry), true);
        registry.setAuctionContract(address(handler));
        vm.stopPrank();

        targetContract(address(handler));
    }

    function invariant_statusNeverMovesBackwards() public view {
        uint256 n = handler.idCount();
        for (uint256 i = 0; i < n; i++) {
            bytes32 id = handler.ids(i);
            uint8 current = handler.rankOf(registry.statusOf(id));
            assertGe(current, handler.highWaterRank(id), "receivable status regressed");
        }
    }

    function invariant_advanceNeverExceedsFaceValue() public view {
        uint256 n = handler.idCount();
        for (uint256 i = 0; i < n; i++) {
            ReceivableRegistry.Receivable memory r = registry.getReceivable(handler.ids(i));
            assertLe(r.advanceAmount, r.faceValue, "advance exceeded face value");
        }
    }

    function invariant_fundedImpliesCompleteEvidence() public view {
        uint256 n = handler.idCount();
        for (uint256 i = 0; i < n; i++) {
            ReceivableRegistry.Receivable memory r = registry.getReceivable(handler.ids(i));

            if (
                r.status == ReceivableRegistry.ReceivableStatus.Funded
                    || r.status == ReceivableRegistry.ReceivableStatus.Overdue
                    || r.status == ReceivableRegistry.ReceivableStatus.Repaid
            ) {
                assertTrue(r.financier != address(0), "funded without a financier");
                assertGt(r.advanceAmount, 0, "funded with a zero advance");
                assertGt(r.fundingDeadline, 0, "funded without an auction funding deadline");
            }
        }
    }

    function invariant_fingerprintStaysClaimed() public view {
        uint256 n = handler.idCount();
        for (uint256 i = 0; i < n; i++) {
            ReceivableRegistry.Receivable memory r = registry.getReceivable(handler.ids(i));
            assertTrue(registry.registeredFingerprint(r.fingerprint), "fingerprint was released");
            assertEq(registry.computeReceivableId(r.fingerprint), r.id, "id/fingerprint drift");
        }
    }

    function invariant_partiesAndTermsAreImmutable() public view {
        uint256 n = handler.idCount();
        for (uint256 i = 0; i < n; i++) {
            ReceivableRegistry.Receivable memory r = registry.getReceivable(handler.ids(i));
            assertEq(r.seller, seller, "seller mutated");
            assertEq(r.buyer, handler.buyer(), "buyer mutated");
            assertEq(r.settlementAsset, aUSDC, "settlement asset mutated");
            assertTrue(r.dueDate > r.issueDate, "due date fell behind issue date");
        }
    }

    function invariant_accounting() public view {
        assertEq(handler.idCount(), handler.createdCount(), "receivable accounting drifted");
    }
}
