export type ReceivableStatus =
  | "Awaiting buyer"
  | "Buyer confirmed"
  | "Auction open"
  | "Auction closed"
  | "Funded"
  | "Repaid"
  | "Overdue"
  | "Cancelled"

export type EvidenceEvent = {
  event: string
  source: "Bidnox" | "Inco" | "Cleanverse" | "Blockchain"
  time: string
  transaction: string
}

export type SealedBid = {
  bidder: string
  transaction: string
}

export type Receivable = {
  id: string
  reference: string
  seller: string
  buyer: string
  faceValue: number
  advance?: number
  issueDate: string
  issueDateTimestamp: number
  dueDate: string
  dueDateTimestamp: number
  dueShort: string
  status: ReceivableStatus
  documentName: string
  documentSize: string
  documentHash: string
  fingerprint: string
  bidders: number
  auctionId?: number
  auctionOpensAt?: string
  auctionOpensAtTimestamp?: number
  auctionClosesAt?: string
  auctionClosesAtTimestamp?: number
  auctionRevealRequested?: boolean
  auctionFinalized?: boolean
  revealedWinner?: string
  revealedHighestBid?: number
  sealedBids: SealedBid[]
  financier?: string
  evidenceEvents: EvidenceEvent[]
  fundingTransaction?: string
  repaymentTransaction?: string
}

export type ActivityRow = EvidenceEvent & { receivable: string }

export function formatMoney(value: number) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 2,
  }).format(value)
}
