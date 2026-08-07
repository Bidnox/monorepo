// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {Test, Vm} from "forge-std/Test.sol";
import {TrivialEncryption} from "../lightning-parts/TrivialEncryption.sol";
import {ETypes} from "../Types.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {inco} from "../Lib.sol";
import {IncoTest} from "./IncoTest.sol";
import {IEncryptedInput} from "../lightning-parts/interfaces/IEncryptedInput.sol";

contract ReturnTwo is UUPSUpgradeable {

    function getTwo() external pure returns (uint256) {
        return 2;
    }

    function _authorizeUpgrade(address) internal override {}

}

contract TestDeploy is Test, IncoTest {

    // todo test that inco gets deployed at the predicted address

    function testDeployedCorrectly() public {
        vm.expectEmit(false, false, true, false, address(inco));
        emit TrivialEncryption.TrivialEncrypt(bytes32(uint256(1)), bytes32(uint256(1)), ETypes.Bool, 0);
        inco.asEbool(true);
        assertTrue(inco.isAcceptedVersion(2));
    }

    function testUpgrade() public {
        ReturnTwo newImplem = new ReturnTwo();
        vm.prank(owner);
        inco.upgradeToAndCall(address(newImplem), "");
        assertEq(ReturnTwo(address(inco)).getTwo(), 2);
    }

    function testAddAcceptedVersion() public {
        assertFalse(inco.isAcceptedVersion(42));
        vm.prank(owner);
        inco.addAcceptedVersion(42);
        assertTrue(inco.isAcceptedVersion(42));
    }

    function testAddAcceptedVersion_EmitsVersionAccepted() public {
        vm.recordLogs();
        vm.prank(owner);
        inco.addAcceptedVersion(42);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 expectedTopic0 = keccak256("VersionAccepted(uint16)");
        bool found = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == expectedTopic0) {
                found = true;
                // version is indexed: must appear in topics[1], not in data
                assertEq(logs[i].topics[1], bytes32(uint256(42)), "version should be an indexed topic");
                assertEq(logs[i].data.length, 0, "data should be empty since version is indexed");
                break;
            }
        }
        assertTrue(found, "VersionAccepted event was not emitted");
    }

    function testAddAcceptedVersionNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        inco.addAcceptedVersion(42);
    }

    function testRemoveAcceptedVersion() public {
        assertFalse(inco.isAcceptedVersion(42));
        vm.prank(owner);
        inco.removeAcceptedVersion(42); // removing a non-existent version should be no-op
        assertFalse(inco.isAcceptedVersion(42));
    }

    function testRemoveAcceptedVersion_EmitsVersionRemoved() public {
        vm.prank(owner);
        inco.addAcceptedVersion(42);

        vm.recordLogs();
        vm.prank(owner);
        inco.removeAcceptedVersion(42);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 expectedTopic0 = keccak256("VersionRemoved(uint16)");
        bool found = false;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == expectedTopic0) {
                found = true;
                // version is indexed: must appear in topics[1], not in data
                assertEq(logs[i].topics[1], bytes32(uint256(42)), "version should be an indexed topic");
                assertEq(logs[i].data.length, 0, "data should be empty since version is indexed");
                break;
            }
        }
        assertTrue(found, "VersionRemoved event was not emitted");
    }

    function testRemoveAcceptedVersionNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice));
        vm.prank(alice);
        inco.removeAcceptedVersion(42);
    }

}
