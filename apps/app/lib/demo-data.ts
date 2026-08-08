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
  evidenceEvents?: EvidenceEvent[]
  fundingTransaction?: string
  repaymentTransaction?: string
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
  {
    id: "base-sepolia-live",
    reference: "BASE-SEPOLIA-LIVE",
    seller: "0xf653…Aacb",
    buyer: "0x376b…d5b2",
    faceValue: 2,
    advance: 1.8,
    issueDate: "08 Aug 2026",
    dueDate: "07 Sep 2026",
    dueShort: "Sep 07",
    status: "Repaid",
    documentName: "private-demo-invoice-v1",
    documentSize: "Hash only",
    fingerprint: "0x6cdfb8cb3b095ac224956ee13bd36c1060ab945abd1ff3d5afb9a6d94001058e",
    bidders: 2,
    fundingTransaction: "0x163d2e4ed32e6de43a85f0bc6a3876f96269b88087dfac3dcf706cdbc5a8728d",
    repaymentTransaction: "0x096c5beebcfe1617b2dbd8fb5aa38f4e473d1224328e932ba86d5144071a66a9",
    evidenceEvents: [
      { event: "Receivable created", time: "08 Aug", source: "Bidnox", transaction: "0x4e746df0923b624d7738bbf76050f366450a7b591b2f02353d0ac6e84bac0e17" },
      { event: "Buyer confirmed", time: "08 Aug", source: "Cleanverse", transaction: "0xf6474f57b8edae18c5c3e436175a270fd7ecea25188d55a9f3106b153393cf81" },
      { event: "Two sealed bids submitted", time: "08 Aug", source: "Inco", transaction: "0x3786107f592aef1373088b29870380ef9fd2f636de9b2850aaaaa81d1e714a76" },
      { event: "Winner selected: 1.8 aUSDC", time: "08 Aug", source: "Inco", transaction: "0x1c0b73008cd68bbd65c767ee5d8381bf0e134fde06aed011574beed3f1dd6d0b" },
      { event: "Seller funded in aUSDC", time: "08 Aug", source: "Blockchain", transaction: "0x163d2e4ed32e6de43a85f0bc6a3876f96269b88087dfac3dcf706cdbc5a8728d" },
      { event: "Buyer repaid 2 aUSDC", time: "08 Aug", source: "Blockchain", transaction: "0x096c5beebcfe1617b2dbd8fb5aa38f4e473d1224328e932ba86d5144071a66a9" },
    ],
  },
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
