// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

contract ComplianceGate is EIP712, Ownable2Step {
    using ECDSA for bytes32;

    struct CompliancePermit {
        address wallet;
        bytes32 action;
        bytes32 subjectId;
        address asset;
        uint256 checkedAt;
        uint256 expiresAt;
        uint256 nonce;
    }

    enum PermitStatus {
        Valid,
        WalletMismatch,
        ActionMismatch,
        SubjectMismatch,
        AssetMismatch,
        NotYetValid,
        Expired,
        TtlTooLong,
        BadSignature,
        NonceUsed
    }

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "CompliancePermit(address wallet,bytes32 action,bytes32 subjectId,address asset,uint256 checkedAt,uint256 expiresAt,uint256 nonce)"
    );

    uint256 public constant MAX_PERMIT_TTL = 15 minutes;

    uint256 public constant DEFAULT_PERMIT_TTL = 120;

    address public complianceSigner;

    address public settlementAsset;

    uint256 public maxPermitTtl;

    mapping(address wallet => mapping(uint256 nonce => bool used)) public usedNonces;

    mapping(address consumer => bool allowed) public isConsumer;

    error InvalidAddress();
    error InvalidTtl(uint256 requested, uint256 ceiling);
    error NotConsumer(address caller);
    error PermitRejected(PermitStatus reason);

    event ComplianceSignerUpdated(address indexed previousSigner, address indexed newSigner);
    event SettlementAssetUpdated(address indexed previousAsset, address indexed newAsset);
    event MaxPermitTtlUpdated(uint256 previousTtl, uint256 newTtl);
    event ConsumerUpdated(address indexed consumer, bool allowed);
    event PermitConsumed(
        address indexed wallet, bytes32 indexed action, bytes32 indexed subjectId, uint256 nonce, uint256 checkedAt
    );

    constructor(address initialOwner, address initialSigner, address initialSettlementAsset)
        EIP712("Bidnox ComplianceGate", "1")
        Ownable(initialOwner)
    {
        if (initialSigner == address(0) || initialSettlementAsset == address(0)) revert InvalidAddress();

        complianceSigner = initialSigner;
        settlementAsset = initialSettlementAsset;
        maxPermitTtl = DEFAULT_PERMIT_TTL;

        emit ComplianceSignerUpdated(address(0), initialSigner);
        emit SettlementAssetUpdated(address(0), initialSettlementAsset);
        emit MaxPermitTtlUpdated(0, DEFAULT_PERMIT_TTL);
    }

    ////////////////////////////////
    //     EXTERNAL FUNCTIONS     //
    ////////////////////////////////

    function verifyPermit(
        CompliancePermit calldata permit,
        bytes calldata signature,
        address expectedWallet,
        bytes32 expectedAction,
        bytes32 expectedSubjectId
    ) external returns (bool) {
        if (!isConsumer[msg.sender]) revert NotConsumer(msg.sender);

        PermitStatus status = _check(permit, signature, expectedWallet, expectedAction, expectedSubjectId);
        if (status != PermitStatus.Valid) revert PermitRejected(status);

        usedNonces[permit.wallet][permit.nonce] = true;

        emit PermitConsumed(permit.wallet, permit.action, permit.subjectId, permit.nonce, permit.checkedAt);
        return true;
    }

    function checkPermit(
        CompliancePermit calldata permit,
        bytes calldata signature,
        address expectedWallet,
        bytes32 expectedAction,
        bytes32 expectedSubjectId
    ) external view returns (PermitStatus) {
        return _check(permit, signature, expectedWallet, expectedAction, expectedSubjectId);
    }

    function hashPermit(CompliancePermit calldata permit) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.wallet,
                    permit.action,
                    permit.subjectId,
                    permit.asset,
                    permit.checkedAt,
                    permit.expiresAt,
                    permit.nonce
                )
            )
        );
    }

    function setComplianceSigner(address newSigner) external onlyOwner {
        if (newSigner == address(0)) revert InvalidAddress();
        emit ComplianceSignerUpdated(complianceSigner, newSigner);
        complianceSigner = newSigner;
    }

    function setSettlementAsset(address newAsset) external onlyOwner {
        if (newAsset == address(0)) revert InvalidAddress();
        emit SettlementAssetUpdated(settlementAsset, newAsset);
        settlementAsset = newAsset;
    }

    function setMaxPermitTtl(uint256 newTtl) external onlyOwner {
        if (newTtl == 0 || newTtl > MAX_PERMIT_TTL) revert InvalidTtl(newTtl, MAX_PERMIT_TTL);
        emit MaxPermitTtlUpdated(maxPermitTtl, newTtl);
        maxPermitTtl = newTtl;
    }

    function setConsumer(address consumer, bool allowed) external onlyOwner {
        if (consumer == address(0)) revert InvalidAddress();
        isConsumer[consumer] = allowed;
        emit ConsumerUpdated(consumer, allowed);
    }

    ////////////////////////////////
    //     INTERNAL FUNCTIONS     //
    ////////////////////////////////

    function _check(
        CompliancePermit calldata permit,
        bytes calldata signature,
        address expectedWallet,
        bytes32 expectedAction,
        bytes32 expectedSubjectId
    ) private view returns (PermitStatus) {
        if (permit.wallet != expectedWallet) return PermitStatus.WalletMismatch;
        if (permit.action != expectedAction) return PermitStatus.ActionMismatch;
        if (permit.subjectId != expectedSubjectId) return PermitStatus.SubjectMismatch;
        if (permit.asset != settlementAsset) return PermitStatus.AssetMismatch;

        if (permit.checkedAt > block.timestamp) return PermitStatus.NotYetValid;
        if (permit.expiresAt <= block.timestamp || permit.expiresAt <= permit.checkedAt) {
            return PermitStatus.Expired;
        }
        if (permit.expiresAt - permit.checkedAt > maxPermitTtl) return PermitStatus.TtlTooLong;

        if (usedNonces[permit.wallet][permit.nonce]) return PermitStatus.NonceUsed;

        (address recovered, ECDSA.RecoverError err,) = hashPermit(permit).tryRecover(signature);
        if (err != ECDSA.RecoverError.NoError || recovered != complianceSigner) {
            return PermitStatus.BadSignature;
        }

        return PermitStatus.Valid;
    }
}
