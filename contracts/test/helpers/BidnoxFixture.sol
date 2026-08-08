// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {ComplianceGate} from "../../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../../src/ReceivableRegistry.sol";

abstract contract BidnoxFixture is Test {
    ComplianceGate internal gate;
    ReceivableRegistry internal registry;

    address internal admin = makeAddr("admin");
    ERC20Mock internal token;
    address internal aUSDC;

    uint256 internal complianceSignerKey = 0xC0FFEE;
    address internal complianceSigner = vm.addr(0xC0FFEE);

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
        token = new ERC20Mock();
        aUSDC = address(token);
        gate = new ComplianceGate(admin, complianceSigner, aUSDC);
        registry = new ReceivableRegistry(admin, gate);

        token.mint(lenderA, 10_000_000e6);
        token.mint(lenderB, 10_000_000e6);
        token.mint(lenderC, 10_000_000e6);
        token.mint(buyer, 10_000_000e6);

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

    function _fund(bytes32 id, address financier, uint256 amount) internal {
        (ComplianceGate.CompliancePermit memory financierPermit, bytes memory financierSig) =
            _permit(financier, keccak256("BIDNOX_SETTLE"), id);
        (ComplianceGate.CompliancePermit memory sellerPermit, bytes memory sellerSig) =
            _permit(seller, keccak256("BIDNOX_SETTLE"), id);
        vm.startPrank(financier);
        token.approve(address(registry), amount);
        registry.fundReceivable(id, financierPermit, financierSig, sellerPermit, sellerSig);
        vm.stopPrank();
    }

    function _repay(bytes32 id, uint256 amount) internal {
        (ComplianceGate.CompliancePermit memory buyerPermit, bytes memory buyerSig) =
            _permit(buyer, keccak256("BIDNOX_REPAY"), id);
        (ComplianceGate.CompliancePermit memory financierPermit, bytes memory financierSig) =
            _permit(lenderC, keccak256("BIDNOX_REPAY"), id);
        vm.startPrank(buyer);
        token.approve(address(registry), amount);
        registry.repayReceivable(id, buyerPermit, buyerSig, financierPermit, financierSig);
        vm.stopPrank();
    }

    function _sign(uint256 key, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, digest);
        return abi.encodePacked(r, s, v);
    }
}
