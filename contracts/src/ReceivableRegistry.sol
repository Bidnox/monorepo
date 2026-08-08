// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ComplianceGate} from "./ComplianceGate.sol";
import {ComplianceActions} from "./libraries/ComplianceActions.sol";

contract ReceivableRegistry is EIP712, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum ReceivableStatus {
        None,
        Created,
        BuyerConfirmed,
        AuctionOpen,
        AuctionClosed,
        Funded,
        Repaid,
        Overdue,
        Cancelled
    }

    struct Receivable {
        bytes32 id;
        address seller;
        address buyer;
        bytes32 fingerprint;
        bytes32 documentHash;
        uint256 faceValue;
        uint64 issueDate;
        uint64 dueDate;
        address settlementAsset;
        ReceivableStatus status;
        uint256 auctionId;
        address financier;
        uint256 advanceAmount;
        uint64 fundingDeadline;
    }

    struct ReceivableInput {
        address buyer;
        bytes32 invoiceReferenceHash;
        bytes32 documentHash;
        bytes32 currency;
        uint256 faceValue;
        uint64 issueDate;
        uint64 dueDate;
        address settlementAsset;
    }

    bytes32 public constant BUYER_CONFIRMATION_TYPEHASH = keccak256(
        "BuyerConfirmation(bytes32 receivableId,address seller,address buyer,uint256 faceValue,uint64 dueDate,bytes32 fingerprint)"
    );

    bytes32 private constant RECEIVABLE_ID_TAG = keccak256("BIDNOX_RECEIVABLE_ID_V1");

    uint64 public constant FUNDING_WINDOW = 1 days;

    ComplianceGate public immutable complianceGate;

    address public auctionContract;

    mapping(bytes32 receivableId => Receivable) private _receivables;

    mapping(bytes32 fingerprint => bool registered) public registeredFingerprint;

    error InvalidAddress();
    error NotAuctionContract(address caller);
    error AuctionContractAlreadySet(address current);
    error NotSeller(address caller, address seller);
    error NotBuyer(address caller, address buyer);
    error UnknownReceivable(bytes32 receivableId);
    error UnexpectedStatus(ReceivableStatus actual, ReceivableStatus expected);

    error DuplicateFingerprint(bytes32 fingerprint);
    error BuyerIsSeller(address account);
    error ZeroFaceValue();
    error DueDateNotInFuture(uint64 dueDate, uint256 nowTs);
    error DueDateBeforeIssueDate(uint64 issueDate, uint64 dueDate);
    error UnsupportedSettlementAsset(address provided, address expected);

    error InvalidBuyerSignature();
    error AuctionMismatch(uint256 expected, uint256 actual);
    error InvalidWinner();
    error ZeroAdvance();
    error AdvanceExceedsFaceValue(uint256 advance, uint256 faceValue);
    error NotFinancier(address caller, address financier);
    error FundingWindowExpired(uint64 deadline, uint256 nowTs);
    error FundingWindowStillOpen(uint64 deadline, uint256 nowTs);
    error UnexpectedTransferAmount(uint256 expected, uint256 actual);
    error NotYetDue(uint64 dueDate, uint256 nowTs);

    event ReceivableCreated(
        bytes32 indexed receivableId,
        address indexed seller,
        address indexed buyer,
        bytes32 fingerprint,
        uint256 faceValue,
        uint64 dueDate,
        address settlementAsset
    );
    event BuyerConfirmed(bytes32 indexed receivableId, address indexed buyer, bytes32 fingerprint);
    event AuctionOpened(bytes32 indexed receivableId, uint256 indexed auctionId);
    event AuctionClosed(
        bytes32 indexed receivableId, uint256 indexed auctionId, address indexed financier, uint256 advanceAmount
    );
    event ReceivableFunded(
        bytes32 indexed receivableId, address indexed financier, address indexed seller, uint256 advanceAmount
    );
    event ReceivableRepaid(
        bytes32 indexed receivableId, address indexed buyer, address indexed financier, uint256 amount
    );
    event FundingExpired(bytes32 indexed receivableId, uint256 indexed auctionId, address indexed financier);
    event AuctionFailed(bytes32 indexed receivableId, uint256 indexed auctionId);
    event ReceivableOverdue(bytes32 indexed receivableId, uint64 dueDate);
    event ReceivableCancelled(bytes32 indexed receivableId, address indexed seller);
    event AuctionContractUpdated(address indexed previous, address indexed current);

    modifier onlyAuction() {
        if (msg.sender != auctionContract) revert NotAuctionContract(msg.sender);
        _;
    }

    constructor(address initialOwner, ComplianceGate gate)
        EIP712("Bidnox ReceivableRegistry", "1")
        Ownable(initialOwner)
    {
        if (address(gate) == address(0)) revert InvalidAddress();
        complianceGate = gate;
    }

    ////////////////////////////////
    //     EXTERNAL FUNCTIONS     //
    ////////////////////////////////

    function computeFingerprint(address seller, ReceivableInput calldata input) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                seller,
                input.buyer,
                input.invoiceReferenceHash,
                input.currency,
                input.faceValue,
                input.issueDate,
                input.dueDate
            )
        );
    }

    function computeReceivableId(bytes32 fingerprint) public view returns (bytes32) {
        return keccak256(abi.encode(RECEIVABLE_ID_TAG, block.chainid, address(this), fingerprint));
    }

    function createReceivable(
        ReceivableInput calldata input,
        ComplianceGate.CompliancePermit calldata permit,
        bytes calldata complianceSignature
    ) external nonReentrant returns (bytes32 receivableId) {
        if (input.buyer == address(0)) revert InvalidAddress();
        if (input.buyer == msg.sender) revert BuyerIsSeller(msg.sender);
        if (input.faceValue == 0) revert ZeroFaceValue();
        if (input.dueDate <= block.timestamp) revert DueDateNotInFuture(input.dueDate, block.timestamp);
        if (input.dueDate <= input.issueDate) revert DueDateBeforeIssueDate(input.issueDate, input.dueDate);

        address expectedAsset = complianceGate.settlementAsset();
        if (input.settlementAsset != expectedAsset) {
            revert UnsupportedSettlementAsset(input.settlementAsset, expectedAsset);
        }

        bytes32 fingerprint = computeFingerprint(msg.sender, input);
        if (registeredFingerprint[fingerprint]) revert DuplicateFingerprint(fingerprint);

        receivableId = computeReceivableId(fingerprint);

        assert(
            complianceGate.verifyPermit(
                permit, complianceSignature, msg.sender, ComplianceActions.CREATE_RECEIVABLE, receivableId
            )
        );

        registeredFingerprint[fingerprint] = true;

        Receivable storage r = _receivables[receivableId];
        r.id = receivableId;
        r.seller = msg.sender;
        r.buyer = input.buyer;
        r.fingerprint = fingerprint;
        r.documentHash = input.documentHash;
        r.faceValue = input.faceValue;
        r.issueDate = input.issueDate;
        r.dueDate = input.dueDate;
        r.settlementAsset = input.settlementAsset;
        r.status = ReceivableStatus.Created;

        emit ReceivableCreated(
            receivableId, msg.sender, input.buyer, fingerprint, input.faceValue, input.dueDate, input.settlementAsset
        );
    }

    function confirmReceivable(
        bytes32 receivableId,
        bytes calldata buyerSignature,
        ComplianceGate.CompliancePermit calldata permit,
        bytes calldata complianceSignature
    ) external nonReentrant {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.Created);

        bytes32 digest = hashBuyerConfirmation(receivableId);
        if (!SignatureChecker.isValidSignatureNow(r.buyer, digest, buyerSignature)) revert InvalidBuyerSignature();

        assert(
            complianceGate.verifyPermit(
                permit, complianceSignature, r.buyer, ComplianceActions.CONFIRM_RECEIVABLE, receivableId
            )
        );

        r.status = ReceivableStatus.BuyerConfirmed;
        emit BuyerConfirmed(receivableId, r.buyer, r.fingerprint);
    }

    function markAuctionOpened(bytes32 receivableId, uint256 auctionId) external onlyAuction {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.BuyerConfirmed);

        r.auctionId = auctionId;
        r.status = ReceivableStatus.AuctionOpen;
        emit AuctionOpened(receivableId, auctionId);
    }

    function recordAuctionResult(bytes32 receivableId, uint256 auctionId, address winner, uint256 advance)
        external
        onlyAuction
    {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.AuctionOpen);

        if (r.auctionId != auctionId) revert AuctionMismatch(r.auctionId, auctionId);
        if (winner == address(0)) revert InvalidWinner();
        if (advance == 0) revert ZeroAdvance();
        if (advance > r.faceValue) revert AdvanceExceedsFaceValue(advance, r.faceValue);

        r.financier = winner;
        r.advanceAmount = advance;
        r.fundingDeadline = uint64(block.timestamp) + FUNDING_WINDOW;
        r.status = ReceivableStatus.AuctionClosed;
        emit AuctionClosed(receivableId, auctionId, winner, advance);
    }

    function recordAuctionFailure(bytes32 receivableId, uint256 auctionId) external onlyAuction {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.AuctionOpen);
        if (r.auctionId != auctionId) revert AuctionMismatch(r.auctionId, auctionId);

        r.status = ReceivableStatus.BuyerConfirmed;
        emit AuctionFailed(receivableId, auctionId);
    }

    function fundReceivable(
        bytes32 receivableId,
        ComplianceGate.CompliancePermit calldata financierPermit,
        bytes calldata financierComplianceSignature,
        ComplianceGate.CompliancePermit calldata sellerPermit,
        bytes calldata sellerComplianceSignature
    ) external nonReentrant {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.AuctionClosed);
        if (msg.sender != r.financier) revert NotFinancier(msg.sender, r.financier);
        if (block.timestamp > r.fundingDeadline) revert FundingWindowExpired(r.fundingDeadline, block.timestamp);

        assert(
            complianceGate.verifyPermit(
                financierPermit, financierComplianceSignature, msg.sender, ComplianceActions.SETTLE, receivableId
            )
        );
        assert(
            complianceGate.verifyPermit(
                sellerPermit, sellerComplianceSignature, r.seller, ComplianceActions.SETTLE, receivableId
            )
        );

        r.status = ReceivableStatus.Funded;
        _transferExact(IERC20(r.settlementAsset), msg.sender, r.seller, r.advanceAmount);

        emit ReceivableFunded(receivableId, r.financier, r.seller, r.advanceAmount);
    }

    function repayReceivable(
        bytes32 receivableId,
        ComplianceGate.CompliancePermit calldata buyerPermit,
        bytes calldata buyerComplianceSignature,
        ComplianceGate.CompliancePermit calldata financierPermit,
        bytes calldata financierComplianceSignature
    ) external nonReentrant {
        Receivable storage r = _get(receivableId);
        if (r.status != ReceivableStatus.Funded && r.status != ReceivableStatus.Overdue) {
            revert UnexpectedStatus(r.status, ReceivableStatus.Funded);
        }
        if (msg.sender != r.buyer) revert NotBuyer(msg.sender, r.buyer);

        assert(
            complianceGate.verifyPermit(
                buyerPermit, buyerComplianceSignature, msg.sender, ComplianceActions.REPAY, receivableId
            )
        );
        assert(
            complianceGate.verifyPermit(
                financierPermit, financierComplianceSignature, r.financier, ComplianceActions.REPAY, receivableId
            )
        );

        r.status = ReceivableStatus.Repaid;
        _transferExact(IERC20(r.settlementAsset), msg.sender, r.financier, r.faceValue);

        emit ReceivableRepaid(receivableId, r.buyer, r.financier, r.faceValue);
    }

    function expireUnfunded(bytes32 receivableId) external {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.AuctionClosed);
        if (block.timestamp <= r.fundingDeadline) {
            revert FundingWindowStillOpen(r.fundingDeadline, block.timestamp);
        }

        uint256 auctionId = r.auctionId;
        address financier = r.financier;
        r.financier = address(0);
        r.advanceAmount = 0;
        r.fundingDeadline = 0;
        r.status = ReceivableStatus.BuyerConfirmed;

        emit FundingExpired(receivableId, auctionId, financier);
    }

    function markOverdue(bytes32 receivableId) external {
        Receivable storage r = _get(receivableId);
        _expect(r.status, ReceivableStatus.Funded);

        if (block.timestamp <= r.dueDate) revert NotYetDue(r.dueDate, block.timestamp);

        r.status = ReceivableStatus.Overdue;
        emit ReceivableOverdue(receivableId, r.dueDate);
    }

    function cancelReceivable(bytes32 receivableId) external {
        Receivable storage r = _get(receivableId);
        if (msg.sender != r.seller) revert NotSeller(msg.sender, r.seller);
        _expect(r.status, ReceivableStatus.Created);

        r.status = ReceivableStatus.Cancelled;
        emit ReceivableCancelled(receivableId, r.seller);
    }

    function getReceivable(bytes32 receivableId) external view returns (Receivable memory) {
        return _get(receivableId);
    }

    function exists(bytes32 receivableId) external view returns (bool) {
        return _receivables[receivableId].status != ReceivableStatus.None;
    }

    function statusOf(bytes32 receivableId) external view returns (ReceivableStatus) {
        return _receivables[receivableId].status;
    }

    function hashBuyerConfirmation(bytes32 receivableId) public view returns (bytes32) {
        Receivable storage r = _get(receivableId);
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    BUYER_CONFIRMATION_TYPEHASH, receivableId, r.seller, r.buyer, r.faceValue, r.dueDate, r.fingerprint
                )
            )
        );
    }

    function setAuctionContract(address newAuction) external onlyOwner {
        if (newAuction == address(0)) revert InvalidAddress();
        if (auctionContract != address(0)) revert AuctionContractAlreadySet(auctionContract);
        emit AuctionContractUpdated(auctionContract, newAuction);
        auctionContract = newAuction;
    }

    ////////////////////////////////
    //     INTERNAL FUNCTIONS     //
    ////////////////////////////////

    function _get(bytes32 receivableId) private view returns (Receivable storage r) {
        r = _receivables[receivableId];
        if (r.status == ReceivableStatus.None) revert UnknownReceivable(receivableId);
    }

    function _expect(ReceivableStatus actual, ReceivableStatus expected) private pure {
        if (actual != expected) revert UnexpectedStatus(actual, expected);
    }

    function _transferExact(IERC20 asset, address from, address to, uint256 amount) private {
        uint256 beforeBalance = asset.balanceOf(to);
        asset.safeTransferFrom(from, to, amount);
        uint256 received = asset.balanceOf(to) - beforeBalance;
        if (received != amount) revert UnexpectedTransferAmount(amount, received);
    }
}
