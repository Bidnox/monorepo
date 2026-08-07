// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {TestUtils} from "../../shared/TestUtils.sol";
import {HEADER_LENGTH, MINIMUM_QUOTE_LENGTH, TDX_TEE} from "../../interfaces/automata-interfaces/Types.sol";
import {BootstrapResult} from "../../lightning-parts/TEELifecycle.types.sol";
import {ITEELifecycle} from "../../lightning-parts/interfaces/ITEELifecycle.sol";

contract MockRemoteAttestation is TestUtils {

    /**
     * @notice Creates a mock quote for the given MRTD and signer
     * The RTMR0, RTMR1, RTMR2 are set to zeros
     * @dev This function is the same as the non-TDX version of
     * get_tdx_quote in attestation/src/remote_attestation.rs
     */
    function createQuote(bytes memory mrtd, address signer) public pure returns (bytes memory quote) {
        // Mock implementation of quote creation
        require(mrtd.length == 48, "MRTD should be 48 bytes");
        /* Quote structure:
            - version ([0:4], 4 bytes long)
            - teeType ([4:8], 4 bytes long)
            - prefix ([8:HEADER_LENGTH+136], HEADER_LENGTH+136 - 8 bytes long)
            - mrtd ([HEADER_LENGTH+136:HEADER_LENGTH+184], 48 bytes long)
            - middle ([HEADER_LENGTH+184:HEADER_LENGTH+520], 336 bytes long)
            - reportData ([HEADER_LENGTH+520:HEADER_LENGTH+584], 64 bytes long)
                - signer ([HEADER_LENGTH+520:HEADER_LENGTH+540], 20 bytes long)
                - reportDataSuffix ([HEADER_LENGTH+540:HEADER_LENGTH+584], 44 bytes long)
           - suffix ([HEADER_LENGTH+584:MINIMUM_QUOTE_LENGTH], remaining bytes to reach MINIMUM_QUOTE_LENGTH)

        */
        bytes4 version = 0x04000000; // Version 4
        bytes4 tdxTeeType = TDX_TEE; // TDX TEETYPE
        bytes memory prefix = new bytes(HEADER_LENGTH + 136 - 8);
        bytes memory middle = new bytes(520 - 184);
        bytes memory reportDataSuffix = new bytes(44);
        bytes memory suffix = new bytes(MINIMUM_QUOTE_LENGTH - HEADER_LENGTH - 584);
        quote = abi.encodePacked(
            version, tdxTeeType, prefix, mrtd, middle, abi.encodePacked(signer), reportDataSuffix, suffix
        );
    }

    // Helper function to create a successful bootstrap result
    function successfulBootstrapResult(
        ITEELifecycle teeLifecycle,
        bytes memory networkPubkey,
        address signer,
        uint256 signerPrivKey
    )
        internal
        returns (
            BootstrapResult memory bootstrapResult,
            bytes memory quote,
            bytes memory signature,
            bytes32 mrAggregated
        )
    {
        // See DEFAULT_MRTD in attestation/src/remote_attestation.rs
        bytes memory mrtd =
            hex"010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101";
        // See DEFAULT_MR_AGGREGATED in attestation/src/remote_attestation.rs to
        // see the calculation of the default value.
        // Note: This uses abi.encode (not encodePacked) to avoid hash collision vulnerabilities.
        mrAggregated = hex"3d48a1faa8620d86ae037f4fd6746987733d085314b3cd5d5d074ade8bab6ebd";
        bootstrapResult = BootstrapResult({networkPubkey: networkPubkey});

        quote = createQuote(mrtd, signer);
        signature = signBootstrapResult(bootstrapResult, signerPrivKey, teeLifecycle);
        // We set the signer address and priv key as part of the bootstrap for non-tee setups
        teeEOA = signer;
        teePrivKey = signerPrivKey;
    }

    // Helper function to sign the bootstrap result
    function signBootstrapResult(BootstrapResult memory bootstrapResult, uint256 privateKey, ITEELifecycle teeLifecycle)
        internal
        view
        returns (bytes memory)
    {
        bytes32 bootstrapResultDigest = teeLifecycle.bootstrapResultDigest(bootstrapResult);
        return getSignatureForDigest(bootstrapResultDigest, privateKey);
    }

}
