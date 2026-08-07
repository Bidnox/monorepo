// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {console} from "forge-std/console.sol";
import {euint256} from "@inco/lightning/src/Types.sol";
import {DecryptionAttestation} from "@inco/lightning/src/lightning-parts/DecryptionAttester.types.sol";

import {inco as auctionInco} from "@inco/lightning/src/Lib.testnet.sol";

import {IncoLocalTest} from "./helpers/IncoLocalTest.sol";
import {BidnoxFixture} from "./helpers/BidnoxFixture.sol";

import {ComplianceGate} from "../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../src/ReceivableRegistry.sol";
import {ConfidentialAuction} from "../src/ConfidentialAuction.sol";
import {ComplianceActions} from "../src/libraries/ComplianceActions.sol";

contract ConfidentialAuctionTest is IncoLocalTest, BidnoxFixture {
    ConfidentialAuction internal auction;

    uint256 internal constant FACE = 1_000_000e6;
    uint64 internal closesAt;

    event BidSubmitted(uint256 indexed auctionId, address indexed bidder);

    function setUp() public override {
        super.setUp();

        if (address(auctionInco).code.length == 0) {
            console.log("");
            console.log("SKIPPED: no Inco Lightning at %s", address(auctionInco));
            console.log("These tests need the local Inco harness. Run them with:");
            console.log("    FOUNDRY_PROFILE=test forge test        (or: make test)");
            console.log("");
            vm.skip(true);
            return;
        }

        _deployCore();

        auction = new ConfidentialAuction(gate, registry);

        vm.startPrank(admin);
        gate.setConsumer(address(auction), true);
        registry.setAuctionContract(address(auction));
        vm.stopPrank();

        vm.deal(address(auction), 1 ether);
        vm.deal(lenderA, 1 ether);
        vm.deal(lenderB, 1 ether);
        vm.deal(lenderC, 1 ether);

        closesAt = uint64(block.timestamp + 1 days);
    }

    function _openAuction() internal returns (bytes32 id, uint256 auctionId) {
        id = _createAndConfirm();
        vm.prank(seller);
        auctionId = auction.createAuction(id, closesAt);
    }

    function _bid(uint256 auctionId, address lender, uint256 amount) internal {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lender, ComplianceActions.BID, bytes32(auctionId));

        bytes memory ciphertext = fakePrepareEuint256Ciphertext(amount, lender, address(auction));

        vm.prank(lender);
        auction.submitBid{value: 0.01 ether}(auctionId, ciphertext, permit, sig);
    }

    function _attest(euint256 handle)
        internal
        returns (uint256 value, DecryptionAttestation memory attestation, bytes[] memory signatures)
    {
        value = getUint256Value(handle);
        (attestation, signatures) = getDecryptionAttestation(
            address(this), HandleWithProof({handle: euint256.unwrap(handle), proof: _emptyAllowanceProof()})
        );
    }

    function _closeAndFinalize(uint256 auctionId) internal returns (address winner, uint256 advance) {
        vm.warp(closesAt);
        auction.closeAuction(auctionId);
        processAllOperations();

        ConfidentialAuction.Auction memory a = auction.getAuction(auctionId);
        (uint256 bidValue, DecryptionAttestation memory bidAtt, bytes[] memory bidSigs) = _attest(a.highestBid);
        (uint256 idxValue, DecryptionAttestation memory idxAtt, bytes[] memory idxSigs) =
            _attest(a.winningBidderIndex);

        auction.finalizeAuction(auctionId, bidValue, idxValue, bidAtt, bidSigs, idxAtt, idxSigs);

        return (auction.getAuction(auctionId).revealedWinner, bidValue);
    }

    function test_auctionCreation() public {
        (bytes32 id, uint256 auctionId) = _openAuction();

        assertEq(auctionId, 1);
        ConfidentialAuction.Auction memory a = auction.getAuction(auctionId);
        assertEq(a.receivableId, id);
        assertEq(a.closesAt, closesAt);
        assertFalse(a.finalized);
        assertEq(uint8(registry.statusOf(id)), uint8(ReceivableRegistry.ReceivableStatus.AuctionOpen));
    }

    function test_onlySellerCanCreateAuction() public {
        bytes32 id = _createAndConfirm();

        vm.prank(buyer);
        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.NotSeller.selector, buyer, seller));
        auction.createAuction(id, closesAt);
    }

    function test_cannotAuctionUnconfirmedReceivable() public {
        bytes32 id = _createReceivable(_defaultInput());

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfidentialAuction.ReceivableNotConfirmed.selector, ReceivableRegistry.ReceivableStatus.Created
            )
        );
        auction.createAuction(id, closesAt);
    }

    function test_closeTimeMustBeInFuture() public {
        bytes32 id = _createAndConfirm();

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfidentialAuction.CloseTimeInPast.selector, uint64(block.timestamp), block.timestamp
            )
        );
        auction.createAuction(id, uint64(block.timestamp));
    }

    function test_cannotOpenTwoAuctionsForSameReceivable() public {
        (bytes32 id,) = _openAuction();

        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(
                ConfidentialAuction.ReceivableNotConfirmed.selector, ReceivableRegistry.ReceivableStatus.AuctionOpen
            )
        );
        auction.createAuction(id, closesAt);
    }

    function test_cannotBidAfterDeadline() public {
        (, uint256 auctionId) = _openAuction();
        vm.warp(closesAt);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderA, ComplianceActions.BID, bytes32(auctionId));
        bytes memory ct = fakePrepareEuint256Ciphertext(1, lenderA, address(auction));

        vm.prank(lenderA);
        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.BiddingClosed.selector, auctionId));
        auction.submitBid{value: 0.01 ether}(auctionId, ct, permit, sig);
    }

    function test_oneBidPerLender() public {
        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, 800_000e6);
        processAllOperations();

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderA, ComplianceActions.BID, bytes32(auctionId));
        bytes memory ct = fakePrepareEuint256Ciphertext(900_000e6, lenderA, address(auction));

        vm.prank(lenderA);
        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.AlreadyBid.selector, auctionId, lenderA));
        auction.submitBid{value: 0.01 ether}(auctionId, ct, permit, sig);
    }

    function test_bidRequiresValidPermit() public {
        (, uint256 auctionId) = _openAuction();

        address lenderD = makeAddr("lenderD");
        vm.deal(lenderD, 1 ether);

        ComplianceGate.CompliancePermit memory forged = ComplianceGate.CompliancePermit({
            wallet: lenderD,
            action: ComplianceActions.BID,
            subjectId: bytes32(auctionId),
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 120,
            nonce: 999
        });
        bytes memory forgedSig = _signPermitWith(0xD00D, forged);
        bytes memory ct = fakePrepareEuint256Ciphertext(999_000e6, lenderD, address(auction));

        vm.prank(lenderD);
        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        auction.submitBid{value: 0.01 ether}(auctionId, ct, forged, forgedSig);

        assertEq(auction.bidderCount(auctionId), 0, "unverified lender must not be recorded");
    }

    function test_bidPermitIsBoundToItsAuction() public {
        (, uint256 auctionId) = _openAuction();

        ReceivableRegistry.ReceivableInput memory other = _defaultInput();
        other.invoiceReferenceHash = keccak256("INV-002");
        bytes32 otherId = _createReceivable(other);
        _confirmReceivable(otherId);

        vm.prank(seller);
        uint256 otherAuction = auction.createAuction(otherId, closesAt);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderA, ComplianceActions.BID, bytes32(otherAuction));
        bytes memory ct = fakePrepareEuint256Ciphertext(500_000e6, lenderA, address(auction));

        vm.prank(lenderA);
        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.SubjectMismatch)
        );
        auction.submitBid{value: 0.01 ether}(auctionId, ct, permit, sig);
    }

    function test_bidEventLeaksNoAmount() public {
        (, uint256 auctionId) = _openAuction();

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(lenderA, ComplianceActions.BID, bytes32(auctionId));
        bytes memory ct = fakePrepareEuint256Ciphertext(880_000e6, lenderA, address(auction));

        vm.expectEmit(true, true, true, true, address(auction));
        emit BidSubmitted(auctionId, lenderA);

        vm.prank(lenderA);
        auction.submitBid{value: 0.01 ether}(auctionId, ct, permit, sig);
    }

    function test_highestBidderWins() public {
        (bytes32 id, uint256 auctionId) = _openAuction();

        _bid(auctionId, lenderA, 880_000e6);
        _bid(auctionId, lenderB, 900_000e6);
        _bid(auctionId, lenderC, 920_000e6);
        processAllOperations();

        (address winner, uint256 advance) = _closeAndFinalize(auctionId);

        assertEq(winner, lenderC);
        assertEq(advance, 920_000e6);

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        assertEq(uint8(r.status), uint8(ReceivableRegistry.ReceivableStatus.AuctionClosed));
        assertEq(r.financier, lenderC, "winner must be forwarded to the registry");
        assertEq(r.advanceAmount, 920_000e6);
    }

    function test_bidOrderDoesNotMatter() public {
        (, uint256 auctionId) = _openAuction();

        _bid(auctionId, lenderC, 920_000e6);
        _bid(auctionId, lenderA, 880_000e6);
        _bid(auctionId, lenderB, 900_000e6);
        processAllOperations();

        (address winner, uint256 advance) = _closeAndFinalize(auctionId);
        assertEq(winner, lenderC);
        assertEq(advance, 920_000e6);
    }

    function test_equalBidsAreDeterministicFirstBidderWins() public {
        (, uint256 auctionId) = _openAuction();

        _bid(auctionId, lenderA, 900_000e6);
        _bid(auctionId, lenderB, 900_000e6);
        _bid(auctionId, lenderC, 900_000e6);
        processAllOperations();

        (address winner, uint256 advance) = _closeAndFinalize(auctionId);
        assertEq(winner, lenderA, "strict greater-than means the first bidder keeps the lead");
        assertEq(advance, 900_000e6);
    }

    function test_bidAboveFaceValueIsClampedNotRejected() public {
        (, uint256 auctionId) = _openAuction();

        _bid(auctionId, lenderA, FACE * 3);
        processAllOperations();

        (address winner, uint256 advance) = _closeAndFinalize(auctionId);
        assertEq(winner, lenderA);
        assertEq(advance, FACE, "over-face offer clamps to face value so finalisation cannot brick");
    }

    function test_cannotCloseBeforeDeadline() public {
        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, 900_000e6);
        processAllOperations();

        vm.expectRevert(
            abi.encodeWithSelector(ConfidentialAuction.AuctionStillOpen.selector, closesAt, block.timestamp)
        );
        auction.closeAuction(auctionId);
    }

    function test_cannotCloseWithNoBidders() public {
        (, uint256 auctionId) = _openAuction();
        vm.warp(closesAt);

        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.NoBidders.selector, auctionId));
        auction.closeAuction(auctionId);
    }

    function test_cannotFinalizeBeforeReveal() public {
        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, 900_000e6);
        processAllOperations();
        vm.warp(closesAt);

        DecryptionAttestation memory empty;
        bytes[] memory noSigs;

        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.RevealNotRequested.selector, auctionId));
        auction.finalizeAuction(auctionId, 900_000e6, 0, empty, noSigs, empty, noSigs);
    }

    function test_onlyCorrectRevealIsAccepted() public {
        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, 880_000e6);
        _bid(auctionId, lenderB, 920_000e6);
        processAllOperations();

        vm.warp(closesAt);
        auction.closeAuction(auctionId);
        processAllOperations();

        ConfidentialAuction.Auction memory a = auction.getAuction(auctionId);
        (uint256 bidValue, DecryptionAttestation memory bidAtt, bytes[] memory bidSigs) = _attest(a.highestBid);
        (, DecryptionAttestation memory idxAtt, bytes[] memory idxSigs) = _attest(a.winningBidderIndex);

        vm.expectRevert();
        auction.finalizeAuction(auctionId, bidValue, 0, bidAtt, bidSigs, idxAtt, idxSigs);

        vm.expectRevert();
        auction.finalizeAuction(auctionId, bidValue + 1, 1, bidAtt, bidSigs, idxAtt, idxSigs);
    }

    function test_cannotFinalizeTwice() public {
        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, 900_000e6);
        processAllOperations();

        _closeAndFinalize(auctionId);

        ConfidentialAuction.Auction memory a = auction.getAuction(auctionId);
        (uint256 bidValue, DecryptionAttestation memory bidAtt, bytes[] memory bidSigs) = _attest(a.highestBid);
        (uint256 idxValue, DecryptionAttestation memory idxAtt, bytes[] memory idxSigs) =
            _attest(a.winningBidderIndex);

        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.AlreadyFinalized.selector, auctionId));
        auction.finalizeAuction(auctionId, bidValue, idxValue, bidAtt, bidSigs, idxAtt, idxSigs);
    }

    function test_unknownAuctionReverts() public {
        vm.expectRevert(abi.encodeWithSelector(ConfidentialAuction.UnknownAuction.selector, 42));
        auction.getAuction(42);
    }

    function testFuzz_highestOfThreeSealedBidsWins(uint256 a, uint256 b, uint256 c) public {
        a = bound(a, 1, FACE);
        b = bound(b, 1, FACE);
        c = bound(c, 1, FACE);

        (, uint256 auctionId) = _openAuction();

        _bid(auctionId, lenderA, a);
        _bid(auctionId, lenderB, b);
        _bid(auctionId, lenderC, c);
        processAllOperations();

        (address winner, uint256 advance) = _closeAndFinalize(auctionId);

        uint256 expectedMax = a;
        address expectedWinner = lenderA;
        if (b > expectedMax) {
            expectedMax = b;
            expectedWinner = lenderB;
        }
        if (c > expectedMax) {
            expectedMax = c;
            expectedWinner = lenderC;
        }

        assertEq(advance, expectedMax, "winning advance must be the maximum offer");
        assertEq(winner, expectedWinner, "ties resolve to the earliest bidder");
    }

    function testFuzz_advanceNeverExceedsFaceValue(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);

        (bytes32 id, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, amount);
        processAllOperations();

        (, uint256 advance) = _closeAndFinalize(auctionId);

        assertLe(advance, FACE);
        assertEq(registry.getReceivable(id).advanceAmount, advance);
    }

    function testFuzz_winnerIsAlwaysARecordedBidder(uint256 a, uint256 b) public {
        a = bound(a, 1, FACE);
        b = bound(b, 1, FACE);

        (, uint256 auctionId) = _openAuction();
        _bid(auctionId, lenderA, a);
        _bid(auctionId, lenderB, b);
        processAllOperations();

        (address winner,) = _closeAndFinalize(auctionId);

        assertTrue(winner == lenderA || winner == lenderB);
        assertTrue(auction.hasBid(auctionId, winner));
    }
}
