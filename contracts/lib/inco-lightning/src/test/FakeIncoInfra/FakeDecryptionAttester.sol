// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {FakeIncoInfraBase} from "./FakeIncoInfraBase.sol";
import {inco} from "../../Lib.sol";
import {DecryptionAttestation} from "../../lightning-parts/DecryptionAttester.types.sol";
import {AllowanceProof} from "../../lightning-parts/AccessControl/AdvancedAccessControl.sol";
import {SenderNotAllowedForHandle, EOps, ETypes} from "../../Types.sol";
import {FakeComputeServer} from "./FakeComputeServer.sol";

/// @notice simulates the TEE / covalidator offchain API for decryption attestations requests
/// The signing and checking of the decryption request is out of scope of this simulation, it is assumed that when
/// called in tests, it emulates the act of a requester emitting a decryption request
/// One can request decryption attestations on one handle, or on a handle not existing onchain resulting from an
/// operation on existing handles, or on a mix of existing handles and plaintexts values (which get trivial encrypted)
/// as long as the handles are allowed for the requester
contract FakeDecryptionAttester is FakeIncoInfraBase, FakeComputeServer {

    struct HandleWithProof {
        bytes32 handle;
        AllowanceProof proof; // sharer == address(0) means no proof
    }

    // The following 4 functions mimic expected behavior of the TEE / covalidator over offchain API

    /// @notice request decryption attestation for an existing handle
    function getDecryptionAttestation(address requester, HandleWithProof memory handle)
        internal
        returns (DecryptionAttestation memory decryption, bytes[] memory signatures)
    {
        checkAccessControl(requester, handle);
        (decryption, signatures) = _getDecryptionAttestation(handle.handle, get(handle.handle));
    }

    // The following 3 functions are for requesting decryption over a handle resulting of an operation
    // only binary ops are supported for now (2 params)

    /// @notice request decryption attestation for a binary operation on 2 existing handles
    function getDecryptionAttestation(
        address requester,
        HandleWithProof memory lhs,
        HandleWithProof memory rhs,
        EOps op
    ) internal returns (DecryptionAttestation memory decryption, bytes memory signature) {
        checkAccessControl(requester, lhs);
        checkAccessControl(requester, rhs);
        bytes32 result = computeBinaryOp(get(lhs.handle), get(rhs.handle), op);
        (decryption, signature) = _getDecryptionAttestation(lhs.handle, rhs.handle, result, op);
    }

    /// @notice request decryption attestation for a binary operation on a handle and a plaintext value (lhs)
    function getDecryptionAttestation(address requester, uint256 lhs, HandleWithProof memory rhs, EOps op)
        internal
        returns (DecryptionAttestation memory decryption, bytes memory signature)
    {
        checkAccessControl(requester, rhs);
        bytes32 lhsHandle = inco.getTrivialEncryptHandle(bytes32(lhs), ETypes.Uint256);
        bytes32 result = computeBinaryOp(bytes32(lhs), get(rhs.handle), op);
        (decryption, signature) = _getDecryptionAttestation(lhsHandle, rhs.handle, result, op);
    }

    /// @notice request decryption attestation for a binary operation on a handle and a plaintext value (rhs)
    function getDecryptionAttestation(address requester, HandleWithProof memory lhs, uint256 rhs, EOps op)
        internal
        returns (DecryptionAttestation memory decryption, bytes memory signature)
    {
        checkAccessControl(requester, lhs);
        bytes32 rhsHandle = inco.getTrivialEncryptHandle(bytes32(rhs), ETypes.Uint256);

        bytes32 result = computeBinaryOp(get(lhs.handle), bytes32(rhs), op);
        (decryption, signature) = _getDecryptionAttestation(lhs.handle, rhsHandle, result, op);
    }

    /// Private methods ///

    function checkAccessControl(address requester, HandleWithProof memory handle) private {
        if (handle.proof.sharer == address(0)) {
            require(inco.isAllowed(handle.handle, requester), SenderNotAllowedForHandle(handle.handle, requester));
        } else {
            require(
                inco.incoVerifier().isAllowedWithProof(handle.handle, requester, handle.proof),
                SenderNotAllowedForHandle(handle.handle, requester)
            );
        }
    }

    function _getDecryptionAttestation(bytes32 handle, bytes32 value)
        private
        view
        returns (DecryptionAttestation memory decryption, bytes[] memory signatures)
    {
        decryption = DecryptionAttestation({handle: handle, value: value});
        bytes memory signature = signDecryption(decryption);
        signatures = new bytes[](1);
        signatures[0] = signature;
    }

    function signDecryption(DecryptionAttestation memory decryption) private view returns (bytes memory signature) {
        // todo change this to don't call inco and call verifier directly
        bytes32 digest = inco.incoVerifier().decryptionAttestationDigest(decryption);
        signature = getSignatureForDigest(digest, teePrivKey);
    }

    function _getDecryptionAttestation(bytes32 lhsHandle, bytes32 rhsHandle, bytes32 encodedResult, EOps op)
        private
        view
        returns (DecryptionAttestation memory decryption, bytes memory signature)
    {
        ETypes resultType = opToResultType(op);
        decryption = DecryptionAttestation({
            handle: inco.getOpResultHandle(op, resultType, abi.encodePacked(lhsHandle, rhsHandle)), value: encodedResult
        });
        signature = signDecryption(decryption);
    }

}
