// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {euint256, ebool} from "../Types.sol";
import {IncoLightning} from "../IncoLightning.sol";
import {IncoUtils, FEE} from "../periphery/IncoUtils.sol";
import {DecryptionAttestation} from "../lightning-parts/DecryptionAttester.types.sol";

// To implement such a contract, we would normally import e form Lib.sol. For test purposes, we take inco as
// a constructor argument instead, so we can test it from other deployment addresses.
contract AddTwo is IncoUtils {

    IncoLightning inco;

    constructor(IncoLightning _inco) {
        inco = _inco;
    }

    // Stores the result of the last callback.
    uint256 public lastResult;

    function addTwo(euint256 a) public returns (euint256) {
        euint256 two = inco.asEuint256(2);
        return inco.eAdd(a, two);
    }

    // To generate a different handle with the same result, instead of adding 2 we add 1 + 1
    function addTwoAlt(euint256 a) public returns (euint256) {
        euint256 one = inco.asEuint256(1);
        return inco.eAdd(a, inco.eAdd(one, one));
    }

    function addTwoEoa(bytes memory uint256EInput)
        external
        payable
        refundUnspent
        returns (euint256 result, euint256 resultRevealed)
    {
        euint256 value = inco.newEuint256{value: FEE}(uint256EInput, msg.sender);
        result = addTwo(value);

        inco.allow(euint256.unwrap(result), address(this));
        inco.allow(euint256.unwrap(result), msg.sender);

        // Used to test attested reveal functionality.
        // Note that msg.sender is not allowed, instead we call .reveal() that gives permission to anyone.
        resultRevealed = addTwoAlt(value);
        inco.reveal(euint256.unwrap(resultRevealed));
    }

    // Used to verify attested compute result handle inside DecryptionAttestation generated from Go code.
    function verifyAttestedComputeResultHandle(bytes32 resultHandle, uint256 p, DecryptionAttestation memory decryption)
        public
        payable
        returns (bool)
    {
        return decryption.handle == ebool.unwrap(inco.eEq(resultHandle, euint256.unwrap(inco.asEuint256(p))));
    }

    function getTrue() external returns (ebool) {
        ebool trueHandle = inco.asEbool(true);
        inco.reveal(ebool.unwrap(trueHandle));
        return trueHandle;
    }

    receive() external payable {
        // Accept ETH payments
    }

}
