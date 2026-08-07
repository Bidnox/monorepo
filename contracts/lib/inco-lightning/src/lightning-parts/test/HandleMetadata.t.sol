// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {TestUtils} from "../../shared/TestUtils.sol";
import {HandleMetadata} from "../primitives/HandleMetadata.sol";
import {HandleGeneration} from "../primitives/HandleGeneration.sol";
import {TrivialEncryption} from "../TrivialEncryption.sol";
import {EncryptedOperations} from "../EncryptedOperations.sol";
import {EncryptedInput} from "../EncryptedInput.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {
    ETypes,
    ebool,
    euint256,
    eaddress,
    typeToBitMask,
    EOps,
    isTypeSupported,
    SenderNotAllowedForHandle,
    UnexpectedType,
    UnsupportedType
} from "../../Types.sol";
import {VerifierAddressGetter} from "../primitives/VerifierAddressGetter.sol";
import {FEE} from "../Fee.sol";
import {HandleAlreadyExists} from "../../Errors.sol";
import {ExternalHandleDoesNotMatchComputedHandle} from "../EncryptedInput.sol";
import {IEncryptedInput} from "../interfaces/IEncryptedInput.sol";

contract TestHandleMetadata is
    EIP712,
    HandleMetadata,
    TestUtils,
    TrivialEncryption,
    EncryptedOperations,
    EncryptedInput
{

    constructor() EIP712("", "") VerifierAddressGetter(address(0)) {
        _setAcceptedVersion(2, true);
    }

    function testTypeAssignment() public pure {
        bytes32 someHandle = bytes32(keccak256("someHandle"));
        assert(typeOf(embedIndexTypeVersion(someHandle, ETypes.Bool)) == ETypes.Bool);
        assert(typeOf(embedIndexTypeVersion(someHandle, ETypes.Uint256)) == ETypes.Uint256);
        assert(
            typeOf(embedIndexTypeVersion(someHandle, ETypes.AddressOrUint160OrBytes20))
                == ETypes.AddressOrUint160OrBytes20
        );
    }

    function testTrivialEncryptionHandleType() public {
        bytes32 boolHandle = ebool.unwrap(this.asEbool(true));
        assert(typeOf(boolHandle) == ETypes.Bool);
        bytes32 uintHandle = euint256.unwrap(this.asEuint256(42));
        assert(typeOf(uintHandle) == ETypes.Uint256);
        bytes32 addressHandle = eaddress.unwrap(this.asEaddress(address(0xdeadbeef)));
        assert(typeOf(addressHandle) == ETypes.AddressOrUint160OrBytes20);
    }

    function testOperationsHandleType() public {
        euint256 a = this.asEuint256(42);
        euint256 b = this.asEuint256(12);
        ebool control = this.asEbool(true);
        ebool c = this.asEbool(false);
        ebool d = this.asEbool(true);
        eaddress addr1 = this.asEaddress(address(0x0));
        eaddress addr2 = this.asEaddress(address(0xdeadbeef));

        assert(typeOf(euint256.unwrap(this.eAdd(a, b))) == ETypes.Uint256);
        assert(typeOf(euint256.unwrap(this.eSub(a, b))) == ETypes.Uint256);
        assert(typeOf(ebool.unwrap(this.eGe(a, b))) == ETypes.Bool);
        assert(typeOf(this.eIfThenElse(control, euint256.unwrap(a), euint256.unwrap(b))) == ETypes.Uint256);
        assert(typeOf(this.eIfThenElse(control, ebool.unwrap(c), ebool.unwrap(d))) == ETypes.Bool);
        assert(typeOf(ebool.unwrap(this.eEq(eaddress.unwrap(addr1), eaddress.unwrap(addr2)))) == ETypes.Bool);
    }

    function testEIfThenElseChecksTypeCoherence() public {
        ebool control = this.asEbool(false);
        euint256 a = this.asEuint256(42);
        ebool b = this.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(UnexpectedType.selector, ETypes.Bool, typeToBitMask(ETypes.Uint256)));
        this.eIfThenElse(control, euint256.unwrap(a), ebool.unwrap(b));
    }

    function testEncryptedInputHandleType() public {
        address self = address(this);
        bytes32 ciphertext = keccak256(abi.encodePacked("ciphertext"));
        euint256 a = this.newEuint256{value: FEE}(getCiphertextInput(ciphertext, self, self, ETypes.Uint256), self);
        assert(typeOf(euint256.unwrap(a)) == ETypes.Uint256);
        ebool b = this.newEbool{value: FEE}(getCiphertextInput(ciphertext, self, self, ETypes.Bool), address(this));
        assert(typeOf(ebool.unwrap(b)) == ETypes.Bool);
        eaddress c = this.newEaddress{value: FEE}(
            getCiphertextInput(ciphertext, self, self, ETypes.AddressOrUint160OrBytes20), address(this)
        );
        assert(typeOf(eaddress.unwrap(c)) == ETypes.AddressOrUint160OrBytes20);
    }

    /// @notice Helper to create an input with a handle prepended to the ciphertext.
    /// @param word A single word to be used as the ciphertext.
    /// @param user The user address associated with the input.
    function getCiphertextInput(bytes32 word, address user, address contractAddress, ETypes inputType)
        public
        view
        returns (bytes memory input)
    {
        // We need a single word here to get correct encoding
        bytes memory ciphertext = abi.encode(word);
        uint16 version = 2; // version - X-Wing
        bytes32 handle = getInputHandle(
            ciphertext,
            address(this),
            user,
            contractAddress,
            version, // version - X-Wing
            inputType
        );
        input = abi.encodePacked(uint32(version), abi.encode(handle, ciphertext));
    }

    // ============ Tests for HandleGeneration functions ============

    function testGetTrivialEncryptHandle() public view {
        bytes32 plaintext = bytes32(uint256(42));
        bytes32 handle = this.getTrivialEncryptHandle(plaintext, ETypes.Uint256);
        // Verify handle has correct type embedded
        assert(typeOf(handle) == ETypes.Uint256);

        // Test with different types
        bytes32 boolHandle = this.getTrivialEncryptHandle(bytes32(uint256(1)), ETypes.Bool);
        assert(typeOf(boolHandle) == ETypes.Bool);

        bytes32 addrHandle =
            this.getTrivialEncryptHandle(bytes32(uint256(0xdeadbeef)), ETypes.AddressOrUint160OrBytes20);
        assert(typeOf(addrHandle) == ETypes.AddressOrUint160OrBytes20);
    }

    function testGetOpResultHandle() public view {
        bytes32 inputA = bytes32(uint256(1));
        bytes32 inputB = bytes32(uint256(2));
        bytes memory packedInputs = abi.encodePacked(inputA, inputB);

        // Test Add operation
        bytes32 addHandle = this.getOpResultHandle(EOps.Add, ETypes.Uint256, packedInputs);
        assert(typeOf(addHandle) == ETypes.Uint256);

        // Test comparison operation (returns bool)
        bytes32 eqHandle = this.getOpResultHandle(EOps.Eq, ETypes.Bool, packedInputs);
        assert(typeOf(eqHandle) == ETypes.Bool);
    }

    // ============ Tests for EncryptedInput internal functions ============

    /// @notice Expose the internal newInputNotPaying for testing
    function exposedNewInputNotPaying(bytes calldata input, address user, ETypes inputType) public returns (bytes32) {
        return newInputNotPaying(input, user, inputType);
    }

    function testNewInputUnwhitelistedVersion() public {
        address self = address(this);
        bytes32 ciphertextData = keccak256(abi.encodePacked("unwhitelisted_version"));
        bytes memory ciphertext = abi.encode(ciphertextData);
        uint16 unwhitelistedVersion = 0;
        bytes32 handle =
            getInputHandle(ciphertext, address(this), self, address(this), unwhitelistedVersion, ETypes.Uint256);
        bytes memory badInput = abi.encodePacked(uint32(unwhitelistedVersion), abi.encode(handle, ciphertext));

        vm.expectRevert(abi.encodeWithSelector(IEncryptedInput.InvalidInputVersion.selector, unwhitelistedVersion));
        this.exposedNewInputNotPaying(badInput, self, ETypes.Uint256);
    }

    function testNewInputVersionAddedThenRemoved() public {
        address self = address(this);
        bytes32 ciphertextData = keccak256(abi.encodePacked("version_toggle"));
        bytes memory ciphertext = abi.encode(ciphertextData);
        uint16 version = 3;

        bytes32 handle = getInputHandle(ciphertext, address(this), self, address(this), version, ETypes.Uint256);
        bytes memory input = abi.encodePacked(uint32(version), abi.encode(handle, ciphertext));

        // Version 3 is not accepted yet
        vm.expectRevert(abi.encodeWithSelector(IEncryptedInput.InvalidInputVersion.selector, version));
        this.exposedNewInputNotPaying(input, self, ETypes.Uint256);

        // Whitelist version 3
        _setAcceptedVersion(3, true);

        // Now it should succeed
        bytes32 resultHandle = this.exposedNewInputNotPaying(input, self, ETypes.Uint256);
        assert(typeOf(resultHandle) == ETypes.Uint256);

        // Remove version 3
        _setAcceptedVersion(3, false);

        // Use different ciphertext to avoid HandleAlreadyExists
        bytes32 ciphertextData2 = keccak256(abi.encodePacked("version_toggle_2"));
        bytes memory ciphertext2 = abi.encode(ciphertextData2);
        bytes32 handle2 = getInputHandle(ciphertext2, address(this), self, address(this), version, ETypes.Uint256);
        bytes memory input2 = abi.encodePacked(uint32(version), abi.encode(handle2, ciphertext2));

        // Should revert again
        vm.expectRevert(abi.encodeWithSelector(IEncryptedInput.InvalidInputVersion.selector, version));
        this.exposedNewInputNotPaying(input2, self, ETypes.Uint256);
    }

    function testNewInputNotPaying() public {
        address self = address(this);
        bytes32 ciphertextData = keccak256(abi.encodePacked("notpaying_ciphertext"));
        // Create input with handle computed for this contract as msg.sender (since exposedNewInputNotPaying is public)
        bytes memory input = getCiphertextInputForExposedCall(ciphertextData, self, ETypes.Uint256);
        // Call the exposed version without paying
        bytes32 handle = this.exposedNewInputNotPaying(input, self, ETypes.Uint256);
        assert(typeOf(handle) == ETypes.Uint256);
    }

    /// @notice Helper to create input for exposed internal function calls where msg.sender == address(this)
    function getCiphertextInputForExposedCall(bytes32 word, address user, ETypes inputType)
        public
        view
        returns (bytes memory input)
    {
        bytes memory ciphertext = abi.encode(word);
        uint16 version = 2; // version - X-Wing
        // For external calls via this., msg.sender is address(this)
        bytes32 handle = getInputHandle(ciphertext, address(this), user, address(this), version, inputType);
        input = abi.encodePacked(uint32(version), abi.encode(handle, ciphertext));
    }

    // ============ Tests for EncryptedInput error branches ============

    function testNewInputTooShort() public {
        address self = address(this);
        // Input less than 64 bytes should revert
        bytes memory shortInput = hex"deadbeef";
        vm.expectRevert(abi.encodeWithSelector(IEncryptedInput.InputLengthTooShort.selector, shortInput.length));
        this.exposedNewInputNotPaying(shortInput, self, ETypes.Uint256);
    }

    function testNewInputHandleMismatch() public {
        address self = address(this);
        bytes32 ciphertextData = keccak256(abi.encodePacked("mismatch_test"));
        bytes memory ciphertext = abi.encode(ciphertextData);
        // Create input with wrong handle (just a random bytes32)
        bytes32 wrongHandle = bytes32(uint256(12345));
        uint16 version = 2; // version - X-Wing
        bytes memory badInput = abi.encodePacked(uint32(version), abi.encode(wrongHandle, ciphertext));

        // Compute the expected handle for the error message
        bytes32 expectedHandle = getInputHandle(ciphertext, address(this), self, address(this), version, ETypes.Uint256);

        vm.expectRevert(
            abi.encodeWithSelector(
                ExternalHandleDoesNotMatchComputedHandle.selector,
                wrongHandle,
                expectedHandle,
                block.chainid,
                address(this),
                self,
                address(this),
                version
            )
        );
        this.exposedNewInputNotPaying(badInput, self, ETypes.Uint256);
    }

    function testNewInputHandleAlreadyExists() public {
        address self = address(this);
        bytes32 ciphertextData = keccak256(abi.encodePacked("duplicate_test"));
        bytes memory input = getCiphertextInputForExposedCall(ciphertextData, self, ETypes.Uint256);

        // First call should succeed
        bytes32 handle = this.exposedNewInputNotPaying(input, self, ETypes.Uint256);

        // Second call with same input should revert with HandleAlreadyExists
        vm.expectRevert(abi.encodeWithSelector(HandleAlreadyExists.selector, handle));
        this.exposedNewInputNotPaying(input, self, ETypes.Uint256);
    }

    // Tests for EncryptedOperations error branches

    /// @notice Test eBitAnd with mismatched types (line 122)
    function testEBitAndTypeMismatch() public {
        euint256 a = this.asEuint256(42);
        ebool b = this.asEbool(true);
        // Error: UnexpectedType(typeOf(rhs), typeToBitMask(lhsType))
        // With lhs=Uint256, rhs=Bool: UnexpectedType(Bool, typeToBitMask(Uint256))
        vm.expectRevert(abi.encodeWithSelector(UnexpectedType.selector, ETypes.Bool, typeToBitMask(ETypes.Uint256)));
        this.eBitAnd(euint256.unwrap(a), ebool.unwrap(b));
    }

    /// @notice Test eBitOr with mismatched types
    function testEBitOrTypeMismatch() public {
        euint256 a = this.asEuint256(42);
        ebool b = this.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(UnexpectedType.selector, ETypes.Bool, typeToBitMask(ETypes.Uint256)));
        this.eBitOr(euint256.unwrap(a), ebool.unwrap(b));
    }

    /// @notice Test eBitXor with mismatched types
    function testEBitXorTypeMismatch() public {
        euint256 a = this.asEuint256(42);
        ebool b = this.asEbool(true);
        vm.expectRevert(abi.encodeWithSelector(UnexpectedType.selector, ETypes.Bool, typeToBitMask(ETypes.Uint256)));
        this.eBitXor(euint256.unwrap(a), ebool.unwrap(b));
    }

    /// @notice Test eCast with unsupported target type (line 273)
    function testECastUnsupportedType() public {
        euint256 a = this.asEuint256(42);
        ETypes unsupportedType = ETypes.Uint4UNSUPPORTED;
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, unsupportedType));
        this.eCast(euint256.unwrap(a), unsupportedType);
    }

    /// @notice Test eRandBounded with unsupported type (line 291)
    function testERandBoundedUnsupportedType() public {
        euint256 bound = this.asEuint256(100);
        ETypes unsupportedType = ETypes.Uint4UNSUPPORTED;
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, unsupportedType));
        this.eRandBounded{value: FEE}(euint256.unwrap(bound), unsupportedType);
    }

    /// @notice Test eIfThenElse with unsupported ifTrue type (line 318)
    function testEIfThenElseUnsupportedType() public {
        ebool control = this.asEbool(true);
        // Create a handle with unsupported type by manually crafting one
        bytes32 unsupportedHandle = embedIndexTypeVersion(bytes32(uint256(1)), ETypes.Uint4UNSUPPORTED);
        ebool ifFalse = this.asEbool(false);
        vm.expectRevert(abi.encodeWithSelector(UnsupportedType.selector, ETypes.Uint4UNSUPPORTED));
        this.eIfThenElse(control, unsupportedHandle, ebool.unwrap(ifFalse));
    }

    /// @notice Test eIfThenElse with mismatched types between ifTrue and ifFalse (line 322)
    function testEIfThenElseTypeMismatch() public {
        ebool control = this.asEbool(true);
        euint256 ifTrue = this.asEuint256(42);
        ebool ifFalse = this.asEbool(false);
        // ifTrue is Uint256, ifFalse is Bool - type mismatch should trigger checkInput failure
        // Error is UnexpectedType(ifFalse type=Bool, required type mask for Uint256)
        vm.expectRevert(abi.encodeWithSelector(UnexpectedType.selector, ETypes.Bool, typeToBitMask(ETypes.Uint256)));
        this.eIfThenElse(control, euint256.unwrap(ifTrue), ebool.unwrap(ifFalse));
    }

    /// @notice Test eIfThenElse with ifTrue handle not allowed for sender
    function testEIfThenElseIfTrueNotAllowed() public {
        // Create handles from this contract (allowed)
        ebool control = this.asEbool(true);
        euint256 ifTrue = this.asEuint256(42);
        ebool ifFalse = this.asEbool(false);

        // Allow alice to access control and ifFalse, but NOT ifTrue
        this.allow(ebool.unwrap(control), alice);
        this.allow(ebool.unwrap(ifFalse), alice);

        // Call eIfThenElse as alice - should fail on ifTrue check
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(SenderNotAllowedForHandle.selector, euint256.unwrap(ifTrue), alice));
        this.eIfThenElse(control, euint256.unwrap(ifTrue), ebool.unwrap(ifFalse));
    }

    // ============ Fuzz Tests for HandleMetadata ============

    /// @dev Fuzz test for type embedding round-trip: typeOf(embedTypeVersion(h, t)) == t
    function testFuzzTypeEmbeddingRoundTrip(bytes32 handle, uint8 typeIndex) public pure {
        // Constrain to supported types (0=Bool, 7=AddressOrUint160OrBytes20, 8=Uint256)
        ETypes inputType;
        uint8 typeSelector = typeIndex % 3;
        if (typeSelector == 0) {
            inputType = ETypes.Bool;
        } else if (typeSelector == 1) {
            inputType = ETypes.AddressOrUint160OrBytes20;
        } else {
            inputType = ETypes.Uint256;
        }

        bytes32 embeddedHandle = embedTypeVersion(handle, inputType);
        ETypes extractedType = typeOf(embeddedHandle);

        assert(extractedType == inputType);
    }

    /// @dev Fuzz test for embedIndexTypeVersion round-trip
    function testFuzzEmbedIndexTypeVersionRoundTrip(bytes32 handle, uint8 typeIndex) public pure {
        // Constrain to supported types
        ETypes inputType;
        uint8 typeSelector = typeIndex % 3;
        if (typeSelector == 0) {
            inputType = ETypes.Bool;
        } else if (typeSelector == 1) {
            inputType = ETypes.AddressOrUint160OrBytes20;
        } else {
            inputType = ETypes.Uint256;
        }

        bytes32 embeddedHandle = embedIndexTypeVersion(handle, inputType);
        ETypes extractedType = typeOf(embeddedHandle);

        assert(extractedType == inputType);
    }

    /// @dev Fuzz test that typeOf correctly extracts type from handles with valid embedded types
    function testFuzzTypeOfExtraction(bytes32 handle, uint8 typeIndex) public pure {
        // First embed a valid type, then verify extraction
        ETypes inputType;
        uint8 typeSelector = typeIndex % 3;
        if (typeSelector == 0) {
            inputType = ETypes.Bool;
        } else if (typeSelector == 1) {
            inputType = ETypes.AddressOrUint160OrBytes20;
        } else {
            inputType = ETypes.Uint256;
        }

        bytes32 handle = embedTypeVersion(handle, inputType);

        // Extract the type from the handle
        ETypes extractedType = typeOf(handle);

        // Manually compute what the type should be (bits 8-15 of the handle)
        uint8 expectedTypeValue = uint8(uint256(handle) >> 8);

        // Verify the extraction matches manual computation
        assert(uint8(extractedType) == expectedTypeValue);
        // Also verify it matches what we embedded
        assert(extractedType == inputType);
    }

    /// @dev Fuzz test that embedding preserves upper bits of handle
    function testFuzzEmbeddingPreservesUpperBits(bytes32 handle, uint8 typeIndex) public pure {
        ETypes inputType;
        uint8 typeSelector = typeIndex % 3;
        if (typeSelector == 0) {
            inputType = ETypes.Bool;
        } else if (typeSelector == 1) {
            inputType = ETypes.AddressOrUint160OrBytes20;
        } else {
            inputType = ETypes.Uint256;
        }

        bytes32 embeddedHandle = embedTypeVersion(handle, inputType);

        // Verify upper 30 bytes (240 bits) are preserved
        // Mask out the lower 2 bytes (16 bits) for comparison
        bytes32 upperMask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000;
        assert((handle & upperMask) == (embeddedHandle & upperMask));
    }

    /// @dev Fuzz test that embedIndexTypeVersion clears index byte correctly
    function testFuzzEmbedIndexClearsCorrectly(bytes32 handle, uint8 typeIndex) public pure {
        ETypes inputType;
        uint8 typeSelector = typeIndex % 3;
        if (typeSelector == 0) {
            inputType = ETypes.Bool;
        } else if (typeSelector == 1) {
            inputType = ETypes.AddressOrUint160OrBytes20;
        } else {
            inputType = ETypes.Uint256;
        }

        bytes32 embeddedHandle = embedIndexTypeVersion(handle, inputType);

        // Extract index byte (bits 16-23) - should be HANDLE_INDEX (0)
        uint8 indexByte = uint8(uint256(embeddedHandle) >> 16);
        assert(indexByte == 0); // HANDLE_INDEX is 0
    }

}
