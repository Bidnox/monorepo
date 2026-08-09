"use client"

import * as React from "react"
import { ExternalLink, FileText, LockKeyhole, ShieldCheck } from "lucide-react"
import { useAccount } from "wagmi"

import type { EvidenceEvent, Receivable } from "@/lib/bidnox"
import {
  CompanyIdentity,
  CopyableAddress,
  LocalDateTime,
  Money,
  SettlementToken,
  SourceBadge,
  TransactionLink,
} from "@/components/receivable-primitives"
import { Badge } from "@/components/ui/badge"
import { Card, CardHeader, CardPanel, CardTitle } from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Separator } from "@/components/ui/separator"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"

function DetailRows({
  rows,
}: {
  rows: Array<{ label: string; value: React.ReactNode }>
}) {
  return (
    <dl className="divide-y">
      {rows.map((row) => (
        <div
          key={row.label}
          className="grid grid-cols-[minmax(7rem,0.8fr)_1.2fr] gap-4 py-3 text-sm"
        >
          <dt className="text-muted-foreground">{row.label}</dt>
          <dd className="text-right font-medium sm:text-left">{row.value}</dd>
        </div>
      ))}
    </dl>
  )
}

export function PrivacySummary() {
  return (
    <section className="relative flex items-start gap-3 overflow-hidden rounded-2xl border border-emerald-500/20 bg-emerald-500/[0.045] p-4 shadow-sm sm:p-5">
      <div className="pointer-events-none absolute -top-16 -right-10 size-36 rounded-full bg-emerald-400/10 blur-2xl" />
      <div className="relative grid size-10 shrink-0 place-items-center rounded-xl border border-emerald-500/20 bg-background text-emerald-700 shadow-sm dark:text-emerald-400">
        <LockKeyhole className="size-4" aria-hidden="true" />
      </div>
      <div className="relative">
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-sm font-medium">Privacy is on by default</h2>
          <Badge variant="success">Powered by Inco</Badge>
        </div>
        <p className="mt-1 text-xs leading-5 text-muted-foreground">
          Bids are encrypted in the browser and compared privately. Only the winner is revealed; losing bids stay hidden.
        </p>
        <div className="mt-2 text-xs text-muted-foreground">Public settlement: <SettlementToken className="ml-1 font-medium text-foreground" /></div>
      </div>
    </section>
  )
}

export function ReceivableSummary({ receivable }: { receivable: Receivable }) {
  return (
    <section>
      <h2 className="mb-3 text-sm font-medium">Deal summary</h2>
      <DetailRows
        rows={[
          {
            label: "Seller",
            value: <CompanyIdentity name={receivable.seller} />,
          },
          {
            label: "Buyer",
            value: <CompanyIdentity name={receivable.buyer} />,
          },
          {
            label: "Face value",
            value: <Money value={receivable.faceValue} />,
          },
          { label: "Due date", value: <LocalDateTime timestamp={receivable.dueDateTimestamp} /> },
          { label: "Settlement", value: <SettlementToken /> },
        ]}
      />
    </section>
  )
}

export function AuctionPanel({ receivable }: { receivable: Receivable }) {
  const isActive = receivable.status === "Auction open"
  const isClosed = ["Auction closed", "Funded", "Repaid"].includes(
    receivable.status
  )

  return (
    <section>
      <div className="mb-3 flex items-center justify-between gap-3">
        <h2 className="text-sm font-medium">Financing</h2>
        {isActive ? <Badge variant="outline">Private with Inco</Badge> : null}
      </div>

      {!isActive && !isClosed ? (
        <div className="border-y">
          <Empty className="py-10">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <ShieldCheck />
              </EmptyMedia>
              <EmptyTitle className="text-base">No auction yet</EmptyTitle>
              <EmptyDescription>
                No auction has been opened for this receivable.
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        </div>
      ) : null}

      {isActive ? (
        <div className="border-y py-5">
          <div className="grid gap-6 sm:grid-cols-2">
            <div>
              <p className="text-xs text-muted-foreground">Auction closes</p>
              <LocalDateTime className="mt-1 block text-xl font-medium" timestamp={receivable.auctionClosesAtTimestamp} />
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Private bids</p>
              <p className="mt-1 text-xl font-medium tabular-nums">
                {receivable.bidders ?? 0}
              </p>
            </div>
          </div>
          <p className="mt-5 text-sm text-muted-foreground">
            Bids are sealed until the auction closes. No rank or leading offer
            is disclosed.
          </p>
          {receivable.sealedBids.length ? (
            <div className="mt-4 flex flex-wrap gap-2">
              {receivable.sealedBids.map((bid, index) => (
                <span className="inline-flex items-center gap-1.5 rounded-md bg-muted px-2 py-1 text-xs" key={bid.transaction}>
                  Encrypted bid {index + 1}
                  <TransactionLink hash={bid.transaction} />
                </span>
              ))}
            </div>
          ) : null}
        </div>
      ) : null}

      {isClosed ? (
        <div className="border-y py-5">
          <p className="text-xs text-muted-foreground">Winning offer</p>
          <p className="mt-1 text-2xl font-medium">
            <Money value={receivable.advance ?? 0} />
          </p>
          <DetailRows
            rows={[
              {
                label: "Financier",
                value: receivable.financier ? (
                  <CopyableAddress value={receivable.financier} />
                ) : (
                  "—"
                ),
              },
              {
                label: "Discount",
                value: (
                  <Money
                    value={receivable.faceValue - (receivable.advance ?? 0)}
                  />
                ),
              },
            ]}
          />
          <p className="text-sm text-muted-foreground">
            {Math.max(receivable.bidders - 1, 0)} losing bids remain private.
          </p>
        </div>
      ) : null}
    </section>
  )
}

export function EvidenceTimeline({
  receivable,
  showHeading = true,
}: {
  receivable: Receivable
  showHeading?: boolean
}) {
  const events: EvidenceEvent[] = receivable.evidenceEvents

  return (
    <section>
      {showHeading ? (
        <div className="mb-5">
          <h2 className="text-sm font-medium">Evidence timeline</h2>
          <p className="mt-1 text-xs text-muted-foreground">
            Bidnox workflow events with their originating system.
          </p>
        </div>
      ) : null}
      <ol className="divide-y rounded-lg border">
        {events.map((event) => (
          <li
            key={`${event.event}-${event.time}`}
            className="flex items-center justify-between gap-3 px-3 py-2.5"
          >
            <div className="min-w-0">
                <p className="text-sm font-medium">{event.event}</p>
                <p className="mt-1 text-xs text-muted-foreground">{event.time}</p>
            </div>
            <div className="shrink-0">
                <SourceBadge source={event.source} />
                {event.transaction ? (
                  <TransactionLink hash={event.transaction} />
                ) : null}
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}

export function CompliancePanel({ receivable }: { receivable: Receivable }) {
  const [status, setStatus] = React.useState<{
    eligible: boolean
    checkedAt: string
    participants: Array<{ role: string; wallet: string; verified: boolean }>
  }>()
  const [unavailable, setUnavailable] = React.useState(false)

  React.useEffect(() => {
    fetch(`/api/cleanverse/status?receivableId=${receivable.id}`, {
      cache: "no-store",
    })
      .then((response) => (response.ok ? response.json() : Promise.reject()))
      .then((result) => { setStatus(result); setUnavailable(false) })
      .catch(() => setUnavailable(true))
  }, [receivable.id])

  return (
    <Card className="rounded-xl shadow-none" data-receivable-status={receivable.status}>
      <CardPanel className="p-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2 text-sm"><ShieldCheck className="size-4 text-emerald-600" /><span className="font-medium">Cleanverse</span><span className="text-muted-foreground">A-Pass + aUSDC settlement</span></div>
          <div className="flex items-center gap-2">
            <Badge variant={!status && !unavailable ? "secondary" : status?.eligible ? "success" : "warning"}>{!status && !unavailable ? "Checking" : status?.eligible ? "Eligible" : "Review"}</Badge>
            <a className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground" href={`${BIDNOX_BASE_SEPOLIA.explorer}/token/${BIDNOX_BASE_SEPOLIA.aUSDC}`} target="_blank" rel="noreferrer"><SettlementToken /><ExternalLink className="size-3" /></a>
          </div>
        </div>
        <details className="group mt-3 border-t pt-3 text-xs">
          <summary className="cursor-pointer text-muted-foreground">Participant verification details</summary>
          <div className="mt-3 grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {status?.participants.map((participant) => <div className="flex items-center justify-between gap-2 rounded-md bg-muted/50 p-2" key={participant.wallet}><div className="min-w-0"><p className="font-medium">{participant.role}</p><p className="truncate font-mono text-muted-foreground">{participant.wallet}</p></div><Badge variant={participant.verified ? "success" : "warning"}>{participant.verified ? "Verified" : "Review"}</Badge></div>)}
            {!status ? <p className="text-muted-foreground">{unavailable ? "Status unavailable." : "Checking participants…"}</p> : null}
          </div>
        </details>
      </CardPanel>
    </Card>
  )
}

export function DocumentPanel({ receivable }: { receivable: Receivable }) {
  const { address } = useAccount()
  const [ipfs, setIpfs] = React.useState<{ cid: string; reference: string }>()

  React.useEffect(() => {
    if (!address) return
    fetch(`/api/pinata/document?receivableId=${receivable.id}&caller=${address}`, { cache: "no-store" })
      .then((response) => response.ok ? response.json() : Promise.reject())
      .then(setIpfs)
      .catch(() => setIpfs(undefined))
  }, [address, receivable.id])

  return (
    <Card className="rounded-xl shadow-none">
      <CardHeader className="p-5 pb-3">
        <CardTitle className="text-sm">Private invoice commitment</CardTitle>
      </CardHeader>
      <CardPanel className="px-5 pb-5">
        <div className="flex items-center gap-3">
          <div className="grid size-9 place-items-center rounded-lg bg-muted">
            <FileText className="size-4" aria-hidden="true" />
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-medium">
              {receivable.documentName}
            </p>
            <p className="text-xs text-muted-foreground">
              {receivable.documentSize}
            </p>
          </div>
        </div>
        <Separator className="my-4" />
        <p className="text-xs text-muted-foreground">Onchain document fingerprint</p>
        <div className="mt-1">
          <CopyableAddress
            value={receivable.fingerprint}
            display={`${receivable.fingerprint.slice(0, 10)}…${receivable.fingerprint.slice(-8)}`}
          />
        </div>
        {ipfs ? <div className="mt-4"><p className="text-xs text-muted-foreground">Private IPFS reference</p><a className="mt-1 inline-flex max-w-full items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground" href={ipfs.reference} rel="noreferrer"><span className="truncate">{ipfs.reference}</span><ExternalLink className="size-3 shrink-0" /></a></div> : null}
      </CardPanel>
    </Card>
  )
}

export function AuctionDetails({ receivable }: { receivable: Receivable }) {
  if (
    !["Auction open", "Auction closed", "Funded", "Repaid"].includes(
      receivable.status
    )
  ) {
    return null
  }

  return (
    <section className="border-y py-4">
      <h2 className="mb-2 text-sm font-medium">Auction</h2>
      <DetailRows
        rows={[
          { label: "Started", value: <LocalDateTime timestamp={receivable.auctionOpensAtTimestamp} /> },
          { label: "Closes", value: <LocalDateTime timestamp={receivable.auctionClosesAtTimestamp} /> },
          { label: "Bidders", value: receivable.bidders },
          { label: "Privacy", value: "Sealed bids" },
        ]}
      />
    </section>
  )
}

export function SettlementPanel({ receivable }: { receivable: Receivable }) {
  const funded = ["Funded", "Repaid"].includes(receivable.status)

  if (!["Auction closed", "Funded", "Repaid"].includes(receivable.status))
    return null

  return (
    <section className="border-y py-5">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-sm font-medium">
          {funded ? "Funding complete" : "Ready to fund"}
        </h2>
          <Badge variant="outline">Cleanverse CVA · aUSDC</Badge>
      </div>
      {funded ? (
        <div>
          <p className="text-2xl font-medium">
            <Money value={receivable.advance ?? 0} />
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            <SettlementToken /> sent to {receivable.seller}
          </p>
          {receivable.fundingTransaction ? (
            <div className="mt-4">
              <TransactionLink hash={receivable.fundingTransaction} />
            </div>
          ) : null}
        </div>
      ) : (
        <>
          <p className="mt-5 text-xs text-muted-foreground">
            No funding transfer has been observed for this receivable yet.
          </p>
        </>
      )}
    </section>
  )
}

export function RepaymentPanel({ receivable }: { receivable: Receivable }) {
  if (!["Funded", "Repaid"].includes(receivable.status)) return null

  return (
    <section>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-sm font-medium">Repayment</h2>
        <Badge
          variant={receivable.status === "Repaid" ? "success" : "secondary"}
        >
          {receivable.status === "Repaid" ? "Repaid in aUSDC" : "Awaiting aUSDC repayment"}
        </Badge>
      </div>
      <p className="text-2xl font-medium">
        <Money value={receivable.faceValue} />
      </p>
      <DetailRows
        rows={[
          { label: "Due", value: <LocalDateTime timestamp={receivable.dueDateTimestamp} /> },
          { label: "Paid by", value: receivable.buyer },
          { label: "Paid to", value: "Winning financier" },
        ]}
      />
      {receivable.repaymentTransaction ? (
        <TransactionLink hash={receivable.repaymentTransaction} />
      ) : null}
    </section>
  )
}
