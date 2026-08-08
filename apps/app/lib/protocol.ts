import { getAddress, keccak256, stringToHex, type Address, type Hex } from "viem"

import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"

export const compliancePermitComponents = [
  { name: "wallet", type: "address" },
  { name: "action", type: "bytes32" },
  { name: "subjectId", type: "bytes32" },
  { name: "asset", type: "address" },
  { name: "checkedAt", type: "uint256" },
  { name: "expiresAt", type: "uint256" },
  { name: "nonce", type: "uint256" },
] as const

export const receivableInputComponents = [
  { name: "buyer", type: "address" },
  { name: "invoiceReferenceHash", type: "bytes32" },
  { name: "documentHash", type: "bytes32" },
  { name: "currency", type: "bytes32" },
  { name: "faceValue", type: "uint256" },
  { name: "issueDate", type: "uint64" },
  { name: "dueDate", type: "uint64" },
  { name: "settlementAsset", type: "address" },
] as const

export const receivableComponents = [
  { name: "id", type: "bytes32" },
  { name: "seller", type: "address" },
  { name: "buyer", type: "address" },
  { name: "fingerprint", type: "bytes32" },
  { name: "documentHash", type: "bytes32" },
  { name: "faceValue", type: "uint256" },
  { name: "issueDate", type: "uint64" },
  { name: "dueDate", type: "uint64" },
  { name: "settlementAsset", type: "address" },
  { name: "status", type: "uint8" },
  { name: "auctionId", type: "uint256" },
  { name: "financier", type: "address" },
  { name: "advanceAmount", type: "uint256" },
  { name: "fundingDeadline", type: "uint64" },
] as const

export const registryAbi = [
  { type: "function", name: "computeFingerprint", stateMutability: "pure", inputs: [{ name: "seller", type: "address" }, { name: "input", type: "tuple", components: receivableInputComponents }], outputs: [{ name: "", type: "bytes32" }] },
  { type: "function", name: "computeReceivableId", stateMutability: "view", inputs: [{ name: "fingerprint", type: "bytes32" }], outputs: [{ name: "", type: "bytes32" }] },
  { type: "function", name: "getReceivable", stateMutability: "view", inputs: [{ name: "receivableId", type: "bytes32" }], outputs: [{ name: "", type: "tuple", components: receivableComponents }] },
  { type: "function", name: "createReceivable", stateMutability: "nonpayable", inputs: [{ name: "input", type: "tuple", components: receivableInputComponents }, { name: "permit", type: "tuple", components: compliancePermitComponents }, { name: "complianceSignature", type: "bytes" }], outputs: [{ name: "receivableId", type: "bytes32" }] },
  { type: "function", name: "confirmReceivable", stateMutability: "nonpayable", inputs: [{ name: "receivableId", type: "bytes32" }, { name: "buyerSignature", type: "bytes" }, { name: "permit", type: "tuple", components: compliancePermitComponents }, { name: "complianceSignature", type: "bytes" }], outputs: [] },
  { type: "function", name: "fundReceivable", stateMutability: "nonpayable", inputs: [{ name: "receivableId", type: "bytes32" }, { name: "financierPermit", type: "tuple", components: compliancePermitComponents }, { name: "financierComplianceSignature", type: "bytes" }, { name: "sellerPermit", type: "tuple", components: compliancePermitComponents }, { name: "sellerComplianceSignature", type: "bytes" }], outputs: [] },
  { type: "function", name: "repayReceivable", stateMutability: "nonpayable", inputs: [{ name: "receivableId", type: "bytes32" }, { name: "buyerPermit", type: "tuple", components: compliancePermitComponents }, { name: "buyerComplianceSignature", type: "bytes" }, { name: "financierPermit", type: "tuple", components: compliancePermitComponents }, { name: "financierComplianceSignature", type: "bytes" }], outputs: [] },
] as const

export const auctionAbi = [
  { type: "function", name: "createAuction", stateMutability: "nonpayable", inputs: [{ name: "receivableId", type: "bytes32" }, { name: "closesAt", type: "uint64" }, { name: "reserveAmount", type: "uint256" }], outputs: [{ name: "auctionId", type: "uint256" }] },
  { type: "function", name: "submitBid", stateMutability: "payable", inputs: [{ name: "auctionId", type: "uint256" }, { name: "encryptedBid", type: "bytes" }, { name: "permit", type: "tuple", components: compliancePermitComponents }, { name: "complianceSignature", type: "bytes" }], outputs: [] },
  { type: "function", name: "getAuction", stateMutability: "view", inputs: [{ name: "auctionId", type: "uint256" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "receivableId", type: "bytes32" }, { name: "opensAt", type: "uint64" },
    { name: "closesAt", type: "uint64" }, { name: "reserveAmount", type: "uint256" },
    { name: "revealRequested", type: "bool" }, { name: "finalized", type: "bool" },
    { name: "highestBid", type: "bytes32" }, { name: "winningBidderIndex", type: "bytes32" },
    { name: "revealedHighestBid", type: "uint256" }, { name: "revealedWinner", type: "address" },
  ] }], },
] as const

export const erc20Abi = [
  { type: "function", name: "approve", stateMutability: "nonpayable", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ name: "", type: "bool" }] },
  { type: "function", name: "allowance", stateMutability: "view", inputs: [{ name: "owner", type: "address" }, { name: "spender", type: "address" }], outputs: [{ name: "", type: "uint256" }] },
] as const

export const incoExecutorAbi = [
  { type: "function", name: "getFee", stateMutability: "pure", inputs: [], outputs: [{ name: "", type: "uint256" }] },
] as const

export const complianceActions = {
  create: keccak256(stringToHex("BIDNOX_CREATE_RECEIVABLE")),
  confirm: keccak256(stringToHex("BIDNOX_CONFIRM_RECEIVABLE")),
  bid: keccak256(stringToHex("BIDNOX_BID")),
  fund: keccak256(stringToHex("BIDNOX_SETTLE")),
  repay: keccak256(stringToHex("BIDNOX_REPAY")),
} as const

export type PermitAction = keyof typeof complianceActions

export type ReceivableInput = {
  buyer: Address
  invoiceReferenceHash: Hex
  documentHash: Hex
  currency: Hex
  faceValue: bigint
  issueDate: bigint
  dueDate: bigint
  settlementAsset: Address
}

export type CompliancePermit = {
  wallet: Address
  action: Hex
  subjectId: Hex
  asset: Address
  checkedAt: bigint
  expiresAt: bigint
  nonce: bigint
}

export const permitTypes = { CompliancePermit: compliancePermitComponents } as const
export const buyerConfirmationTypes = { BuyerConfirmation: [
  { name: "receivableId", type: "bytes32" }, { name: "seller", type: "address" },
  { name: "buyer", type: "address" }, { name: "faceValue", type: "uint256" },
  { name: "dueDate", type: "uint64" }, { name: "fingerprint", type: "bytes32" },
] } as const

export const gateDomain = {
  name: "Bidnox ComplianceGate",
  version: "1",
  chainId: BIDNOX_BASE_SEPOLIA.chainId,
  verifyingContract: getAddress(BIDNOX_BASE_SEPOLIA.complianceGate),
} as const

export const registryDomain = {
  name: "Bidnox ReceivableRegistry",
  version: "1",
  chainId: BIDNOX_BASE_SEPOLIA.chainId,
  verifyingContract: getAddress(BIDNOX_BASE_SEPOLIA.receivableRegistry),
} as const

export function permitRequestMessage(caller: Address, action: PermitAction, subjectId: Hex, issuedAt: number) {
  return [
    "Authorize Bidnox compliance check",
    `Chain: ${BIDNOX_BASE_SEPOLIA.chainId}`,
    `Caller: ${getAddress(caller)}`,
    `Action: ${action}`,
    `Subject: ${subjectId}`,
    `Issued at: ${issuedAt}`,
  ].join("\n")
}

export function deserializePermit(value: Record<string, string>): CompliancePermit {
  return {
    wallet: getAddress(value.wallet), action: value.action as Hex,
    subjectId: value.subjectId as Hex, asset: getAddress(value.asset),
    checkedAt: BigInt(value.checkedAt), expiresAt: BigInt(value.expiresAt), nonce: BigInt(value.nonce),
  }
}
