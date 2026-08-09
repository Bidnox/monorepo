import "server-only"

import {
  createPublicClient,
  formatUnits,
  http,
  parseAbiItem,
  type AbiEvent,
  type Address,
  type GetLogsParameters,
  type GetLogsReturnType,
  type Hex,
} from "viem"
import { baseSepolia } from "viem/chains"

import type {
  ActivityRow,
  EvidenceEvent,
  Receivable,
  ReceivableStatus,
  SealedBid,
} from "@/lib/bidnox"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"

const registryReadAbi = [
  {
    type: "function",
    name: "getReceivable",
    stateMutability: "view",
    inputs: [{ name: "receivableId", type: "bytes32" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
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
        ],
      },
    ],
  },
] as const

const auctionReadAbi = [
  {
    type: "function",
    name: "bidderCount",
    stateMutability: "view",
    inputs: [{ name: "auctionId", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "getAuction",
    stateMutability: "view",
    inputs: [{ name: "auctionId", type: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        components: [
          { name: "receivableId", type: "bytes32" },
          { name: "opensAt", type: "uint64" },
          { name: "closesAt", type: "uint64" },
          { name: "reserveAmount", type: "uint256" },
          { name: "revealRequested", type: "bool" },
          { name: "finalized", type: "bool" },
          { name: "highestBid", type: "bytes32" },
          { name: "winningBidderIndex", type: "bytes32" },
          { name: "revealedHighestBid", type: "uint256" },
          { name: "revealedWinner", type: "address" },
        ],
      },
    ],
  },
] as const

const createdEvent = parseAbiItem(
  "event ReceivableCreated(bytes32 indexed receivableId,address indexed seller,address indexed buyer,bytes32 fingerprint,uint256 faceValue,uint64 dueDate,address settlementAsset)"
)
const registryEvents = [
  createdEvent,
  parseAbiItem(
    "event BuyerConfirmed(bytes32 indexed receivableId,address indexed buyer,bytes32 fingerprint)"
  ),
  parseAbiItem(
    "event AuctionOpened(bytes32 indexed receivableId,uint256 indexed auctionId)"
  ),
  parseAbiItem(
    "event AuctionClosed(bytes32 indexed receivableId,uint256 indexed auctionId,address indexed financier,uint256 advanceAmount)"
  ),
  parseAbiItem(
    "event ReceivableFunded(bytes32 indexed receivableId,address indexed financier,address indexed seller,uint256 advanceAmount)"
  ),
  parseAbiItem(
    "event ReceivableRepaid(bytes32 indexed receivableId,address indexed buyer,address indexed financier,uint256 amount)"
  ),
  parseAbiItem(
    "event ReceivableOverdue(bytes32 indexed receivableId,uint64 dueDate)"
  ),
  parseAbiItem(
    "event ReceivableCancelled(bytes32 indexed receivableId,address indexed seller)"
  ),
] as const
const auctionEvents = [
  parseAbiItem(
    "event BidSubmitted(uint256 indexed auctionId,address indexed bidder)"
  ),
  parseAbiItem("event AuctionRevealRequested(uint256 indexed auctionId)"),
  parseAbiItem(
    "event AuctionFinalized(uint256 indexed auctionId,address indexed winner,uint256 advanceAmount)"
  ),
] as const

function client() {
  return createPublicClient({
    chain: baseSepolia,
    transport: http(process.env.BASE_SEPOLIA_RPC_URL),
  })
}

// Base's public RPC rejects eth_getLogs requests spanning more than 2,000
// blocks. Keep this below the inclusive provider limit so the same code works
// with both the public fallback and paid RPC providers.
const MAX_LOG_BLOCKS = 2_000n

type EventLogQuery<TEvent extends AbiEvent> = {
  address: NonNullable<GetLogsParameters<TEvent>["address"]>
  event: TEvent
  args?: GetLogsParameters<TEvent>["args"]
}

async function getLogsInChunks<const TEvent extends AbiEvent>(
  publicClient: ReturnType<typeof client>,
  query: EventLogQuery<TEvent>,
  fromBlock: bigint,
  toBlock: bigint
): Promise<GetLogsReturnType<TEvent>> {
  const logs: GetLogsReturnType<TEvent> = []

  for (let start = fromBlock; start <= toBlock; start += MAX_LOG_BLOCKS) {
    const end =
      start + MAX_LOG_BLOCKS - 1n < toBlock
        ? start + MAX_LOG_BLOCKS - 1n
        : toBlock
    const chunk = await publicClient.getLogs({
      ...query,
      fromBlock: start,
      toBlock: end,
    })
    logs.push(...chunk)
  }

  return logs
}

type EvidenceLog = {
  eventName: string
  blockNumber: bigint
  transactionHash: Hex
  args: Record<string, unknown>
}

const evidenceLabels: Record<
  string,
  { event: string; source: EvidenceEvent["source"] }
> = {
  ReceivableCreated: { event: "Receivable created", source: "Bidnox" },
  BuyerConfirmed: { event: "Buyer confirmed", source: "Bidnox" },
  AuctionOpened: { event: "Auction opened", source: "Bidnox" },
  AuctionClosed: { event: "Winning bid recorded", source: "Inco" },
  ReceivableFunded: {
    event: "Seller funded in aUSDC",
    source: "Blockchain",
  },
  ReceivableRepaid: {
    event: "Buyer repaid in aUSDC",
    source: "Blockchain",
  },
  ReceivableOverdue: {
    event: "Receivable marked overdue",
    source: "Bidnox",
  },
  ReceivableCancelled: {
    event: "Receivable cancelled",
    source: "Bidnox",
  },
  BidSubmitted: { event: "Encrypted bid submitted", source: "Inco" },
  AuctionRevealRequested: {
    event: "Winner reveal requested",
    source: "Inco",
  },
  AuctionFinalized: { event: "Winner finalized", source: "Inco" },
}

let activityCache:
  | { expiresAt: number; rows: ActivityRow[] }
  | undefined

async function getEventSetLogsInChunks<
  const TEvents extends readonly AbiEvent[],
>(
  publicClient: ReturnType<typeof client>,
  address: Address,
  events: TEvents,
  fromBlock: bigint,
  toBlock: bigint
) {
  const logs: EvidenceLog[] = []
  for (let start = fromBlock; start <= toBlock; start += MAX_LOG_BLOCKS) {
    const end =
      start + MAX_LOG_BLOCKS - 1n < toBlock
        ? start + MAX_LOG_BLOCKS - 1n
        : toBlock
    const chunk = await publicClient.getLogs({
      address,
      events,
      fromBlock: start,
      toBlock: end,
    })
    logs.push(...(chunk as unknown as EvidenceLog[]))
  }
  return logs
}

const statusNames: Record<number, ReceivableStatus> = {
  1: "Awaiting buyer",
  2: "Buyer confirmed",
  3: "Auction open",
  4: "Auction closed",
  5: "Funded",
  6: "Repaid",
  7: "Overdue",
  8: "Cancelled",
}
const date = (value: bigint, short = false) =>
  new Intl.DateTimeFormat(
    "en-GB",
    short
      ? { month: "short", day: "2-digit" }
      : {
          day: "2-digit",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          timeZone: "UTC",
          timeZoneName: "short",
        }
  ).format(new Date(Number(value) * 1000))
const shortAddress = (value: string) =>
  `${value.slice(0, 6)}…${value.slice(-4)}`

async function eventEvidence(
  receivableId: Hex,
  auctionId: bigint
): Promise<{ evidence: EvidenceEvent[]; sealedBids: SealedBid[] }> {
  const publicClient = client()
  const latestBlock = await publicClient.getBlockNumber()
  const [registryLogs, auctionLogs] = await Promise.all([
    getEventSetLogsInChunks(
      publicClient,
      BIDNOX_BASE_SEPOLIA.receivableRegistry,
      registryEvents,
      BIDNOX_BASE_SEPOLIA.deploymentBlock,
      latestBlock
    ).then((logs) =>
      logs.filter((log) => log.args.receivableId === receivableId)
    ),
    auctionId > 0n
      ? getEventSetLogsInChunks(
          publicClient,
          BIDNOX_BASE_SEPOLIA.confidentialAuction,
          auctionEvents,
          BIDNOX_BASE_SEPOLIA.deploymentBlock,
          latestBlock
        ).then((logs) => logs.filter((log) => log.args.auctionId === auctionId))
      : [],
  ])
  const evidence = [...registryLogs, ...auctionLogs]
    .sort((a, b) => Number(a.blockNumber - b.blockNumber))
    .map((log) => {
      const label = evidenceLabels[log.eventName]
      return {
        ...label,
        time: `Block ${log.blockNumber}`,
        transaction: log.transactionHash,
      }
    })
  const sealedBids = auctionLogs.flatMap((log) => {
    if (log.eventName !== "BidSubmitted") return []
    const bidder = log.args.bidder
    return typeof bidder === "string"
      ? [{ bidder, transaction: log.transactionHash }]
      : []
  })
  return { evidence, sealedBids }
}

export async function getReceivableById(
  id: string,
  includeEvidence = true
): Promise<Receivable | undefined> {
  if (!/^0x[0-9a-fA-F]{64}$/.test(id)) return undefined
  const publicClient = client()
  try {
    const value = await publicClient.readContract({
      address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
      abi: registryReadAbi,
      functionName: "getReceivable",
      args: [id as Hex],
    })
    if (Number(value.status) === 0) return undefined
    const emptyDetails: { evidence: EvidenceEvent[]; sealedBids: SealedBid[] } =
      { evidence: [], sealedBids: [] }
    const [auction, bidders, details] = await (async () => {
      try {
        return includeEvidence && value.auctionId > 0n
          ? await Promise.all([
              publicClient.readContract({
                address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
                abi: auctionReadAbi,
                functionName: "getAuction",
                args: [value.auctionId],
              }),
              publicClient.readContract({
                address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
                abi: auctionReadAbi,
                functionName: "bidderCount",
                args: [value.auctionId],
              }),
              eventEvidence(id as Hex, value.auctionId),
            ])
          : ([
              undefined,
              0n,
              includeEvidence
                ? await eventEvidence(id as Hex, 0n)
                : emptyDetails,
            ] as const)
      } catch (error) {
        console.error(
          "Receivable evidence enrichment failed",
          id,
          error instanceof Error ? error.name : "Unknown server error"
        )
        return [undefined, 0n, emptyDetails] as const
      }
    })()
    const { evidence, sealedBids } = details
    const funding = evidence.find(
      (item) => item.event === "Seller funded in aUSDC"
    )
    const repayment = evidence.find(
      (item) => item.event === "Buyer repaid in aUSDC"
    )
    return {
      id,
      reference: `RCV-${id.slice(2, 10).toUpperCase()}`,
      seller: value.seller,
      buyer: value.buyer,
      faceValue: Number(formatUnits(value.faceValue, 6)),
      advance: value.advanceAmount
        ? Number(formatUnits(value.advanceAmount, 6))
        : undefined,
      issueDate: date(value.issueDate),
      issueDateTimestamp: Number(value.issueDate),
      dueDate: date(value.dueDate),
      dueDateTimestamp: Number(value.dueDate),
      dueShort: date(value.dueDate, true),
      status: statusNames[Number(value.status)],
      documentName: `Commitment ${shortAddress(value.documentHash)}`,
      documentSize: "Private file stored offchain; hash anchored onchain",
      documentHash: value.documentHash,
      fingerprint: value.fingerprint,
      bidders: Number(bidders),
      auctionId: Number(value.auctionId),
      auctionOpensAt: auction ? date(auction.opensAt) : undefined,
      auctionOpensAtTimestamp: auction ? Number(auction.opensAt) : undefined,
      auctionClosesAt: auction ? date(auction.closesAt) : undefined,
      auctionClosesAtTimestamp: auction ? Number(auction.closesAt) : undefined,
      auctionRevealRequested: auction?.revealRequested,
      auctionFinalized: auction?.finalized,
      revealedWinner: auction?.finalized ? auction.revealedWinner : undefined,
      revealedHighestBid: auction?.finalized
        ? Number(formatUnits(auction.revealedHighestBid, 6))
        : undefined,
      sealedBids,
      financier: value.financier,
      evidenceEvents: evidence,
      fundingTransaction: funding?.transaction,
      repaymentTransaction: repayment?.transaction,
    }
  } catch {
    return undefined
  }
}

export async function getReceivables(): Promise<Receivable[]> {
  const publicClient = client()
  try {
    const latestBlock = await publicClient.getBlockNumber()
    const logs = await getLogsInChunks(
      publicClient,
      { address: BIDNOX_BASE_SEPOLIA.receivableRegistry, event: createdEvent },
      BIDNOX_BASE_SEPOLIA.deploymentBlock,
      latestBlock
    )
    return (
      await Promise.all(
        logs.map((log) => getReceivableById(log.args.receivableId!, false))
      )
    )
      .filter((item): item is Receivable => Boolean(item))
      .sort((left, right) => right.issueDateTimestamp - left.issueDateTimestamp)
  } catch (error) {
    console.error(
      "Receivables unavailable",
      error instanceof Error ? error.name : "Unknown server error"
    )
    return []
  }
}

export async function getActivity(): Promise<ActivityRow[]> {
  // Activity is a demo-facing recent feed, not a historical indexer. Keep the
  // window within Base's public 2,000-block eth_getLogs limit and issue only
  // one registry query plus one auction query per page load.
  const activityWindow = 1_900n
  const activityLimit = 30
  const cached = activityCache
  if (cached && cached.expiresAt > Date.now()) return cached.rows

  const publicClient = client()

  try {
    const latest = await publicClient.getBlock({ blockTag: "latest" })
    const latestBlock = latest.number
    const recentStart =
      latestBlock >= activityWindow
        ? latestBlock - activityWindow + 1n
        : BIDNOX_BASE_SEPOLIA.deploymentBlock
    const fromBlock =
      recentStart > BIDNOX_BASE_SEPOLIA.deploymentBlock
        ? recentStart
        : BIDNOX_BASE_SEPOLIA.deploymentBlock

    const registryLogs = await getEventSetLogsInChunks(
      publicClient,
      BIDNOX_BASE_SEPOLIA.receivableRegistry,
      registryEvents,
      fromBlock,
      latestBlock
    )
    const auctionLogs = await getEventSetLogsInChunks(
      publicClient,
      BIDNOX_BASE_SEPOLIA.confidentialAuction,
      auctionEvents,
      fromBlock,
      latestBlock
    )

    const auctionReceivables = new Map<bigint, string>()
    for (const log of registryLogs) {
      const auctionId = log.args.auctionId
      const receivableId = log.args.receivableId
      if (typeof auctionId === "bigint" && typeof receivableId === "string") {
        auctionReceivables.set(auctionId, receivableId)
      }
    }

    const activity = [...registryLogs, ...auctionLogs]
      .sort((left, right) => Number(right.blockNumber - left.blockNumber))
      .flatMap((log): ActivityRow[] => {
        const label = evidenceLabels[log.eventName]
        if (!label) return []

        const directId = log.args.receivableId
        const auctionId = log.args.auctionId
        const receivableId =
          typeof directId === "string"
            ? directId
            : typeof auctionId === "bigint"
              ? auctionReceivables.get(auctionId)
              : undefined
        const reference = receivableId
          ? `RCV-${receivableId.slice(2, 10).toUpperCase()}`
          : typeof auctionId === "bigint"
            ? `Auction #${auctionId}`
            : "—"
        const estimatedTimestamp =
          latest.timestamp - (latestBlock - log.blockNumber) * 2n

        return [
          {
            ...label,
            receivable: reference,
            time: `≈ ${date(estimatedTimestamp)}`,
            timestamp: Number(estimatedTimestamp),
            blockNumber: Number(log.blockNumber),
            transaction: log.transactionHash,
          },
        ]
      })
      .slice(0, activityLimit)
    activityCache = { expiresAt: Date.now() + 15_000, rows: activity }
    return activity
  } catch (error) {
    console.error(
      "Recent activity unavailable",
      error instanceof Error ? error.name : "Unknown server error"
    )
    return cached?.rows ?? []
  }
}
