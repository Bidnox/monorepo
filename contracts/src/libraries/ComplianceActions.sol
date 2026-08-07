// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

library ComplianceActions {
    bytes32 internal constant CREATE_RECEIVABLE = keccak256("BIDNOX_CREATE_RECEIVABLE");
    bytes32 internal constant CONFIRM_RECEIVABLE = keccak256("BIDNOX_CONFIRM_RECEIVABLE");
    bytes32 internal constant BID = keccak256("BIDNOX_BID");
    bytes32 internal constant SETTLE = keccak256("BIDNOX_SETTLE");
    bytes32 internal constant REPAY = keccak256("BIDNOX_REPAY");
}
