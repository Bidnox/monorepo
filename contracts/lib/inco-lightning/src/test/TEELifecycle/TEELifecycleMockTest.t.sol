// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {TEELifecycle} from "../../lightning-parts/TEELifecycle.sol";
import {BootstrapResult, AddNodeResult, UpgradeResult} from "../../lightning-parts/TEELifecycle.types.sol";
import {MockRemoteAttestation} from "../FakeIncoInfra/MockRemoteAttestation.sol";
import {FakeQuoteVerifier} from "../FakeIncoInfra/FakeQuoteVerifier.sol";
import {IQuoteVerifier} from "../../interfaces/automata-interfaces/IQuoteVerifier.sol";
import {
    TcbInfoJsonObj,
    EnclaveIdentityJsonObj,
    TDX_TEE,
    HEADER_LENGTH,
    MINIMUM_QUOTE_LENGTH
} from "../../interfaces/automata-interfaces/Types.sol";
import {SignatureVerifier} from "../../lightning-parts/primitives/SignatureVerifier.sol";

contract TEELifecycleMockTest is MockRemoteAttestation, TEELifecycle {

    // Constants for testing
    bytes testNetworkPubkey = hex"02516bda9e68a1c3dce74dc1b6ed7d91a91d51c1e1933947f06331cef59631e9eb";
    // See DEFAULT_MRTD in attestation/src/remote_attestation.rs
    bytes testMrtd =
        hex"010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101";
    // See DEFAULT_MR_AGGREGATED in attestation/src/remote_attestation.rs to
    // see the calculation of the default value.
    // Note: This uses abi.encode (not encodePacked) to avoid hash collision vulnerabilities.
    bytes32 testMrAggregated = hex"3d48a1faa8620d86ae037f4fd6746987733d085314b3cd5d5d074ade8bab6ebd";

    function setUp() public {
        getTeeLifecycleStorage().quoteVerifier = new FakeQuoteVerifier();
    }

    function testSuccessfulBootstrap() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        assertTrue(this.isBootstrapComplete(), "Bootstrap should be complete");
        vm.stopPrank();
    }

    function testInvalidMrtd() public {
        bytes memory badMrtd =
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";

        (BootstrapResult memory bootstrapResult, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult(this, testNetworkPubkey, teeEOA, teePrivKey);

        quote = createQuote(badMrtd, teeEOA); // Replace with bad MRTD
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        vm.expectRevert(TEELifecycle.InvalidReportMrAggregated.selector);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.stopPrank();
    }

    function testInvalidSignature() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote,, bytes32 mrAggregated) =
            successfulBootstrapResult();
        (uint256 bootstrapPartyFakePrivkey,) = getLabeledKeyPair("bootstrapPartyFake");
        bytes memory signatureInvalid = signBootstrapResult(bootstrapResult, bootstrapPartyFakePrivkey);
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        vm.expectRevert(TEELifecycle.InvalidEIP712Signature.selector);
        this.verifyBootstrapResult(bootstrapResult, quote, signatureInvalid);
        vm.stopPrank();
    }

    function testBootstrapAlreadyComplete() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.expectRevert(TEELifecycle.BootstrapAlreadyCompleted.selector);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.stopPrank();
    }

    function testAddNodeBootstrapNotComplete() public {
        bytes memory mrtd =
            hex"2a90c8fa38672cafd791d994beb6836b99383b2563736858632284f0f760a6446efd1e7ec457cf08b629ea630f7b4525";
        (, address newCoval) = getLabeledKeyPair("newCoval");
        bytes memory quote = createQuote(mrtd, newCoval);
        vm.startPrank(this.owner());
        vm.expectRevert(TEELifecycle.BootstrapNotComplete.selector);
        this.verifyAddNodeResult(testMrAggregated, AddNodeResult({networkPubkey: hex"00"}), quote, hex"");
        vm.stopPrank();
    }

    function testAddNodeInvalidMrtd() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        bytes memory badMrtd =
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
        (, address newCoval) = getLabeledKeyPair("newCoval");
        bytes memory badQuote = createQuote(badMrtd, newCoval);
        vm.expectRevert(TEELifecycle.InvalidReportMrAggregated.selector);
        this.verifyAddNodeResult(mrAggregated, AddNodeResult({networkPubkey: testNetworkPubkey}), badQuote, signature);
        vm.stopPrank();
    }

    function testAddNodeInvalidNetworkPubkey() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.expectRevert(TEELifecycle.InvalidNetworkPubkey.selector);
        this.verifyAddNodeResult(testMrAggregated, AddNodeResult({networkPubkey: hex"00"}), quote, signature);
        vm.stopPrank();
    }

    function testAddNodeInvalidSignature() public {
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);

        (uint256 maliciousNewNodePrivkey,) = getLabeledKeyPair("maliciousNewNode");
        bytes memory badSignature =
            signAddNodeResult(AddNodeResult({networkPubkey: testNetworkPubkey}), maliciousNewNodePrivkey);

        vm.expectRevert(TEELifecycle.InvalidEIP712Signature.selector);
        this.verifyAddNodeResult(
            testMrAggregated, AddNodeResult({networkPubkey: testNetworkPubkey}), quote, badSignature
        );
        vm.stopPrank();
    }

    // Helper function to create a successful bootstrap result
    function successfulBootstrapResult()
        internal
        returns (
            BootstrapResult memory bootstrapResult,
            uint256 bootstrapPartyPrivkey,
            address bootstrapPartyAddress,
            bytes memory quote,
            bytes memory signature,
            bytes32 mrAggregated
        )
    {
        (bootstrapPartyPrivkey, bootstrapPartyAddress) = getLabeledKeyPair("bootstrapParty");
        mrAggregated = testMrAggregated;
        bootstrapResult = BootstrapResult({networkPubkey: testNetworkPubkey});

        quote = createQuote(testMrtd, bootstrapPartyAddress);
        signature = signBootstrapResult(bootstrapResult, bootstrapPartyPrivkey);
    }

    // Helper function to sign the bootstrap result
    function signBootstrapResult(BootstrapResult memory bootstrapResult, uint256 privateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 bootstrapResultDigest = bootstrapResultDigest(bootstrapResult);
        return getSignatureForDigest(bootstrapResultDigest, privateKey);
    }

    // Helper function to sign the add node result
    function signAddNodeResult(AddNodeResult memory addNodeResult, uint256 privateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 addNodeResultDigest = addNodeResultDigest(addNodeResult);
        return getSignatureForDigest(addNodeResultDigest, privateKey);
    }

    // Helper function to sign the upgrade result
    function signUpgradeResult(UpgradeResult memory upgradeResult, uint256 privateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes32 upgradeResultDigest = upgradeResultDigest(upgradeResult);
        return getSignatureForDigest(upgradeResultDigest, privateKey);
    }

    // ============ Getter Tests ============

    function testQuoteVerifier() public view {
        IQuoteVerifier qv = this.quoteVerifier();
        assertEq(address(qv), address(getTeeLifecycleStorage().quoteVerifier));
    }

    function testNetworkPubkeyGetter() public {
        // Before bootstrap, network pubkey should be empty
        assertEq(this.networkPubkey().length, 0);

        // Complete bootstrap
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.stopPrank();

        // After bootstrap, network pubkey should be set
        assertEq(this.networkPubkey(), testNetworkPubkey);
    }

    function testApprovedTeeVersions() public {
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(testMrAggregated);
        vm.stopPrank();

        bytes32 version = this.approvedTeeVersions(0);
        assertEq(version, testMrAggregated);
    }

    function testApprovedTeeVersions_IndexOutOfBounds() public {
        vm.expectRevert(TEELifecycle.IndexOutOfBounds.selector);
        this.approvedTeeVersions(0);
    }

    function testUpgradeResultDigest() public view {
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: testNetworkPubkey});
        bytes32 digest = this.upgradeResultDigest(upgradeResult);
        // Digest should not be zero
        assertTrue(digest != bytes32(0));
    }

    // ============ verifyUpgradeResult Tests ============

    function testVerifyUpgradeResult() public {
        // First complete bootstrap
        (
            BootstrapResult memory bootstrapResult,
            uint256 bootstrapPartyPrivkey,
            address bootstrapPartyAddress,
            bytes memory quote,
            bytes memory signature,
            bytes32 mrAggregated
        ) = successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);

        // Now test upgrade - use the same signer (they're upgrading their TDX)
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: testNetworkPubkey});
        bytes memory upgradeSignature = signUpgradeResult(upgradeResult, bootstrapPartyPrivkey);
        bytes memory upgradeQuote = createQuote(testMrtd, bootstrapPartyAddress);

        // verifyUpgradeResult calls _verifyResultForEoa which has onlyOwner
        this.verifyUpgradeResult(mrAggregated, upgradeResult, upgradeQuote, upgradeSignature);
        vm.stopPrank();
    }

    function testVerifyUpgradeResult_BootstrapNotComplete() public {
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: testNetworkPubkey});
        vm.prank(this.owner());
        vm.expectRevert(TEELifecycle.BootstrapNotComplete.selector);
        this.verifyUpgradeResult(testMrAggregated, upgradeResult, hex"", hex"");
    }

    function testVerifyUpgradeResult_InvalidNetworkPubkey() public {
        // First complete bootstrap
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.stopPrank();

        // Try upgrade with wrong network pubkey
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: hex"deadbeef"});
        vm.prank(this.owner());
        vm.expectRevert(TEELifecycle.InvalidNetworkPubkey.selector);
        this.verifyUpgradeResult(mrAggregated, upgradeResult, quote, signature);
    }

    function testVerifyUpgradeResult_TEEVersionNotFound() public {
        // First complete bootstrap
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        vm.stopPrank();

        // Try upgrade with unapproved MR_AGGREGATED
        bytes32 unapprovedMr = bytes32(uint256(1234));
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: testNetworkPubkey});
        vm.prank(this.owner());
        vm.expectRevert(TEELifecycle.TEEVersionNotFound.selector);
        this.verifyUpgradeResult(unapprovedMr, upgradeResult, quote, signature);
    }

    // ============ Tests for digest functions ============

    function testAddNodeResultDigest() public view {
        AddNodeResult memory addNodeResult = AddNodeResult({networkPubkey: testNetworkPubkey});
        bytes32 digest = this.addNodeResultDigest(addNodeResult);
        // Verify digest is non-zero and deterministic
        assertTrue(digest != bytes32(0), "Digest should not be zero");
        // Call again to verify determinism
        bytes32 digest2 = this.addNodeResultDigest(addNodeResult);
        assertEq(digest, digest2, "Digest should be deterministic");
    }

    // ============ Tests for uploadCollateral validation ============

    function testUploadCollateral_RevertsWhenEmptyTcbInfo() public {
        TcbInfoJsonObj memory emptyTcbInfo = TcbInfoJsonObj({tcbInfoStr: "", signature: ""});
        EnclaveIdentityJsonObj memory validIdentity = EnclaveIdentityJsonObj({identityStr: "valid", signature: ""});

        vm.prank(this.owner());
        vm.expectRevert(TEELifecycle.EmptyTcbInfo.selector);
        this.uploadCollateral(emptyTcbInfo, validIdentity);
    }

    function testUploadCollateral_RevertsWhenEmptyIdentity() public {
        TcbInfoJsonObj memory validTcbInfo = TcbInfoJsonObj({tcbInfoStr: "valid", signature: ""});
        EnclaveIdentityJsonObj memory emptyIdentity = EnclaveIdentityJsonObj({identityStr: "", signature: ""});

        vm.prank(this.owner());
        vm.expectRevert(TEELifecycle.EmptyIdentity.selector);
        this.uploadCollateral(validTcbInfo, emptyIdentity);
    }

    // ============ Tests for verifyUpgradeResult SignerNotFound ============

    function testVerifyUpgradeResult_RevertsWhenNotASigner() public {
        // First complete bootstrap
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();
        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);

        // Create a new EOA that is NOT a signer
        (uint256 nonSignerPrivkey, address nonSignerAddress) = getLabeledKeyPair("nonSigner");

        // Create upgrade result and quote for the non-signer
        UpgradeResult memory upgradeResult = UpgradeResult({networkPubkey: testNetworkPubkey});
        bytes memory upgradeSignature = signUpgradeResult(upgradeResult, nonSignerPrivkey);
        bytes memory upgradeQuote = createQuote(testMrtd, nonSignerAddress);

        // Should revert because nonSignerAddress is not a registered signer
        vm.expectRevert(abi.encodeWithSelector(SignatureVerifier.SignerNotFound.selector, nonSignerAddress));
        this.verifyUpgradeResult(mrAggregated, upgradeResult, upgradeQuote, upgradeSignature);
        vm.stopPrank();
    }

    // ============ Tests for _verifyAndAttestOnChain error paths ============

    function testVerifyBootstrapResult_RevertsWhenQuoteTooShort() public {
        BootstrapResult memory bootstrapResult = BootstrapResult({networkPubkey: testNetworkPubkey});
        bytes memory shortQuote = hex"0102030405"; // Much shorter than HEADER_LENGTH (48 bytes)
        bytes memory signature = signBootstrapResult(bootstrapResult, teePrivKey);

        vm.startPrank(this.owner());
        this.approveNewTeeVersion(testMrAggregated);
        vm.expectRevert("Could not parse quote header");
        this.verifyBootstrapResult(bootstrapResult, shortQuote, signature);
        vm.stopPrank();
    }

    function testVerifyBootstrapResult_RevertsWhenUnsupportedQuoteVersion() public {
        BootstrapResult memory bootstrapResult = BootstrapResult({networkPubkey: testNetworkPubkey});

        // Create a quote with wrong version (version 3 instead of 4)
        // Version is in first 2 bytes as little-endian
        bytes memory wrongVersionQuote = createQuoteWithVersion(testMrtd, teeEOA, 3);
        bytes memory signature = signBootstrapResult(bootstrapResult, teePrivKey);

        vm.startPrank(this.owner());
        this.approveNewTeeVersion(testMrAggregated);
        vm.expectRevert("Unsupported quote version");
        this.verifyBootstrapResult(bootstrapResult, wrongVersionQuote, signature);
        vm.stopPrank();
    }

    // Helper function to create a quote with a specific version
    function createQuoteWithVersion(bytes memory mrtd, address signer, uint16 version)
        internal
        pure
        returns (bytes memory quote)
    {
        require(mrtd.length == 48, "MRTD should be 48 bytes");
        // Version as little-endian 2 bytes, then 2 bytes padding
        bytes4 versionBytes = bytes4(uint32(version)); // little-endian
        bytes4 tdxTeeType = TDX_TEE;
        bytes memory prefix = new bytes(HEADER_LENGTH + 136 - 8);
        bytes memory middle = new bytes(520 - 184);
        bytes memory reportDataSuffix = new bytes(44);
        bytes memory suffix = new bytes(MINIMUM_QUOTE_LENGTH - HEADER_LENGTH - 584);
        quote = abi.encodePacked(
            versionBytes, tdxTeeType, prefix, mrtd, middle, abi.encodePacked(signer), reportDataSuffix, suffix
        );
    }

    // ============ Tests for reset() ============

    function testReset_OnlyOwner() public {
        address nonOwner = address(0x1234);
        vm.startPrank(nonOwner);
        vm.expectRevert();
        this.reset();
        vm.stopPrank();
    }

    function testReset_WithMultipleSigners() public {
        // Complete bootstrap with first signer
        (
            BootstrapResult memory bootstrapResult,,
            address bootstrapPartyAddress,
            bytes memory quote,
            bytes memory signature,
            bytes32 mrAggregated
        ) = successfulBootstrapResult();

        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);

        // Add a second node
        (uint256 newNodePrivkey, address newNodeAddress) = getLabeledKeyPair("newNode");
        AddNodeResult memory addNodeResult = AddNodeResult({networkPubkey: testNetworkPubkey});
        bytes memory addNodeSignature = signAddNodeResult(addNodeResult, newNodePrivkey);
        bytes memory addNodeQuote = createQuote(testMrtd, newNodeAddress);
        this.verifyAddNodeResult(mrAggregated, addNodeResult, addNodeQuote, addNodeSignature);

        // Verify state before reset
        assertTrue(this.isBootstrapComplete(), "Bootstrap should be complete before reset");
        assertEq(this.networkPubkey(), testNetworkPubkey, "Network pubkey should be set before reset");
        assertEq(this.approvedTeeVersions(0), mrAggregated, "Approved TEE version should exist before reset");
        assertEq(this.getSignersCount(), 2, "Should have 2 signers before reset");
        assertTrue(this.isSigner(bootstrapPartyAddress), "First signer should exist");
        assertTrue(this.isSigner(newNodeAddress), "Second signer should exist");

        // Call reset
        this.reset();

        // Verify all state has been cleared
        assertFalse(this.isBootstrapComplete(), "Bootstrap should not be complete after reset");
        assertEq(this.networkPubkey().length, 0, "Network pubkey should be empty after reset");
        assertEq(this.getSignersCount(), 0, "Should have 0 signers after reset");
        assertFalse(this.isSigner(bootstrapPartyAddress), "First signer should be removed");
        assertFalse(this.isSigner(newNodeAddress), "Second signer should be removed");
        assertEq(this.getThreshold(), 0, "Threshold should be 0 after reset");

        // Verify approved TEE versions array is empty
        vm.expectRevert(TEELifecycle.IndexOutOfBounds.selector);
        this.approvedTeeVersions(0);

        vm.stopPrank();
    }

    function testReset_AllowsNewBootstrap() public {
        // Complete bootstrap
        (BootstrapResult memory bootstrapResult,,, bytes memory quote, bytes memory signature, bytes32 mrAggregated) =
            successfulBootstrapResult();

        vm.startPrank(this.owner());
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        assertTrue(this.isBootstrapComplete(), "Bootstrap should be complete");

        // Reset the contract
        this.reset();
        assertFalse(this.isBootstrapComplete(), "Bootstrap should not be complete after reset");

        // Should be able to bootstrap again
        this.approveNewTeeVersion(mrAggregated);
        this.verifyBootstrapResult(bootstrapResult, quote, signature);
        assertTrue(this.isBootstrapComplete(), "Should be able to bootstrap again after reset");

        vm.stopPrank();
    }

}
