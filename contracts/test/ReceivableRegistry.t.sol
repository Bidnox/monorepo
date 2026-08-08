// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {BidnoxFixture} from "./helpers/BidnoxFixture.sol";
import {ComplianceGate} from "../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../src/ReceivableRegistry.sol";
import {ComplianceActions} from "../src/libraries/ComplianceActions.sol";

contract ReceivableRegistryTest is BidnoxFixture {
    uint256 internal constant FACE = 1_000_000e6;
    uint256 internal constant ADVANCE = 920_000e6;

    function setUp() public {
        _deployCore();

        vm.prank(admin);
        registry.setAuctionContract(address(this));
    }

    function _toAuctionClosed() internal returns (bytes32 id) {
        id = _createAndConfirm();
        registry.markAuctionOpened(id, 1);
        registry.recordAuctionResult(id, 1, lenderC, ADVANCE);
    }

    function _toFunded() internal returns (bytes32 id) {
        id = _toAuctionClosed();
        _fund(id, lenderC, ADVANCE);
    }

    function test_createSucceeds() public {
        bytes32 id = _createReceivable(_defaultInput());

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        assertEq(r.seller, seller);
        assertEq(r.buyer, buyer);
        assertEq(r.faceValue, FACE);
        assertEq(uint8(r.status), uint8(ReceivableRegistry.ReceivableStatus.Created));
        assertTrue(registry.registeredFingerprint(r.fingerprint));
    }

    function test_duplicateFingerprintRejected() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        _createReceivable(input);

        bytes32 fingerprint = registry.computeFingerprint(seller, input);
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, registry.computeReceivableId(fingerprint));

        vm.prank(seller);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.DuplicateFingerprint.selector, fingerprint));
        registry.createReceivable(input, permit, sig);
    }

    function test_documentChangeDoesNotBypassDuplicateFingerprint() public {
        ReceivableRegistry.ReceivableInput memory original = _defaultInput();
        _createReceivable(original);

        ReceivableRegistry.ReceivableInput memory altered = original;
        altered.documentHash = keccak256("same-invoice-different-file");
        bytes32 fingerprint = registry.computeFingerprint(seller, altered);
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, registry.computeReceivableId(fingerprint));

        vm.prank(seller);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.DuplicateFingerprint.selector, fingerprint));
        registry.createReceivable(altered, permit, sig);
    }

    function test_buyerCannotBeSeller() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.buyer = seller;

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, bytes32(0));

        vm.prank(seller);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.BuyerIsSeller.selector, seller));
        registry.createReceivable(input, permit, sig);
    }

    function test_zeroFaceValueRejected() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.faceValue = 0;

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, bytes32(0));

        vm.prank(seller);
        vm.expectRevert(ReceivableRegistry.ZeroFaceValue.selector);
        registry.createReceivable(input, permit, sig);
    }

    function test_pastDueDateRejected() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.dueDate = uint64(block.timestamp);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, bytes32(0));

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(ReceivableRegistry.DueDateNotInFuture.selector, input.dueDate, block.timestamp)
        );
        registry.createReceivable(input, permit, sig);
    }

    function test_unsupportedSettlementAssetRejected() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.settlementAsset = makeAddr("randomToken");

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, bytes32(0));

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(ReceivableRegistry.UnsupportedSettlementAsset.selector, input.settlementAsset, aUSDC)
        );
        registry.createReceivable(input, permit, sig);
    }

    function test_invalidCompliancePermitRejected() public {
        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        bytes32 id = registry.computeReceivableId(registry.computeFingerprint(seller, input));

        ComplianceGate.CompliancePermit memory permit = ComplianceGate.CompliancePermit({
            wallet: seller,
            action: ComplianceActions.CREATE_RECEIVABLE,
            subjectId: id,
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 120,
            nonce: 1
        });
        bytes memory badSig = _signPermitWith(0xBADBAD, permit);

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        registry.createReceivable(input, permit, badSig);
    }

    function test_buyerConfirmationSucceeds() public {
        bytes32 id = _createAndConfirm();
        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.BuyerConfirmed));
    }

    function test_wrongBuyerSignatureRejected() public {
        bytes32 id = _createReceivable(_defaultInput());

        bytes memory wrongSig = _sign(sellerKey, registry.hashBuyerConfirmation(id));
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(buyer, ComplianceActions.CONFIRM_RECEIVABLE, id);

        vm.expectRevert(ReceivableRegistry.InvalidBuyerSignature.selector);
        registry.confirmReceivable(id, wrongSig, permit, sig);
    }

    function test_confirmTwiceRejected() public {
        bytes32 id = _createAndConfirm();

        bytes memory buyerSig = _sign(buyerKey, registry.hashBuyerConfirmation(id));
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(buyer, ComplianceActions.CONFIRM_RECEIVABLE, id);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReceivableRegistry.UnexpectedStatus.selector,
                ReceivableRegistry.ReceivableStatus.BuyerConfirmed,
                ReceivableRegistry.ReceivableStatus.Created
            )
        );
        registry.confirmReceivable(id, buyerSig, permit, sig);
    }

    function test_cannotOpenAuctionBeforeConfirmation() public {
        bytes32 id = _createReceivable(_defaultInput());

        vm.expectRevert(
            abi.encodeWithSelector(
                ReceivableRegistry.UnexpectedStatus.selector,
                ReceivableRegistry.ReceivableStatus.Created,
                ReceivableRegistry.ReceivableStatus.BuyerConfirmed
            )
        );
        registry.markAuctionOpened(id, 1);
    }

    function test_onlyAuctionContractCanOpenOrRecord() public {
        bytes32 id = _createAndConfirm();
        address stranger = makeAddr("stranger");

        vm.startPrank(stranger);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotAuctionContract.selector, stranger));
        registry.markAuctionOpened(id, 1);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotAuctionContract.selector, stranger));
        registry.recordAuctionResult(id, 1, lenderC, ADVANCE);
        vm.stopPrank();
    }

    function test_auctionContractCannotBeRotated() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.AuctionContractAlreadySet.selector, address(this)));
        registry.setAuctionContract(makeAddr("replacementAuction"));
    }

    function test_advanceCannotExceedFaceValue() public {
        bytes32 id = _createAndConfirm();
        registry.markAuctionOpened(id, 1);

        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.AdvanceExceedsFaceValue.selector, FACE + 1, FACE));
        registry.recordAuctionResult(id, 1, lenderC, FACE + 1);
    }

    function test_auctionIdMustMatch() public {
        bytes32 id = _createAndConfirm();
        registry.markAuctionOpened(id, 7);

        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.AuctionMismatch.selector, 7, 8));
        registry.recordAuctionResult(id, 8, lenderC, ADVANCE);
    }

    function test_fundingSucceeds() public {
        uint256 sellerBalanceBefore = token.balanceOf(seller);
        bytes32 id = _toFunded();

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        assertEq(uint8(r.status), uint8(ReceivableRegistry.ReceivableStatus.Funded));
        assertEq(r.financier, lenderC);
        assertEq(token.balanceOf(seller) - sellerBalanceBefore, ADVANCE);
    }

    function test_cannotFundBeforeAuctionCloses() public {
        bytes32 id = _createAndConfirm();

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderC, ComplianceActions.SETTLE, id);
        (ComplianceGate.CompliancePermit memory sellerPermit, bytes memory sellerSig) =
            _permit(seller, ComplianceActions.SETTLE, id);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReceivableRegistry.UnexpectedStatus.selector,
                ReceivableRegistry.ReceivableStatus.BuyerConfirmed,
                ReceivableRegistry.ReceivableStatus.AuctionClosed
            )
        );
        vm.prank(lenderC);
        registry.fundReceivable(id, permit, sig, sellerPermit, sellerSig);
    }

    function test_onlyWinningFinancierCanFund() public {
        bytes32 id = _toAuctionClosed();

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderA, ComplianceActions.SETTLE, id);
        (ComplianceGate.CompliancePermit memory sellerPermit, bytes memory sellerSig) =
            _permit(seller, ComplianceActions.SETTLE, id);
        vm.prank(lenderA);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotFinancier.selector, lenderA, lenderC));
        registry.fundReceivable(id, permit, sig, sellerPermit, sellerSig);
    }

    function test_fundingRequiresFreshSellerEligibilityToo() public {
        bytes32 id = _toAuctionClosed();
        (ComplianceGate.CompliancePermit memory financierPermit, bytes memory financierSig) =
            _permit(lenderC, ComplianceActions.SETTLE, id);
        (ComplianceGate.CompliancePermit memory sellerPermit,) = _permit(seller, ComplianceActions.SETTLE, id);
        bytes memory forgedSellerSig = _signPermitWith(0xDEAD, sellerPermit);

        vm.startPrank(lenderC);
        token.approve(address(registry), ADVANCE);
        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        registry.fundReceivable(id, financierPermit, financierSig, sellerPermit, forgedSellerSig);
        vm.stopPrank();

        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.AuctionClosed));
    }

    function test_repaymentSucceeds() public {
        bytes32 id = _toFunded();
        uint256 lenderBalanceBefore = token.balanceOf(lenderC);
        _repay(id, FACE);

        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.Repaid));
        assertEq(token.balanceOf(lenderC) - lenderBalanceBefore, FACE);
    }

    function test_cannotRepayBeforeFunded() public {
        bytes32 id = _toAuctionClosed();

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permit(buyer, ComplianceActions.REPAY, id);
        (ComplianceGate.CompliancePermit memory financierPermit, bytes memory financierSig) =
            _permit(lenderC, ComplianceActions.REPAY, id);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReceivableRegistry.UnexpectedStatus.selector,
                ReceivableRegistry.ReceivableStatus.AuctionClosed,
                ReceivableRegistry.ReceivableStatus.Funded
            )
        );
        vm.prank(buyer);
        registry.repayReceivable(id, permit, sig, financierPermit, financierSig);
    }

    function test_cannotRepayTwice() public {
        bytes32 id = _toFunded();

        _repay(id, FACE);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permit(buyer, ComplianceActions.REPAY, id);
        (ComplianceGate.CompliancePermit memory financierPermit, bytes memory financierSig) =
            _permit(lenderC, ComplianceActions.REPAY, id);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReceivableRegistry.UnexpectedStatus.selector,
                ReceivableRegistry.ReceivableStatus.Repaid,
                ReceivableRegistry.ReceivableStatus.Funded
            )
        );
        vm.prank(buyer);
        registry.repayReceivable(id, permit, sig, financierPermit, financierSig);
    }

    function test_expiredFundingCanBeReleasedForReauction() public {
        bytes32 id = _toAuctionClosed();
        uint64 deadline = registry.getReceivable(id).fundingDeadline;

        vm.expectRevert(
            abi.encodeWithSelector(ReceivableRegistry.FundingWindowStillOpen.selector, deadline, block.timestamp)
        );
        registry.expireUnfunded(id);

        vm.warp(uint256(deadline) + 1);
        registry.expireUnfunded(id);

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        assertEq(uint8(r.status), uint8(ReceivableRegistry.ReceivableStatus.BuyerConfirmed));
        assertEq(r.financier, address(0));
        assertEq(r.advanceAmount, 0);
    }

    function test_overdueOnlyAfterDueDate() public {
        bytes32 id = _toFunded();
        uint64 dueDate = registry.getReceivable(id).dueDate;

        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotYetDue.selector, dueDate, block.timestamp));
        registry.markOverdue(id);

        vm.warp(uint256(dueDate) + 1);
        registry.markOverdue(id);
        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.Overdue));
    }

    function test_lateRepaymentStillAccepted() public {
        bytes32 id = _toFunded();
        vm.warp(uint256(registry.getReceivable(id).dueDate) + 1);
        registry.markOverdue(id);

        _repay(id, FACE);

        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.Repaid));
    }

    function test_onlySellerCanCancelAndOnlyBeforeConfirmation() public {
        bytes32 id = _createReceivable(_defaultInput());

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotSeller.selector, buyer, seller));
        registry.cancelReceivable(id);

        vm.prank(seller);
        registry.cancelReceivable(id);
        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.Cancelled));
    }

    function test_unknownReceivableReverts() public {
        bytes32 ghost = keccak256("nope");
        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.UnknownReceivable.selector, ghost));
        registry.getReceivable(ghost);
    }

    function testFuzz_createAcceptsAnyValidTerms(uint128 faceValue, uint32 tenor, bytes32 invoiceRef) public {
        vm.assume(faceValue > 0);
        tenor = uint32(bound(tenor, 1, 3650 days));

        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.faceValue = faceValue;
        input.issueDate = uint64(block.timestamp);
        input.dueDate = uint64(block.timestamp + tenor);
        input.invoiceReferenceHash = invoiceRef;

        bytes32 id = _createReceivable(input);

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        assertEq(r.faceValue, faceValue);
        assertEq(r.dueDate, input.dueDate);
        assertEq(uint8(r.status), uint8(ReceivableRegistry.ReceivableStatus.Created));
    }

    function testFuzz_fingerprintIsInjectiveOverReference(bytes32 refA, bytes32 refB) public {
        vm.assume(refA != refB);

        ReceivableRegistry.ReceivableInput memory a = _defaultInput();
        a.invoiceReferenceHash = refA;

        ReceivableRegistry.ReceivableInput memory b = _defaultInput();
        b.invoiceReferenceHash = refB;

        assertTrue(registry.computeFingerprint(seller, a) != registry.computeFingerprint(seller, b));
    }

    function testFuzz_sameInvoiceFromDifferentSellersIsNotADuplicate(address otherSeller) public {
        vm.assume(otherSeller != seller && otherSeller != buyer && otherSeller != address(0));

        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        assertTrue(
            registry.computeFingerprint(seller, input) != registry.computeFingerprint(otherSeller, input),
            "fingerprint must be seller-scoped"
        );
    }

    function testFuzz_advanceWithinFaceValueAlwaysAccepted(uint256 advance) public {
        advance = bound(advance, 1, FACE);

        bytes32 id = _createAndConfirm();
        registry.markAuctionOpened(id, 1);
        registry.recordAuctionResult(id, 1, lenderC, advance);

        assertEq(registry.getReceivable(id).advanceAmount, advance);
    }

    function testFuzz_advanceAboveFaceValueAlwaysRejected(uint256 advance) public {
        advance = bound(advance, FACE + 1, type(uint256).max);

        bytes32 id = _createAndConfirm();
        registry.markAuctionOpened(id, 1);

        vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.AdvanceExceedsFaceValue.selector, advance, FACE));
        registry.recordAuctionResult(id, 1, lenderC, advance);
    }

    function testFuzz_overdueBoundary(uint64 tenor, uint64 elapsed) public {
        tenor = uint64(bound(tenor, 1 days, 365 days));
        elapsed = uint64(bound(elapsed, 0, 730 days));

        ReceivableRegistry.ReceivableInput memory input = _defaultInput();
        input.dueDate = uint64(block.timestamp) + tenor;

        bytes32 id = _createReceivable(input);
        _confirmReceivable(id);
        registry.markAuctionOpened(id, 1);
        registry.recordAuctionResult(id, 1, lenderC, ADVANCE);

        _fund(id, lenderC, ADVANCE);

        uint64 dueDate = input.dueDate;
        vm.warp(block.timestamp + elapsed);

        if (block.timestamp > dueDate) {
            registry.markOverdue(id);
            assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.Overdue));
        } else {
            vm.expectRevert(abi.encodeWithSelector(ReceivableRegistry.NotYetDue.selector, dueDate, block.timestamp));
            registry.markOverdue(id);
        }
    }
}
