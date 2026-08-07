// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

import {ComplianceGate} from "../../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../../src/ReceivableRegistry.sol";
import {ComplianceActions} from "../../src/libraries/ComplianceActions.sol";

contract BidnoxHandler is Test {
    ComplianceGate public immutable gate;
    ReceivableRegistry public immutable registry;

    address public immutable aUSDC;
    uint256 public immutable complianceSignerKey;
    uint256 public immutable settlementSignerKey;

    address public immutable seller;
    uint256 public immutable buyerKey;
    address public immutable buyer;
    address public immutable lender;

    bytes32[] public ids;
    mapping(bytes32 => bool) public known;

    uint256 public permitNonce;
    uint256 public txNonce;
    uint256 public createdCount;

    mapping(bytes32 => uint8) public highWaterRank;

    constructor(
        ComplianceGate gate_,
        ReceivableRegistry registry_,
        address aUSDC_,
        uint256 complianceSignerKey_,
        uint256 settlementSignerKey_,
        address seller_,
        uint256 buyerKey_,
        address lender_
    ) {
        gate = gate_;
        registry = registry_;
        aUSDC = aUSDC_;
        complianceSignerKey = complianceSignerKey_;
        settlementSignerKey = settlementSignerKey_;
        seller = seller_;
        buyerKey = buyerKey_;
        buyer = vm.addr(buyerKey_);
        lender = lender_;
    }

    function idCount() external view returns (uint256) {
        return ids.length;
    }

    function rankOf(ReceivableRegistry.ReceivableStatus status) public pure returns (uint8) {
        if (status == ReceivableRegistry.ReceivableStatus.None) return 0;
        if (status == ReceivableRegistry.ReceivableStatus.Created) return 1;
        if (status == ReceivableRegistry.ReceivableStatus.BuyerConfirmed) return 2;
        if (status == ReceivableRegistry.ReceivableStatus.AuctionOpen) return 3;
        if (status == ReceivableRegistry.ReceivableStatus.AuctionClosed) return 4;
        if (status == ReceivableRegistry.ReceivableStatus.Funded) return 5;
        if (status == ReceivableRegistry.ReceivableStatus.Overdue) return 6;
        if (status == ReceivableRegistry.ReceivableStatus.Repaid) return 7;
        return 8;
    }

    function _record(bytes32 id) internal {
        uint8 rank = rankOf(registry.statusOf(id));
        if (rank > highWaterRank[id]) highWaterRank[id] = rank;
    }

    function _pick(uint256 seed) internal view returns (bytes32 id, bool ok) {
        if (ids.length == 0) return (bytes32(0), false);
        return (ids[seed % ids.length], true);
    }

    function _sign(uint256 key, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }

    function _permit(address wallet, bytes32 action, bytes32 subjectId)
        internal
        returns (ComplianceGate.CompliancePermit memory permit, bytes memory signature)
    {
        permit = ComplianceGate.CompliancePermit({
            wallet: wallet,
            action: action,
            subjectId: subjectId,
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 100,
            nonce: ++permitNonce
        });
        signature = _sign(complianceSignerKey, gate.hashPermit(permit));
    }

    function createReceivable(uint128 faceValue, uint32 tenor, uint256 refSeed) external {
        faceValue = uint128(bound(faceValue, 1, type(uint96).max));
        tenor = uint32(bound(tenor, 1 days, 365 days));

        ReceivableRegistry.ReceivableInput memory input = ReceivableRegistry.ReceivableInput({
            buyer: buyer,
            invoiceReferenceHash: keccak256(abi.encode(refSeed, ids.length)),
            documentHash: keccak256(abi.encode("doc", refSeed)),
            currency: bytes32("INR"),
            faceValue: faceValue,
            issueDate: uint64(block.timestamp),
            dueDate: uint64(block.timestamp) + tenor,
            settlementAsset: aUSDC
        });

        bytes32 id = registry.computeReceivableId(registry.computeFingerprint(seller, input));
        if (known[id]) return;

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, ComplianceActions.CREATE_RECEIVABLE, id);

        vm.prank(seller);
        registry.createReceivable(input, permit, sig);

        ids.push(id);
        known[id] = true;
        createdCount++;
        _record(id);
    }

    function confirm(uint256 seed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        bytes memory buyerSig = _sign(buyerKey, registry.hashBuyerConfirmation(id));
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(buyer, ComplianceActions.CONFIRM_RECEIVABLE, id);

        registry.confirmReceivable(id, buyerSig, permit, sig);
        _record(id);
    }

    function openAuction(uint256 seed, uint96 auctionId) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        registry.markAuctionOpened(id, uint256(auctionId) + 1);
        _record(id);
    }

    function recordResult(uint256 seed, uint256 advanceSeed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);
        uint256 advance = bound(advanceSeed, 1, r.faceValue);

        registry.recordAuctionResult(id, r.auctionId, lender, advance);
        _record(id);
    }

    function fund(uint256 seed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);

        ReceivableRegistry.SettlementProof memory proof = ReceivableRegistry.SettlementProof({
            receivableId: id,
            txHash: keccak256(abi.encode("fund", id, ++txNonce)),
            from: r.financier,
            to: r.seller,
            asset: aUSDC,
            amount: r.advanceAmount,
            chainId: block.chainid
        });

        registry.recordFunding(proof, _sign(settlementSignerKey, registry.hashSettlementProof(proof)));
        _record(id);
    }

    function repay(uint256 seed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        ReceivableRegistry.Receivable memory r = registry.getReceivable(id);

        ReceivableRegistry.SettlementProof memory proof = ReceivableRegistry.SettlementProof({
            receivableId: id,
            txHash: keccak256(abi.encode("repay", id, ++txNonce)),
            from: r.buyer,
            to: r.financier,
            asset: aUSDC,
            amount: r.faceValue,
            chainId: block.chainid
        });

        registry.recordRepayment(proof, _sign(settlementSignerKey, registry.hashSettlementProof(proof)));
        _record(id);
    }

    function markOverdue(uint256 seed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        registry.markOverdue(id);
        _record(id);
    }

    function cancel(uint256 seed) external {
        (bytes32 id, bool ok) = _pick(seed);
        if (!ok) return;

        vm.prank(seller);
        registry.cancelReceivable(id);
        _record(id);
    }

    function warp(uint32 secs) external {
        vm.warp(block.timestamp + bound(secs, 1, 30 days));
    }
}
