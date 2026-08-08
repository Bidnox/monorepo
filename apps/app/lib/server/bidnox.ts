import "server-only"

import { createPublicClient, formatUnits, http, parseAbiItem, type Hex } from "viem"
import { baseSepolia } from "viem/chains"

import type { ActivityRow, EvidenceEvent, Receivable, ReceivableStatus } from "@/lib/bidnox"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"

const registryReadAbi = [{
  type: "function",
  name: "getReceivable",
  stateMutability: "view",
  inputs: [{ name: "receivableId", type: "bytes32" }],
  outputs: [{ name: "", type: "tuple", components: [
    { name: "id", type: "bytes32" }, { name: "seller", type: "address" },
    { name: "buyer", type: "address" }, { name: "fingerprint", type: "bytes32" },
    { name: "documentHash", type: "bytes32" }, { name: "faceValue", type: "uint256" },
    { name: "issueDate", type: "uint64" }, { name: "dueDate", type: "uint64" },
    { name: "settlementAsset", type: "address" }, { name: "status", type: "uint8" },
    { name: "auctionId", type: "uint256" }, { name: "financier", type: "address" },
    { name: "advanceAmount", type: "uint256" }, { name: "fundingDeadline", type: "uint64" },
  ] }],
}] as const

const auctionReadAbi = [
  { type: "function", name: "bidderCount", stateMutability: "view", inputs: [{ name: "auctionId", type: "uint256" }], outputs: [{ name: "", type: "uint256" }] },
  { type: "function", name: "getAuction", stateMutability: "view", inputs: [{ name: "auctionId", type: "uint256" }], outputs: [{ name: "", type: "tuple", components: [
    { name: "receivableId", type: "bytes32" }, { name: "opensAt", type: "uint64" },
    { name: "closesAt", type: "uint64" }, { name: "reserveAmount", type: "uint256" },
    { name: "revealRequested", type: "bool" }, { name: "finalized", type: "bool" },
    { name: "highestBid", type: "bytes32" }, { name: "winningBidderIndex", type: "bytes32" },
    { name: "revealedHighestBid", type: "uint256" }, { name: "revealedWinner", type: "address" },
  ] }], },
] as const

const createdEvent = parseAbiItem("event ReceivableCreated(bytes32 indexed receivableId,address indexed seller,address indexed buyer,bytes32 fingerprint,uint256 faceValue,uint64 dueDate,address settlementAsset)")
const registryEvents = [
  createdEvent,
  parseAbiItem("event BuyerConfirmed(bytes32 indexed receivableId,address indexed buyer,bytes32 fingerprint)"),
  parseAbiItem("event AuctionOpened(bytes32 indexed receivableId,uint256 indexed auctionId)"),
  parseAbiItem("event AuctionClosed(bytes32 indexed receivableId,uint256 indexed auctionId,address indexed financier,uint256 advanceAmount)"),
  parseAbiItem("event ReceivableFunded(bytes32 indexed receivableId,address indexed financier,address indexed seller,uint256 advanceAmount)"),
  parseAbiItem("event ReceivableRepaid(bytes32 indexed receivableId,address indexed buyer,address indexed financier,uint256 amount)"),
  parseAbiItem("event ReceivableOverdue(bytes32 indexed receivableId,uint64 dueDate)"),
  parseAbiItem("event ReceivableCancelled(bytes32 indexed receivableId,address indexed seller)"),
] as const
const auctionEvents = [
  parseAbiItem("event BidSubmitted(uint256 indexed auctionId,address indexed bidder)"),
  parseAbiItem("event AuctionRevealRequested(uint256 indexed auctionId)"),
  parseAbiItem("event AuctionFinalized(uint256 indexed auctionId,address indexed winner,uint256 advanceAmount)"),
] as const

function client() {
  return createPublicClient({ chain: baseSepolia, transport: http(process.env.BASE_SEPOLIA_RPC_URL) })
}

const statusNames: Record<number, ReceivableStatus> = {
  1: "Awaiting buyer", 2: "Buyer confirmed", 3: "Auction open", 4: "Auction closed",
  5: "Funded", 6: "Repaid", 7: "Overdue", 8: "Cancelled",
}
const date = (value: bigint, short = false) => new Intl.DateTimeFormat("en-GB", short
  ? { month: "short", day: "2-digit" }
  : { day: "2-digit", month: "short", year: "numeric" }
).format(new Date(Number(value) * 1000))
const shortAddress = (value: string) => `${value.slice(0, 6)}…${value.slice(-4)}`

async function eventEvidence(receivableId: Hex, auctionId: bigint): Promise<EvidenceEvent[]> {
  const publicClient = client()
  const [registryLogs, auctionLogs] = await Promise.all([
    Promise.all(registryEvents.map((event) => publicClient.getLogs({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, event, args: { receivableId }, fromBlock: BIDNOX_BASE_SEPOLIA.deploymentBlock }))).then((groups) => groups.flat()),
    auctionId > 0n ? Promise.all(auctionEvents.map((event) => publicClient.getLogs({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, event, args: { auctionId }, fromBlock: BIDNOX_BASE_SEPOLIA.deploymentBlock }))).then((groups) => groups.flat()) : [],
  ])
  const labels: Record<string, { event: string; source: EvidenceEvent["source"] }> = {
    ReceivableCreated: { event: "Receivable created", source: "Bidnox" },
    BuyerConfirmed: { event: "Buyer confirmed", source: "Bidnox" },
    AuctionOpened: { event: "Auction opened", source: "Bidnox" },
    AuctionClosed: { event: "Winning bid recorded", source: "Inco" },
    ReceivableFunded: { event: "Seller funded in aUSDC", source: "Blockchain" },
    ReceivableRepaid: { event: "Buyer repaid in aUSDC", source: "Blockchain" },
    ReceivableOverdue: { event: "Receivable marked overdue", source: "Bidnox" },
    ReceivableCancelled: { event: "Receivable cancelled", source: "Bidnox" },
    BidSubmitted: { event: "Encrypted bid submitted", source: "Inco" },
    AuctionRevealRequested: { event: "Winner reveal requested", source: "Inco" },
    AuctionFinalized: { event: "Winner finalized", source: "Inco" },
  }
  return [...registryLogs, ...auctionLogs]
    .sort((a, b) => Number(a.blockNumber - b.blockNumber))
    .map((log) => {
      const label = labels[log.eventName]
      return { ...label, time: `Block ${log.blockNumber}`, transaction: log.transactionHash }
    })
}

export async function getReceivableById(id: string): Promise<Receivable | undefined> {
  if (!/^0x[0-9a-fA-F]{64}$/.test(id)) return undefined
  const publicClient = client()
  try {
    const value = await publicClient.readContract({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryReadAbi, functionName: "getReceivable", args: [id as Hex] })
    if (Number(value.status) === 0) return undefined
    const [auction, bidders, evidence] = value.auctionId > 0n
      ? await Promise.all([
          publicClient.readContract({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, abi: auctionReadAbi, functionName: "getAuction", args: [value.auctionId] }),
          publicClient.readContract({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, abi: auctionReadAbi, functionName: "bidderCount", args: [value.auctionId] }),
          eventEvidence(id as Hex, value.auctionId),
        ])
      : [undefined, 0n, await eventEvidence(id as Hex, 0n)] as const
    const funding = evidence.find((item) => item.event === "Seller funded in aUSDC")
    const repayment = evidence.find((item) => item.event === "Buyer repaid in aUSDC")
    return {
      id,
      reference: `RCV-${id.slice(2, 10).toUpperCase()}`,
      seller: value.seller,
      buyer: value.buyer,
      faceValue: Number(formatUnits(value.faceValue, 6)),
      advance: value.advanceAmount ? Number(formatUnits(value.advanceAmount, 6)) : undefined,
      issueDate: date(value.issueDate), dueDate: date(value.dueDate), dueShort: date(value.dueDate, true),
      status: statusNames[Number(value.status)],
      documentName: `Hash ${shortAddress(value.documentHash)}`,
      documentSize: "Stored offchain",
      fingerprint: value.fingerprint,
      bidders: Number(bidders), auctionId: Number(value.auctionId),
      auctionOpensAt: auction ? date(auction.opensAt) : undefined,
      auctionClosesAt: auction ? date(auction.closesAt) : undefined,
      financier: value.financier,
      evidenceEvents: evidence,
      fundingTransaction: funding?.transaction,
      repaymentTransaction: repayment?.transaction,
    }
  } catch { return undefined }
}

export async function getReceivables(): Promise<Receivable[]> {
  const logs = await client().getLogs({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, event: createdEvent, fromBlock: BIDNOX_BASE_SEPOLIA.deploymentBlock })
  return (await Promise.all(logs.map((log) => getReceivableById(log.args.receivableId!)))).filter((item): item is Receivable => Boolean(item))
}

export async function getActivity(): Promise<ActivityRow[]> {
  const receivables = await getReceivables()
  return receivables.flatMap((receivable) => receivable.evidenceEvents.map((event) => ({ ...event, receivable: receivable.reference }))).reverse()
}
