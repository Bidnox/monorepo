// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

import {ComplianceGate} from "../../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../../src/ReceivableRegistry.sol";

abstract contract BidnoxFixture is Test {
    ComplianceGate internal gate;
    ReceivableRegistry internal registry;

    address internal admin = makeAddr("admin");
    address internal aUSDC = makeAddr("aUSDC");

    uint256 internal complianceSignerKey = 0xC0FFEE;
    address internal complianceSigner = vm.addr(0xC0FFEE);

    uint256 internal settlementSignerKey = 0xBEEF;
    address internal settlementSigner = vm.addr(0xBEEF);

    uint256 internal sellerKey = 0xA11CE;
    address internal seller = vm.addr(0xA11CE);

    uint256 internal buyerKey = 0xB0B;
    address internal buyer = vm.addr(0xB0B);

    uint256 internal lenderAKey = 0x1111;
    address internal lenderA = vm.addr(0x1111);

    uint256 internal lenderBKey = 0x2222;
    address internal lenderB = vm.addr(0x2222);

    uint256 internal lenderCKey = 0x3333;
    address internal lenderC = vm.addr(0x3333);

    uint256 internal permitNonce;

    function _deployCore() internal {
        gate = new ComplianceGate(admin, complianceSigner, aUSDC);
        registry = new ReceivableRegistry(admin, gate, settlementSigner);

        vm.prank(admin);
        gate.setConsumer(address(registry), true);
    }

    function _permit(address wallet, bytes32 action, bytes32 subjectId)
        internal
        returns (ComplianceGate.CompliancePermit memory permit, bytes memory signature)
    {
        return _permitWith(wallet, action, subjectId, aUSDC, block.timestamp, block.timestamp + 120, ++permitNonce);
    }

    function _permitWith(
        address wallet,
        bytes32 action,
        bytes32 subjectId,
        address asset,
        uint256 checkedAt,
        uint256 expiresAt,
        uint256 nonce
    ) internal view returns (ComplianceGate.CompliancePermit memory permit, bytes memory signature) {
        permit = ComplianceGate.CompliancePermit({
            wallet: wallet,
            action: action,
            subjectId: subjectId,
            asset: asset,
            checkedAt: checkedAt,
            expiresAt: expiresAt,
            nonce: nonce
        });
        signature = _sign(complianceSignerKey, gate.hashPermit(permit));
    }

    function _signPermitWith(uint256 key, ComplianceGate.CompliancePermit memory permit)
        internal
        view
        returns (bytes memory)
    {
        return _sign(key, gate.hashPermit(permit));
    }

    function _defaultInput() internal view returns (ReceivableRegistry.ReceivableInput memory) {
        return ReceivableRegistry.ReceivableInput({
            buyer: buyer,
            invoiceReferenceHash: keccak256("INV-001"),
            documentHash: keccak256("document"),
            currency: bytes32("INR"),
            faceValue: 1_000_000e6,
            issueDate: uint64(block.timestamp),
            dueDate: uint64(block.timestamp + 60 days),
            settlementAsset: aUSDC
        });
    }

    function _createReceivable(ReceivableRegistry.ReceivableInput memory input) internal returns (bytes32 id) {
        bytes32 fingerprint = registry.computeFingerprint(seller, input);
        id = registry.computeReceivableId(fingerprint);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(seller, keccak256("BIDNOX_CREATE_RECEIVABLE"), id);

        vm.prank(seller);
        registry.createReceivable(input, permit, sig);
    }

    function _confirmReceivable(bytes32 id) internal {
        bytes memory buyerSig = _sign(buyerKey, registry.hashBuyerConfirmation(id));

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) =
            _permit(buyer, keccak256("BIDNOX_CONFIRM_RECEIVABLE"), id);

        registry.confirmReceivable(id, buyerSig, permit, sig);
    }

    function _createAndConfirm() internal returns (bytes32 id) {
        id = _createReceivable(_defaultInput());
        _confirmReceivable(id);
    }

    function _proof(bytes32 id, bytes32 txHash, address from, address to, uint256 amount)
        internal
        view
        returns (ReceivableRegistry.SettlementProof memory proof, bytes memory signature)
    {
        proof = ReceivableRegistry.SettlementProof({
            receivableId: id,
            txHash: txHash,
            from: from,
            to: to,
            asset: aUSDC,
            amount: amount,
            chainId: block.chainid
        });
        signature = _sign(settlementSignerKey, registry.hashSettlementProof(proof));
    }

    function _sign(uint256 key, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }
}
