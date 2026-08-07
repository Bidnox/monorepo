// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {inco} from "../Lib.sol";
import {euint256, ebool, ETypes, elist, typeBitSize, SenderNotAllowedForHandle} from "../Types.sol";
import {IncoTest} from "./IncoTest.sol";
import {IEncryptedOperations} from "../lightning-parts/interfaces/IEncryptedOperations.sol";
import {ITrivialEncryption} from "../lightning-parts/interfaces/ITrivialEncryption.sol";
import {IBaseAccessControlList} from "../lightning-parts/AccessControl/interfaces/IBaseAccessControlList.sol";
import {IEList} from "../lightning-parts/interfaces/IEList.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {BIT_FEE, FEE} from "../lightning-parts/Fee.sol";

contract TestPause is IncoTest {

    /// @dev A single op spec: calldata, msg.value, and the exact selector the op must
    /// revert with when the contract is paused. Annotating each op keeps payable and
    /// non-payable ops in one loop while still asserting the specific expected error.
    struct Op {
        bytes data;
        uint256 value;
        bytes4 expectedPauseError;
    }

    function testPausedOpsRevertAndUnpausedOpsSucceed() public {
        // Fund this contract for the payable ops below.
        vm.deal(address(this), 100 ether);

        // Create encrypted operands. Trivial-encryption grants transient ACL access to
        // this contract for the lifetime of this transaction, so subsequent ops can
        // call back into `inco` as msg.sender.
        euint256 a = inco.asEuint256(10);
        euint256 b = inco.asEuint256(5);
        ebool t = inco.asEbool(true);
        bytes32 aH = euint256.unwrap(a);
        bytes32 bH = euint256.unwrap(b);

        // Build a 3-element euint256 elist to feed into list ops.
        uint256 listFee = uint256(3) * typeBitSize(ETypes.Uint256) * BIT_FEE;
        elist list = inco.listRange{value: listFee}(0, 3, ETypes.Uint256);
        // Pull a valid encrypted index/value out of the list (transient ACL access).
        bytes32 idxH = inco.listGet(list, 0);
        uint256 listBits = uint256(3) * typeBitSize(ETypes.Uint256);
        uint256 listAppendFee = listBits + typeBitSize(ETypes.Uint256);

        // Selector each op is expected to revert with under pause:
        // - aclErr: ops that take input handles. `isAllowed(...)` returns false when
        //   paused, so `checkInput` reverts before the op reaches `setDigest`.
        // - pauseErr: ops without input handle checks. They reach `setDigest`, which
        //   has the `whenNotPaused` modifier.
        bytes4 aclErr = SenderNotAllowedForHandle.selector;
        bytes4 pauseErr = PausableUpgradeable.EnforcedPause.selector;

        // Build the op list. Each op MUST revert with `expectedPauseError` when paused
        // and succeed when unpaused.
        Op[] memory ops = new Op[](41);
        uint256 i;
        // ----- EncryptedOperations: all check input handles -----
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eAdd, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eSub, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eMul, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eDiv, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eRem, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eShl, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eShr, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eRotl, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eRotr, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eBitAnd, (aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eBitOr, (aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eBitXor, (aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eEq, (aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eNe, (aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eGe, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eGt, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eLe, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eLt, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eMin, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eMax, (a, b)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eNot, (t)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eCast, (aH, ETypes.AddressOrUint160OrBytes20)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eIfThenElse, (t, aH, bH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEncryptedOperations.eRandBounded, (aH, ETypes.Uint256)), FEE, aclErr);
        // ----- TrivialEncryption: plaintext inputs, no ACL check -----
        ops[i++] = Op(abi.encodeCall(ITrivialEncryption.asEuint256, (uint256(7))), 0, pauseErr);
        ops[i++] = Op(abi.encodeCall(ITrivialEncryption.asEbool, (false)), 0, pauseErr);
        ops[i++] = Op(abi.encodeCall(ITrivialEncryption.asEaddress, (bob)), 0, pauseErr);
        // ----- ACL grant: gated on `isAllowed(handle, msg.sender)` -----
        ops[i++] = Op(abi.encodeCall(IBaseAccessControlList.allow, (aH, bob)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IBaseAccessControlList.reveal, (bH)), 0, aclErr);
        // ----- EList -----
        // listRange takes only plain integers; reaches setDigest directly.
        ops[i++] = Op(
            abi.encodeCall(IEList.listRange, (0, 2, ETypes.Uint256)),
            2 * typeBitSize(ETypes.Uint256) * BIT_FEE,
            pauseErr
        );
        // The rest take a list handle (and often value/index handles).
        ops[i++] = Op(abi.encodeCall(IEList.listAppend, (list, idxH)), listAppendFee * BIT_FEE, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listGet, (list, uint16(0))), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listGetOr, (list, idxH, idxH)), 0, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listSet, (list, idxH, idxH)), listBits * BIT_FEE, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listInsert, (list, idxH, idxH)), listAppendFee * BIT_FEE, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listConcat, (list, list)), (listBits + listBits) * BIT_FEE, aclErr);
        ops[i++] = Op(
            abi.encodeCall(IEList.listSlice, (list, idxH, uint16(2), idxH)),
            2 * typeBitSize(ETypes.Uint256) * BIT_FEE,
            aclErr
        );
        ops[i++] = Op(abi.encodeCall(IEList.listShuffle, (list)), listBits * BIT_FEE, aclErr);
        ops[i++] = Op(abi.encodeCall(IEList.listReverse, (list)), listBits * BIT_FEE, aclErr);
        // newEList overloads — overloaded, so resolve by signature.
        // Empty arrays are valid inputs and skip the inner loops, isolating the pause
        // gate (the `setDigest` call) as the only thing that can revert.
        bytes32[] memory emptyHandles = new bytes32[](0);
        bytes[] memory emptyInputs = new bytes[](0);
        ops[i++] = Op(abi.encodeWithSignature("newEList(bytes32[],uint8)", emptyHandles, ETypes.Uint256), 0, pauseErr);
        ops[i++] = Op(
            abi.encodeWithSignature("newEList(bytes[],uint8,address)", emptyInputs, ETypes.Uint256, address(this)),
            0,
            pauseErr
        );
        assertEq(i, ops.length, "ops list length mismatch");

        // ---- Pause: every op must revert with its expected selector ----
        vm.prank(owner);
        inco.pause();

        for (uint256 j = 0; j < ops.length; j++) {
            (bool ok, bytes memory ret) = address(inco).call{value: ops[j].value}(ops[j].data);
            assertFalse(ok, string.concat("expected revert when paused, op #", vm.toString(j)));
            assertGe(ret.length, 4, "revert payload too short");
            // Read the first 4 bytes of revert data (the error selector).
            bytes4 sel;
            assembly {
                sel := mload(add(ret, 0x20))
            }
            assertTrue(
                sel == ops[j].expectedPauseError, string.concat("unexpected revert selector, op #", vm.toString(j))
            );
        }

        // ---- Unpause: every op must succeed ----
        vm.prank(owner);
        inco.unpause();

        for (uint256 j = 0; j < ops.length; j++) {
            (bool ok,) = address(inco).call{value: ops[j].value}(ops[j].data);
            assertTrue(ok, string.concat("expected success when unpaused, op #", vm.toString(j)));
        }
    }

}
