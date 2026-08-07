// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {e} from "@inco/lightning/src/Lib.testnet.sol";
import {euint256, ebool} from "@inco/lightning/src/Types.sol";
import {DecryptionAttestation} from "@inco/lightning/src/lightning-parts/DecryptionAttester.types.sol";
import {IncoUtils} from "@inco/lightning/src/periphery/IncoUtils.sol";

import {ComplianceGate} from "./ComplianceGate.sol";
import {ReceivableRegistry} from "./ReceivableRegistry.sol";
import {ComplianceActions} from "./libraries/ComplianceActions.sol";

contract ConfidentialAuction is IncoUtils {
    struct Auction {
        bytes32 receivableId;
        uint64 opensAt;
        uint64 closesAt;
        bool revealRequested;
        bool finalized;
        euint256 highestBid;
        euint256 winningBidderIndex;
        uint256 revealedHighestBid;
        address revealedWinner;
    }

    ComplianceGate public immutable complianceGate;
    ReceivableRegistry public immutable registry;

    uint256 public auctionCount;

    mapping(uint256 auctionId => Auction) private _auctions;

    mapping(uint256 auctionId => address[]) public bidders;

    mapping(uint256 auctionId => mapping(address bidder => bool)) public hasBid;

    error InvalidAddress();
    error UnknownAuction(uint256 auctionId);
    error NotSeller(address caller, address seller);
    error ReceivableNotConfirmed(ReceivableRegistry.ReceivableStatus status);
    error CloseTimeInPast(uint64 closesAt, uint256 nowTs);

    error BiddingClosed(uint256 auctionId);
    error AlreadyBid(uint256 auctionId, address bidder);

    error AuctionStillOpen(uint64 closesAt, uint256 nowTs);
    error NoBidders(uint256 auctionId);
    error RevealNotRequested(uint256 auctionId);
    error RevealAlreadyRequested(uint256 auctionId);
    error AlreadyFinalized(uint256 auctionId);
    error NoWinningBid(uint256 auctionId);
    error WinningIndexOutOfRange(uint256 index, uint256 bidderCount);

    event AuctionCreated(
        uint256 indexed auctionId, bytes32 indexed receivableId, address indexed seller, uint64 opensAt, uint64 closesAt
    );
    event BidSubmitted(uint256 indexed auctionId, address indexed bidder);
    event AuctionRevealRequested(uint256 indexed auctionId);
    event AuctionFinalized(uint256 indexed auctionId, address indexed winner, uint256 advanceAmount);

    constructor(ComplianceGate gate, ReceivableRegistry registry_) {
        if (address(gate) == address(0) || address(registry_) == address(0)) revert InvalidAddress();
        complianceGate = gate;
        registry = registry_;
    }

    ////////////////////////////////
    //     EXTERNAL FUNCTIONS     //
    ////////////////////////////////

    function createAuction(bytes32 receivableId, uint64 closesAt) external returns (uint256 auctionId) {
        ReceivableRegistry.Receivable memory r = registry.getReceivable(receivableId);
        if (msg.sender != r.seller) revert NotSeller(msg.sender, r.seller);
        if (r.status != ReceivableRegistry.ReceivableStatus.BuyerConfirmed) revert ReceivableNotConfirmed(r.status);
        if (closesAt <= block.timestamp) revert CloseTimeInPast(closesAt, block.timestamp);

        auctionId = ++auctionCount;

        Auction storage a = _auctions[auctionId];
        a.receivableId = receivableId;
        a.opensAt = uint64(block.timestamp);
        a.closesAt = closesAt;

        a.highestBid = e.asEuint256(0);
        a.winningBidderIndex = e.asEuint256(0);
        e.allowThis(a.highestBid);
        e.allowThis(a.winningBidderIndex);

        registry.markAuctionOpened(receivableId, auctionId);

        emit AuctionCreated(auctionId, receivableId, msg.sender, a.opensAt, closesAt);
    }

    function submitBid(
        uint256 auctionId,
        bytes calldata encryptedBid,
        ComplianceGate.CompliancePermit calldata permit,
        bytes calldata complianceSignature
    ) external payable refundUnspent {
        Auction storage a = _get(auctionId);
        if (a.revealRequested || a.finalized || block.timestamp >= a.closesAt) revert BiddingClosed(auctionId);
        if (hasBid[auctionId][msg.sender]) revert AlreadyBid(auctionId, msg.sender);

        complianceGate.verifyPermit(permit, complianceSignature, msg.sender, ComplianceActions.BID, bytes32(auctionId));

        uint256 index = bidders[auctionId].length;
        hasBid[auctionId][msg.sender] = true;
        bidders[auctionId].push(msg.sender);

        uint256 faceValue = registry.getReceivable(a.receivableId).faceValue;
        euint256 bid = e.min(e.newEuint256(encryptedBid, msg.sender), faceValue);

        ebool isHigher = e.gt(bid, a.highestBid);

        a.highestBid = e.select(isHigher, bid, a.highestBid);
        a.winningBidderIndex = e.select(isHigher, e.asEuint256(index), a.winningBidderIndex);

        e.allowThis(a.highestBid);
        e.allowThis(a.winningBidderIndex);

        emit BidSubmitted(auctionId, msg.sender);
    }

    function closeAuction(uint256 auctionId) external {
        Auction storage a = _get(auctionId);
        if (a.finalized) revert AlreadyFinalized(auctionId);
        if (a.revealRequested) revert RevealAlreadyRequested(auctionId);
        if (block.timestamp < a.closesAt) revert AuctionStillOpen(a.closesAt, block.timestamp);
        if (bidders[auctionId].length == 0) revert NoBidders(auctionId);

        a.revealRequested = true;

        e.reveal(a.highestBid);
        e.reveal(a.winningBidderIndex);

        emit AuctionRevealRequested(auctionId);
    }

    function finalizeAuction(
        uint256 auctionId,
        uint256 highestBid,
        uint256 winningIndex,
        DecryptionAttestation calldata bidAttestation,
        bytes[] calldata bidSignatures,
        DecryptionAttestation calldata indexAttestation,
        bytes[] calldata indexSignatures
    ) external {
        Auction storage a = _get(auctionId);
        if (a.finalized) revert AlreadyFinalized(auctionId);
        if (!a.revealRequested) revert RevealNotRequested(auctionId);

        e.requireEqual(a.highestBid, highestBid, bidAttestation, bidSignatures);
        e.requireEqual(a.winningBidderIndex, winningIndex, indexAttestation, indexSignatures);

        if (highestBid == 0) revert NoWinningBid(auctionId);
        if (winningIndex >= bidders[auctionId].length) {
            revert WinningIndexOutOfRange(winningIndex, bidders[auctionId].length);
        }

        address winner = bidders[auctionId][winningIndex];

        a.finalized = true;
        a.revealedWinner = winner;
        a.revealedHighestBid = highestBid;

        registry.recordAuctionResult(a.receivableId, auctionId, winner, highestBid);

        emit AuctionFinalized(auctionId, winner, highestBid);
    }

    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return _get(auctionId);
    }

    function bidderCount(uint256 auctionId) external view returns (uint256) {
        return bidders[auctionId].length;
    }

    function bidderAt(uint256 auctionId, uint256 index) external view returns (address) {
        return bidders[auctionId][index];
    }

    receive() external payable {}

    ////////////////////////////////
    //     INTERNAL FUNCTIONS     //
    ////////////////////////////////

    function _get(uint256 auctionId) private view returns (Auction storage) {
        if (auctionId == 0 || auctionId > auctionCount) revert UnknownAuction(auctionId);
        return _auctions[auctionId];
    }
}
