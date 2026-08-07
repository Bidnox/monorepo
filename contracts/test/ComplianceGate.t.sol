// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {BidnoxFixture} from "./helpers/BidnoxFixture.sol";
import {ComplianceGate} from "../src/ComplianceGate.sol";
import {ComplianceActions} from "../src/libraries/ComplianceActions.sol";

contract ComplianceGateTest is BidnoxFixture {
    bytes32 internal constant SUBJECT = keccak256("subject");

    function setUp() public {
        _deployCore();

        vm.prank(admin);
        gate.setConsumer(address(this), true);
    }

    function _valid()
        internal
        returns (ComplianceGate.CompliancePermit memory permit, bytes memory signature)
    {
        return _permit(seller, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);
    }

    function _consume(ComplianceGate.CompliancePermit memory permit, bytes memory signature)
        internal
        returns (bool)
    {
        return gate.verifyPermit(permit, signature, seller, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);
    }

    function test_validPermitPasses() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();
        assertTrue(_consume(permit, sig));
        assertTrue(gate.usedNonces(seller, permit.nonce));
    }

    function test_expiredPermitFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();
        vm.warp(permit.expiresAt + 1);

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.Expired)
        );
        _consume(permit, sig);
    }

    function test_permitNotYetValidFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            aUSDC,
            block.timestamp + 100,
            block.timestamp + 200,
            ++permitNonce
        );

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.NotYetValid)
        );
        _consume(permit, sig);
    }

    function test_wrongWalletFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.WalletMismatch)
        );
        gate.verifyPermit(permit, sig, buyer, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);
    }

    function test_wrongActionFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.ActionMismatch)
        );
        gate.verifyPermit(permit, sig, seller, ComplianceActions.BID, SUBJECT);
    }

    function test_wrongSubjectFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.SubjectMismatch)
        );
        gate.verifyPermit(permit, sig, seller, ComplianceActions.CREATE_RECEIVABLE, keccak256("other"));
    }

    function test_wrongAssetFails() public {
        address stale = makeAddr("staleAUSDC");
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            stale,
            block.timestamp,
            block.timestamp + 120,
            ++permitNonce
        );

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.AssetMismatch)
        );
        _consume(permit, sig);
    }

    function test_assetRotationInvalidatesOutstandingPermits() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.prank(admin);
        gate.setSettlementAsset(makeAddr("newAUSDC"));

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.AssetMismatch)
        );
        _consume(permit, sig);
    }

    function test_wrongSignerFails() public {
        ComplianceGate.CompliancePermit memory permit = ComplianceGate.CompliancePermit({
            wallet: seller,
            action: ComplianceActions.CREATE_RECEIVABLE,
            subjectId: SUBJECT,
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 120,
            nonce: ++permitNonce
        });
        bytes memory sig = _signPermitWith(0xDEADBEEF, permit);

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        _consume(permit, sig);
    }

    function test_replayedNonceFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();
        _consume(permit, sig);

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.NonceUsed)
        );
        _consume(permit, sig);
    }

    function test_ttlTooLongFails() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            aUSDC,
            block.timestamp,
            block.timestamp + gate.maxPermitTtl() + 1,
            ++permitNonce
        );

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.TtlTooLong)
        );
        _consume(permit, sig);
    }

    function test_nonConsumerCannotConsume() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(ComplianceGate.NotConsumer.selector, stranger));
        gate.verifyPermit(permit, sig, seller, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);

        assertFalse(gate.usedNonces(seller, permit.nonce), "griefing must not burn the nonce");
    }

    function test_checkPermitDoesNotConsume() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        ComplianceGate.PermitStatus status =
            gate.checkPermit(permit, sig, seller, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);

        assertEq(uint8(status), uint8(ComplianceGate.PermitStatus.Valid));
        assertFalse(gate.usedNonces(seller, permit.nonce));
        assertTrue(_consume(permit, sig), "still consumable after preview");
    }

    function test_checkPermitReportsMalformedSignatureWithoutReverting() public view {
        ComplianceGate.CompliancePermit memory permit = ComplianceGate.CompliancePermit({
            wallet: seller,
            action: ComplianceActions.CREATE_RECEIVABLE,
            subjectId: SUBJECT,
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 120,
            nonce: 1
        });

        ComplianceGate.PermitStatus status =
            gate.checkPermit(permit, hex"1234", seller, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);

        assertEq(uint8(status), uint8(ComplianceGate.PermitStatus.BadSignature));
    }

    function test_onlyOwnerCanConfigure() public {
        address stranger = makeAddr("stranger");

        vm.startPrank(stranger);
        vm.expectRevert();
        gate.setComplianceSigner(stranger);
        vm.expectRevert();
        gate.setSettlementAsset(stranger);
        vm.expectRevert();
        gate.setMaxPermitTtl(60);
        vm.expectRevert();
        gate.setConsumer(stranger, true);
        vm.stopPrank();
    }

    function test_ttlCeilingEnforced() public {
        uint256 ceiling = gate.MAX_PERMIT_TTL();

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ComplianceGate.InvalidTtl.selector, ceiling + 1, ceiling));
        gate.setMaxPermitTtl(ceiling + 1);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ComplianceGate.InvalidTtl.selector, 0, ceiling));
        gate.setMaxPermitTtl(0);

        vm.prank(admin);
        gate.setMaxPermitTtl(ceiling);
        assertEq(gate.maxPermitTtl(), ceiling);
    }

    function test_rotatingSignerInvalidatesOldPermits() public {
        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.prank(admin);
        gate.setComplianceSigner(vm.addr(0xFEED));

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        _consume(permit, sig);
    }

    function testFuzz_onlyExactWalletIsAccepted(address wallet) public {
        vm.assume(wallet != seller);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.WalletMismatch)
        );
        gate.verifyPermit(permit, sig, wallet, ComplianceActions.CREATE_RECEIVABLE, SUBJECT);
    }

    function testFuzz_onlyExactActionIsAccepted(bytes32 action) public {
        vm.assume(action != ComplianceActions.CREATE_RECEIVABLE);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.ActionMismatch)
        );
        gate.verifyPermit(permit, sig, seller, action, SUBJECT);
    }

    function testFuzz_onlyExactSubjectIsAccepted(bytes32 subject) public {
        vm.assume(subject != SUBJECT);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.SubjectMismatch)
        );
        gate.verifyPermit(permit, sig, seller, ComplianceActions.CREATE_RECEIVABLE, subject);
    }

    function testFuzz_onlyComplianceSignerIsAccepted(uint256 key) public {
        key = bound(key, 1, type(uint128).max);
        vm.assume(vm.addr(key) != complianceSigner);

        ComplianceGate.CompliancePermit memory permit = ComplianceGate.CompliancePermit({
            wallet: seller,
            action: ComplianceActions.CREATE_RECEIVABLE,
            subjectId: SUBJECT,
            asset: aUSDC,
            checkedAt: block.timestamp,
            expiresAt: block.timestamp + 120,
            nonce: ++permitNonce
        });
        bytes memory sig = _signPermitWith(key, permit);

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.BadSignature)
        );
        _consume(permit, sig);
    }

    function testFuzz_ttlBoundary(uint256 ttl) public {
        uint256 maxTtl = gate.maxPermitTtl();
        ttl = bound(ttl, 1, maxTtl * 4);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            aUSDC,
            block.timestamp,
            block.timestamp + ttl,
            ++permitNonce
        );

        if (ttl <= maxTtl) {
            assertTrue(_consume(permit, sig));
        } else {
            vm.expectRevert(
                abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.TtlTooLong)
            );
            _consume(permit, sig);
        }
    }

    function testFuzz_permitIsDeadAfterExpiry(uint256 elapsed) public {
        elapsed = bound(elapsed, 0, 3650 days);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _valid();
        uint256 expiresAt = permit.expiresAt;

        vm.warp(block.timestamp + elapsed);

        if (block.timestamp < expiresAt) {
            assertTrue(_consume(permit, sig));
        } else {
            vm.expectRevert(
                abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.Expired)
            );
            _consume(permit, sig);
        }
    }

    function testFuzz_nonceIsSingleUse(uint256 nonce) public {
        nonce = bound(nonce, 1, type(uint128).max);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            aUSDC,
            block.timestamp,
            block.timestamp + 120,
            nonce
        );

        assertTrue(_consume(permit, sig));
        assertTrue(gate.usedNonces(seller, nonce));

        vm.expectRevert(
            abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, ComplianceGate.PermitStatus.NonceUsed)
        );
        _consume(permit, sig);
    }

    function testFuzz_checkPermitAgreesWithVerifyPermit(
        address wallet,
        bytes32 action,
        bytes32 subject,
        uint256 ttl
    ) public {
        ttl = bound(ttl, 1, 600);

        (ComplianceGate.CompliancePermit memory permit, bytes memory sig) = _permitWith(
            seller,
            ComplianceActions.CREATE_RECEIVABLE,
            SUBJECT,
            aUSDC,
            block.timestamp,
            block.timestamp + ttl,
            ++permitNonce
        );

        ComplianceGate.PermitStatus previewed = gate.checkPermit(permit, sig, wallet, action, subject);

        if (previewed == ComplianceGate.PermitStatus.Valid) {
            assertTrue(gate.verifyPermit(permit, sig, wallet, action, subject));
        } else {
            vm.expectRevert(abi.encodeWithSelector(ComplianceGate.PermitRejected.selector, previewed));
            gate.verifyPermit(permit, sig, wallet, action, subject);
        }
    }
}
