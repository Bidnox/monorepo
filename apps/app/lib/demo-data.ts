export type ReceivableStatus =
  | "Draft"
  | "Awaiting buyer"
  | "Buyer confirmed"
  | "Auction open"
  | "Auction closed"
  | "Funded"
  | "Repaid"
  | "Overdue"

export type Receivable = {
  id: string
  reference: string
  seller: string
  buyer: string
  faceValue: number
  advance?: number
  issueDate: string
  dueDate: string
  dueShort: string
  status: ReceivableStatus
  documentName: string
  documentSize: string
  fingerprint: string
  bidders?: number
}

export type EvidenceEvent = {
  event: string
  source: "Bidnox" | "Inco" | "Cleanverse" | "Blockchain"
  time: string
  transaction?: string
}

export const DEMO_RECEIVABLE: Receivable = {
  id: "inv-2026-041",
  reference: "INV-2026-041",
  seller: "ABC Manufacturing",
  buyer: "Acme Retail",
  faceValue: 1_000_000,
  advance: 920_000,
  issueDate: "08 Aug 2026",
  dueDate: "30 Sep 2026",
  dueShort: "Sep 30",
  status: "Auction open",
  documentName: "invoice-041.pdf",
  documentSize: "184 KB",
  fingerprint: "0xf4a1c971d40e95cc8b2f48a85040b31fd38682de",
  bidders: 3,
}

export const RECEIVABLES: Receivable[] = [
  DEMO_RECEIVABLE,
  {
    ...DEMO_RECEIVABLE,
    id: "inv-2026-040",
    reference: "INV-2026-040",
    buyer: "Northstar Foods",
    faceValue: 640_000,
    advance: undefined,
    dueDate: "18 Oct 2026",
    dueShort: "Oct 18",
    status: "Buyer confirmed",
    documentName: "invoice-040.pdf",
  },
  {
    ...DEMO_RECEIVABLE,
    id: "inv-2026-039",
    reference: "INV-2026-039",
    buyer: "Keystone Stores",
    faceValue: 780_000,
    advance: 716_000,
    dueDate: "12 Sep 2026",
    dueShort: "Sep 12",
    status: "Funded",
    documentName: "invoice-039.pdf",
  },
  {
    ...DEMO_RECEIVABLE,
    id: "inv-2026-038",
    reference: "INV-2026-038",
    buyer: "Orchid Commerce",
    faceValue: 425_000,
    advance: undefined,
    dueDate: "05 Nov 2026",
    dueShort: "Nov 05",
    status: "Awaiting buyer",
    documentName: "invoice-038.pdf",
  },
  {
    ...DEMO_RECEIVABLE,
    id: "inv-2026-032",
    reference: "INV-2026-032",
    buyer: "Acme Retail",
    faceValue: 510_000,
    advance: 470_000,
    dueDate: "31 Jul 2026",
    dueShort: "Jul 31",
    status: "Repaid",
    documentName: "invoice-032.pdf",
  },
]

export const EVIDENCE_EVENTS: EvidenceEvent[] = [
  { event: "Receivable created", time: "08 Aug, 10:02", source: "Bidnox" },
  { event: "Buyer confirmed", time: "08 Aug, 10:11", source: "Bidnox" },
  { event: "Auction opened", time: "08 Aug, 10:20", source: "Bidnox" },
  { event: "3 private bids submitted", time: "08 Aug, 10:35", source: "Inco" },
]

export const CLOSED_EVIDENCE_EVENTS: EvidenceEvent[] = [
  ...EVIDENCE_EVENTS,
  { event: "Winner selected", time: "08 Aug, 11:00", source: "Inco" },
  {
    event: "Winner eligibility checked",
    time: "08 Aug, 11:01",
    source: "Cleanverse",
  },
  {
    event: "$920,000 funded",
    time: "08 Aug, 11:03",
    source: "Blockchain",
    transaction: "0x92c4…a171",
  },
]

export const ACTIVITY = [
  {
    event: "Private bid submitted",
    receivable: "INV-2026-041",
    source: "Inco",
    time: "2m ago",
    transaction: "0x71a2…09cf",
  },
  {
    event: "Buyer confirmed",
    receivable: "INV-2026-041",
    source: "Bidnox",
    time: "24m ago",
    transaction: "0x92c4…a171",
  },
  {
    event: "Eligibility checked",
    receivable: "INV-2026-039",
    source: "Cleanverse",
    time: "1h ago",
    transaction: "—",
  },
  {
    event: "Funding complete",
    receivable: "INV-2026-039",
    source: "Payments",
    time: "1h ago",
    transaction: "0xac18…f90b",
  },
  {
    event: "Receivable created",
    receivable: "INV-2026-038",
    source: "Bidnox",
    time: "Yesterday",
    transaction: "0xdf11…82de",
  },
] as const

export function getReceivable(id: string) {
  return RECEIVABLES.find((receivable) => receivable.id === id)
}

export function formatMoney(value: number) {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value)
}
