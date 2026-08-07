// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {HandleMetadata} from "../../lightning-parts/primitives/HandleMetadata.sol";
import {ETypes, euint256, ebool, eaddress} from "../../Types.sol";
import {asBool} from "../..//shared/TypeUtils.sol";

/// @notice key-value store, knows the value behind each handle
contract KVStore is HandleMetadata {

    mapping(bytes32 => bytes32) private store;

    function set(bytes32 key, bytes32 value) internal {
        store[key] = value;
    }

    function get(bytes32 key) internal view returns (bytes32) {
        return store[key];
    }

    function getUint256Value(euint256 input) internal view returns (uint256) {
        bytes32 handle = euint256.unwrap(input);
        checkType(handle, ETypes.Uint256);
        return uint256(get(handle));
    }

    function getBoolValue(ebool input) internal view returns (bool) {
        bytes32 handle = ebool.unwrap(input);
        checkType(handle, ETypes.Bool);
        return asBool(get(handle));
    }

    function getAddressValue(eaddress input) internal view returns (address) {
        bytes32 handle = eaddress.unwrap(input);
        checkType(handle, ETypes.AddressOrUint160OrBytes20);
        return address(uint160(uint256(get(handle))));
    }

    function checkType(bytes32 handle, ETypes requiredType) private pure {
        assert(typeOf(handle) == requiredType);
    }

}
