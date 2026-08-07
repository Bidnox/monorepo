// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {ebool, euint256, ETypes} from "../../Types.sol";
import {inco} from "../../Lib.sol";
import {TestUtils} from "../../shared/TestUtils.sol";
import {KVStore} from "./KVStore.sol";
import {HandleGeneration} from "../../lightning-parts/primitives/HandleGeneration.sol";

/// @notice simulates what inco does offchain but over plaintexts
contract FakeIncoInfraBase is TestUtils, KVStore, HandleGeneration {

    error UnsupportedTypeInput(ETypes inputType);

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
            address(inco),
            user,
            contractAddress,
            version, // version - X-Wing
            inputType
        );
        input = abi.encodePacked(uint32(version), abi.encode(handle, ciphertext));
    }

    function fakePrepareEuint256Ciphertext(uint256 value, address userAddress, address contractAddress)
        internal
        view
        returns (bytes memory ciphertext)
    {
        ciphertext = getCiphertextInput(bytes32(value), userAddress, contractAddress, ETypes.Uint256);
    }

    function fakeDecryptEuint256Ciphertext(bytes memory ciphertext) internal pure returns (uint256 value) {
        (value) = abi.decode(ciphertext, (uint256));
    }

    function fakeDecryptEuint160Ciphertext(bytes memory ciphertext) internal pure returns (uint160 value) {
        value = abi.decode(ciphertext, (uint160));
    }

    function fakePrepareEboolCiphertext(bool value, address userAddress, address contractAddress)
        internal
        view
        returns (bytes memory ciphertext)
    {
        bytes32 b = bytes32(uint256(value ? 1 : 0));
        ciphertext = getCiphertextInput(b, userAddress, contractAddress, ETypes.Bool);
    }

    function fakePrepareEaddressCiphertext(address value, address userAddress, address contractAddress)
        internal
        view
        returns (bytes memory ciphertext)
    {
        ciphertext = getCiphertextInput(
            bytes32(uint256(uint160(value))), userAddress, contractAddress, ETypes.AddressOrUint160OrBytes20
        );
    }

    function fakeDecryptEaddressCiphertext(bytes memory ciphertext) internal pure returns (address value) {
        value = abi.decode(ciphertext, (address));
    }

    function fakeDecryptEboolCiphertext(bytes memory ciphertext) internal pure returns (bool value) {
        value = abi.decode(ciphertext, (bool));
    }

    function fakeEncryptBool(bool value) internal pure returns (ebool) {
        return ebool.wrap(bytes32(value ? uint256(1) : uint256(0)));
    }

    function fakeEncryptUint256(uint256 value) internal pure returns (euint256) {
        return euint256.wrap(bytes32(value));
    }

    function fakeDecryptEbool(ebool handle) internal pure returns (bool) {
        return ebool.unwrap(handle) == bytes32(uint256(1));
    }

    function fakeDecryptEuint256(euint256 handle) internal pure returns (uint256) {
        return uint256(euint256.unwrap(handle));
    }

}
