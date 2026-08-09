"use client"

import * as React from "react"
import { ChevronDown, ExternalLink, FileText, LockKeyhole, ShieldCheck } from "lucide-react"
import { useAccount } from "wagmi"

import type { EvidenceEvent, Receivable } from "@/lib/bidnox"
import {
  CompanyIdentity,
  CopyableAddress,
  ExplorerAddress,
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
import { PartnerMark } from "@/components/partner-mark"

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
          <Badge variant="success">
            <PartnerMark partner="inco" />
          </Badge>
        </div>
        <p className="mt-1 text-xs leading-5 text-muted-foreground">
          Bids are encrypted in the browser and compared privately. Only the
          winner is revealed; losing bids stay hidden.
        </p>
        <div className="mt-2 text-xs text-muted-foreground">
          Public settlement:{" "}
          <SettlementToken className="ml-1 font-medium text-foreground" />
        </div>
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
          {
            label: "Due date",
            value: <LocalDateTime timestamp={receivable.dueDateTimestamp} />,
          },
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
        {isActive ? (
          <Badge variant="outline">
            <PartnerMark partner="inco" />
            Private bids
          </Badge>
        ) : null}
      </div>

      {!isActive && !isClosed ? (
        <div className="rounded-xl bg-muted/30">
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
        <div className="rounded-xl bg-muted/30 p-4 sm:p-5">
          <div className="grid gap-6 sm:grid-cols-2">
            <div>
              <p className="text-xs text-muted-foreground">Auction closes</p>
              <LocalDateTime
                className="mt-1 block text-xl font-medium"
                timestamp={receivable.auctionClosesAtTimestamp}
              />
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
                <span
                  className="inline-flex items-center gap-1.5 rounded-md bg-muted px-2 py-1 text-xs"
                  key={bid.transaction}
                >
                  Encrypted bid {index + 1}
                  <TransactionLink hash={bid.transaction} />
                </span>
              ))}
            </div>
          ) : null}
        </div>
      ) : null}

      {isClosed ? (
        <div className="rounded-xl bg-muted/30 p-4 sm:p-5">
          <p className="text-xs text-muted-foreground">Winning offer</p>
          <p className="mt-1 text-2xl font-medium">
            <Money value={receivable.advance ?? 0} />
          </p>
          <DetailRows
            rows={[
              {
                label: "Financier",
                value: receivable.financier ? (
                  <ExplorerAddress value={receivable.financier} />
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
            className="flex min-w-0 flex-col gap-3 px-3 py-2.5 sm:flex-row sm:items-center sm:justify-between"
          >
            <div className="min-w-0">
              <p className="text-sm font-medium">{event.event}</p>
              <p className="mt-1 text-xs text-muted-foreground">{event.time}</p>
            </div>
            <div className="flex min-w-0 flex-wrap items-center gap-2 sm:shrink-0 sm:justify-end">
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
      .then((result) => {
        setStatus(result)
        setUnavailable(false)
      })
      .catch(() => setUnavailable(true))
  }, [receivable.id])

  return (
    <Card
      className="rounded-xl shadow-none"
      data-receivable-status={receivable.status}
    >
      <CardPanel className="p-0">
        <div className="flex flex-wrap items-center justify-between gap-3 p-4">
          <div>
            <PartnerMark partner="cleanverse" className="text-sm font-medium" />
            <p className="mt-1 text-xs text-muted-foreground">Identity checks and settlement asset</p>
          </div>
          <div className="flex items-center gap-3">
            <span className="text-xs font-medium text-muted-foreground">
              {!status && !unavailable ? "Checking" : status?.eligible ? "Eligible" : "Review needed"}
            </span>
            <a
              className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
              href={`${BIDNOX_BASE_SEPOLIA.explorer}/token/${BIDNOX_BASE_SEPOLIA.aUSDC}`}
              target="_blank"
              rel="noreferrer"
            >
              <SettlementToken />
              <ExternalLink className="size-3" />
            </a>
          </div>
        </div>
        <details className="group border-t text-xs">
          <summary className="flex cursor-pointer list-none items-center justify-between gap-3 px-4 py-3 text-muted-foreground [&::-webkit-details-marker]:hidden">
            <span>
              {status
                ? `${status.participants.filter((participant) => participant.verified).length} of ${status.participants.length} participants verified`
                : unavailable
                  ? "Verification status unavailable"
                  : "Checking participants…"}
            </span>
            <ChevronDown className="size-3.5 transition-transform group-open:rotate-180" />
          </summary>
          <div className="divide-y border-t">
            {status?.participants.map((participant) => (
              <div
                className="grid min-w-0 grid-cols-[minmax(0,1fr)_auto] items-center gap-2 px-4 py-3 sm:grid-cols-[5.5rem_minmax(0,1fr)_auto] sm:gap-3"
                key={participant.wallet}
              >
                <span className="font-medium">{participant.role}</span>
                <span className="col-span-2 row-start-2 min-w-0 sm:col-span-1 sm:col-start-2 sm:row-start-1"><ExplorerAddress value={participant.wallet} /></span>
                <span className="col-start-2 row-start-1 justify-self-end text-muted-foreground sm:col-start-3">{participant.verified ? "Verified" : "Review"}</span>
              </div>
            ))}
          </div>
        </details>
      </CardPanel>
    </Card>
  )
}

export function DocumentPanel({ receivable }: { receivable: Receivable }) {
  const { address } = useAccount()
  const [ipfs, setIpfs] = React.useState<{
    cid: string
    reference: string
    gatewayUrl?: string
  }>()

  React.useEffect(() => {
    if (!address) return
    fetch(
      `/api/pinata/document?receivableId=${receivable.id}&caller=${address}`,
      { cache: "no-store" }
    )
      .then((response) => (response.ok ? response.json() : Promise.reject()))
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
        <p className="text-xs text-muted-foreground">
          Onchain document fingerprint
        </p>
        <div className="mt-1">
          <CopyableAddress
            value={receivable.fingerprint}
            display={`${receivable.fingerprint.slice(0, 10)}…${receivable.fingerprint.slice(-8)}`}
          />
        </div>
        {ipfs ? (
          <div className="mt-4">
            <p className="text-xs text-muted-foreground">
              Invoice on IPFS
            </p>
            <a
              className="mt-1 inline-flex max-w-full items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground"
              href={
                ipfs.gatewayUrl || `https://gateway.pinata.cloud/ipfs/${ipfs.cid}`
              }
              target="_blank"
              rel="noreferrer"
              title={ipfs.reference}
            >
              <span className="truncate">
                {ipfs.gatewayUrl ||
                  `https://gateway.pinata.cloud/ipfs/${ipfs.cid}`}
              </span>
              <ExternalLink className="size-3 shrink-0" />
            </a>
          </div>
        ) : null}
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
          {
            label: "Started",
            value: (
              <LocalDateTime timestamp={receivable.auctionOpensAtTimestamp} />
            ),
          },
          {
            label: "Closes",
            value: (
              <LocalDateTime timestamp={receivable.auctionClosesAtTimestamp} />
            ),
          },
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
    <section className="border-t pt-5">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-sm font-medium">{funded ? "Funding complete" : "Ready to fund"}</h2>
        <span className="inline-flex items-center gap-1.5 text-xs text-muted-foreground"><PartnerMark compact partner="cleanverse" />CVA settlement</span>
      </div>
      {funded ? (
        <div className="mt-4">
          <p className="text-2xl font-medium"><Money value={receivable.advance ?? 0} /></p>
          <p className="mt-1 text-xs text-muted-foreground">Financed in <a className="inline-flex font-medium text-foreground hover:underline" href={`${BIDNOX_BASE_SEPOLIA.explorer}/token/${BIDNOX_BASE_SEPOLIA.aUSDC}`} target="_blank" rel="noreferrer"><SettlementToken /></a></p>
          <dl className="mt-4 divide-y border-y text-xs">
            <div className="flex items-center justify-between gap-4 py-3">
              <dt className="text-muted-foreground">Seller received</dt>
              <dd><ExplorerAddress value={receivable.seller} /></dd>
            </div>
            {receivable.fundingTransaction ? (
              <div className="flex items-center justify-between gap-4 py-3">
                <dt className="text-muted-foreground">Funding transaction</dt>
                <dd><TransactionLink hash={receivable.fundingTransaction} /></dd>
              </div>
            ) : null}
          </dl>
        </div>
      ) : (
        <p className="mt-3 text-xs text-muted-foreground">No funding transfer has been observed for this receivable yet.</p>
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
          {receivable.status === "Repaid"
            ? "Repaid in aUSDC"
            : "Awaiting aUSDC repayment"}
        </Badge>
      </div>
      <p className="text-2xl font-medium">
        <Money value={receivable.faceValue} />
      </p>
      <DetailRows
        rows={[
          {
            label: "Due",
            value: <LocalDateTime timestamp={receivable.dueDateTimestamp} />,
          },
          { label: "Paid by", value: <ExplorerAddress value={receivable.buyer} /> },
          { label: "Paid to", value: receivable.financier ? <ExplorerAddress value={receivable.financier} /> : "Winning financier" },
        ]}
      />
      {receivable.repaymentTransaction ? (
        <TransactionLink hash={receivable.repaymentTransaction} />
      ) : null}
    </section>
  )
}
