// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "../../../test/IncoTest.sol";
import {SessionVerifier, Session} from "../../../periphery/SessionVerifier.sol";
import {AllowanceVoucher, AllowanceProof} from "../AdvancedAccessControl.sol";
import {REQUIRED_ALLOWANCE_VOUCHER_WARNING} from "../AdvancedAccessControl.types.sol";
import {euint256, SharerNotAllowedForHandle} from "../../../Types.sol";
import {e, inco} from "../../../Lib.sol";
import {AdvancedAccessControl} from "../AdvancedAccessControl.sol";
import {ALLOWANCE_GRANTED_MAGIC_VALUE} from "../../../Types.sol";
import {IIncoVerifier} from "../../../interfaces/IIncoVerifier.sol";
import {BaseAccessControlList} from "../BaseAccessControlList.sol";

contract SomeContractWithConfidentialData {

    using e for bytes;
    using e for euint256;

    euint256 public secret;

    function saveAPersonalSecret(bytes memory ciphertext) public {
        secret = ciphertext.newEuint256(msg.sender);
        secret.allow(msg.sender);
    }

}

contract SomeVerifier {

    struct SharerArg {
        bytes32 handleShared;
        address allowedAccount;
    }

    struct RequesterArg {
        bytes2 mustBeBeef;
    }

    function someCheck(bytes32 handle, address account, bytes memory sharerArgData, bytes memory requesterArgData)
        public
        pure
        returns (bytes32)
    {
        SharerArg memory sharerArg = abi.decode(sharerArgData, (SharerArg));
        RequesterArg memory requesterArg = abi.decode(requesterArgData, (RequesterArg));
        if (
            requesterArg.mustBeBeef == bytes2(0xbeef) && sharerArg.handleShared == handle
                && sharerArg.allowedAccount == account
        ) {
            return ALLOWANCE_GRANTED_MAGIC_VALUE;
        }
        return bytes32(0);
    }

}

contract DoesNotVerifyAnything {

    function someCheck(
        bytes32, /* handle */
        address, /* account */
        bytes memory, /* sharerArgData */
        bytes memory /* requesterArgData */
    )
        public
        pure
        returns (bytes32)
    {
        return ALLOWANCE_GRANTED_MAGIC_VALUE;
    }

}

contract TestAdvancedAccessControl is IncoTest {

    SomeContractWithConfidentialData someContract;
    bytes32 secretHandle;
    IIncoVerifier incoVerifier;

    function setUp() public override {
        super.setUp();
        someContract = new SomeContractWithConfidentialData();
        vm.deal(address(someContract), 100 ether);
        bytes memory secretCt = fakePrepareEuint256Ciphertext(42, alice, address(someContract));
        vm.prank(alice);
        someContract.saveAPersonalSecret(secretCt);
        secretHandle = euint256.unwrap(someContract.secret());
        incoVerifier = inco.incoVerifier();
    }

    function testAdvancedSharingWithInvalidVerifyingContract() public {
        AllowanceVoucher memory invalidSessionVoucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(0),
            callFunction: SessionVerifier.canUseSession.selector,
            sharerArgData: abi.encode(Session({decrypter: bob, expiresAt: block.timestamp + 1 days})),
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory bobsProof = getBobsProof(invalidSessionVoucher);
        vm.expectRevert(abi.encodeWithSelector(AdvancedAccessControl.InvalidVerifyingContract.selector));
        incoVerifier.isAllowedWithProof(secretHandle, bob, bobsProof);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(AdvancedAccessControl.InvalidVerifyingContract.selector));
        inco.claimHandle(secretHandle, bobsProof);
    }

    function testAdvancedSharingWithSession() public {
        SessionVerifier sessionVerifier = new SessionVerifier("");
        assertFalse(inco.isAllowed(secretHandle, bob), "bob should't be allowed on secret yet");
        assertTrue(inco.isAllowed(secretHandle, alice), "alice should be allowed on secret");
        AllowanceVoucher memory aliceSessionVoucherForBob = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(sessionVerifier),
            callFunction: SessionVerifier.canUseSession.selector,
            sharerArgData: abi.encode(Session({decrypter: bob, expiresAt: block.timestamp + 1 days})),
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory bobsProof = getBobsProof(aliceSessionVoucherForBob);
        assertTrue(
            incoVerifier.isAllowedWithProof(secretHandle, bob, bobsProof), "bob should be allowed on secret with proof"
        );
        vm.prank(bob);
        inco.claimHandle(secretHandle, bobsProof);
        assertTrue(inco.persistAllowed(secretHandle, bob), "bob should have claimed persistent allowance on secret");
    }

    function testVoucherSessionIdCheck() public {
        DoesNotVerifyAnything verifier = new DoesNotVerifyAnything();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory bobsFirstProof = getBobsProof(voucher);
        assertTrue(
            incoVerifier.isAllowedWithProof(secretHandle, bob, bobsFirstProof),
            "the initial vouchers session nonce should be 0"
        );
        bytes32 madeUpNonce = bytes32(bytes4(0xdeadbeef));
        voucher = AllowanceVoucher({
            sessionNonce: madeUpNonce,
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory invalidBobProof = getBobsProof(voucher);
        // the session nonce should be checked by inco
        vm.expectRevert(
            abi.encodeWithSelector(AdvancedAccessControl.InvalidVoucherSessionNonce.selector, madeUpNonce, bytes32(0))
        );
        incoVerifier.isAllowedWithProof(secretHandle, bob, invalidBobProof);
        vm.prank(alice);
        bytes32 salt = keccak256(abi.encodePacked("some random value", block.timestamp));
        // update the session nonce to invalidate all previous vouchers
        incoVerifier.updateActiveVouchersSessionNonce(salt);
        bytes32 alicesNewNonce = incoVerifier.getActiveVouchersSessionNonce(alice);
        // previously valid voucher should now be invalid
        vm.expectRevert(
            abi.encodeWithSelector(
                AdvancedAccessControl.InvalidVoucherSessionNonce.selector, bytes32(0), alicesNewNonce
            )
        );
        incoVerifier.isAllowedWithProof(secretHandle, bob, bobsFirstProof);
        voucher = AllowanceVoucher({
            sessionNonce: alicesNewNonce,
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory bobsSecondProof = getBobsProof(voucher);
        assertTrue(
            incoVerifier.isAllowedWithProof(secretHandle, bob, bobsSecondProof),
            "the voucher should signed with the new nonce should be valid"
        );
    }

    function testSessionVerifierAreCorrectlyCalledAsCheckers() public {
        SomeVerifier verifier = new SomeVerifier();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: abi.encode(SomeVerifier.SharerArg({handleShared: secretHandle, allowedAccount: bob})),
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory bobsProof = AllowanceProof({
            sharer: alice,
            voucher: voucher,
            voucherSignature: getAliceSig(voucher),
            requesterArgData: abi.encode(SomeVerifier.RequesterArg({mustBeBeef: bytes2(0xbeef)}))
        });
        assertTrue(
            incoVerifier.isAllowedWithProof(secretHandle, bob, bobsProof), "bob should be allowed on secret with proof"
        );
        bobsProof = AllowanceProof({
            sharer: alice,
            voucher: voucher,
            voucherSignature: getAliceSig(voucher),
            requesterArgData: abi.encode(SomeVerifier.RequesterArg({mustBeBeef: bytes2(0xbebe)}))
        });
        assertFalse(incoVerifier.isAllowedWithProof(secretHandle, bob, bobsProof), "all parameters should be checked");
    }

    function getBobsProof(AllowanceVoucher memory alicesVoucher) private view returns (AllowanceProof memory) {
        bytes memory voucherSignature = getAliceSig(alicesVoucher);
        return AllowanceProof({
            sharer: alice, voucher: alicesVoucher, voucherSignature: voucherSignature, requesterArgData: ""
        });
    }

    function getAliceSig(AllowanceVoucher memory voucher) private view returns (bytes memory) {
        return getSignatureForDigest(incoVerifier.allowanceVoucherDigest(voucher), alicePrivKey);
    }

    /// @notice Test SharerNotAllowedForHandle error when sharer is not allowed
    function testIsAllowedWithProofSharerNotAllowed() public {
        DoesNotVerifyAnything verifier = new DoesNotVerifyAnything();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        // Use bob as sharer, but bob is NOT allowed on the secret (only alice is)
        AllowanceProof memory proof = AllowanceProof({
            sharer: bob,
            voucher: voucher,
            voucherSignature: getSignatureForDigest(incoVerifier.allowanceVoucherDigest(voucher), bobPrivKey),
            requesterArgData: ""
        });
        vm.expectRevert(abi.encodeWithSelector(SharerNotAllowedForHandle.selector, secretHandle, bob));
        incoVerifier.isAllowedWithProof(secretHandle, carol, proof);
    }

    /// @notice Test InvalidVoucherSignature error when signature is invalid
    function testIsAllowedWithProofInvalidSignature() public {
        DoesNotVerifyAnything verifier = new DoesNotVerifyAnything();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        // Alice is the sharer (and is allowed), but we sign with Bob's key
        bytes memory wrongSignature = getSignatureForDigest(incoVerifier.allowanceVoucherDigest(voucher), bobPrivKey);
        AllowanceProof memory proof =
            AllowanceProof({sharer: alice, voucher: voucher, voucherSignature: wrongSignature, requesterArgData: ""});
        bytes32 voucherDigest = incoVerifier.allowanceVoucherDigest(voucher);
        vm.expectRevert(
            abi.encodeWithSelector(
                AdvancedAccessControl.InvalidVoucherSignature.selector, alice, voucherDigest, wrongSignature
            )
        );
        incoVerifier.isAllowedWithProof(secretHandle, bob, proof);
    }

    /// @notice Test InvalidVoucherWarning error when voucher warning does not match required text
    function testIsAllowedWithProofInvalidVoucherWarning() public {
        DoesNotVerifyAnything verifier = new DoesNotVerifyAnything();
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: "",
            warning: "wrong warning"
        });
        AllowanceProof memory proof = AllowanceProof({
            sharer: alice, voucher: voucher, voucherSignature: getAliceSig(voucher), requesterArgData: ""
        });
        vm.expectRevert(abi.encodeWithSelector(AdvancedAccessControl.InvalidVoucherWarning.selector));
        incoVerifier.isAllowedWithProof(secretHandle, bob, proof);
    }

    /// @notice Test claimHandle fails when proof verification fails (line 107)
    function testClaimHandleProofVerificationFailed() public {
        SomeVerifier verifier = new SomeVerifier();
        // Create a voucher that will be valid signature-wise but the verifier will return false
        // because we pass wrong requesterArgData (not 0xbeef)
        AllowanceVoucher memory voucher = AllowanceVoucher({
            sessionNonce: bytes32(0),
            verifyingContract: address(verifier),
            callFunction: verifier.someCheck.selector,
            sharerArgData: abi.encode(SomeVerifier.SharerArg({handleShared: secretHandle, allowedAccount: bob})),
            warning: REQUIRED_ALLOWANCE_VOUCHER_WARNING
        });
        AllowanceProof memory proof = AllowanceProof({
            sharer: alice, // alice IS allowed on the secret
            voucher: voucher,
            voucherSignature: getAliceSig(voucher),
            requesterArgData: abi.encode(SomeVerifier.RequesterArg({mustBeBeef: bytes2(0x1234)})) // WRONG! Not 0xbeef
        });

        // isAllowedWithProof should return false (not revert), then claimHandle should revert
        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                BaseAccessControlList.ProofVerificationFailed.selector,
                address(verifier),
                verifier.someCheck.selector,
                abi.encode(SomeVerifier.SharerArg({handleShared: secretHandle, allowedAccount: bob}))
            )
        );
        inco.claimHandle(secretHandle, proof);
    }

}
