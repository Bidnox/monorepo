"use client"

import * as React from "react"
import { Check, FileText, LockKeyhole, ShieldCheck } from "lucide-react"

import type { EvidenceEvent, Receivable } from "@/lib/bidnox"
import {
  CompanyIdentity,
  CopyableAddress,
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
    <section className="flex items-start gap-3 rounded-xl border border-success/20 bg-success/5 p-4">
      <div className="grid size-9 shrink-0 place-items-center rounded-full bg-success/10 text-success-foreground">
        <LockKeyhole className="size-4" aria-hidden="true" />
      </div>
      <div>
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-sm font-medium">Privacy is on by default</h2>
          <Badge variant="success">Powered by Inco</Badge>
        </div>
        <p className="mt-1 text-xs leading-5 text-muted-foreground">
          Bids are encrypted in the browser and compared privately. Only the winning offer is revealed; losing bids stay hidden. aUSDC settlement remains publicly verifiable.
        </p>
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
          { label: "Due date", value: receivable.dueDate },
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
          <div className="grid gap-6 sm:grid-cols-3">
            <div>
              <p className="text-xs text-muted-foreground">Auction closes</p>
              <p className="mt-1 text-xl font-medium tabular-nums">
                {receivable.auctionClosesAt ?? "—"}
              </p>
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
      <ol className="relative ms-2 border-s">
        {events.map((event) => (
          <li
            key={`${event.event}-${event.time}`}
            className="relative ms-6 pb-7 last:pb-0"
          >
            <span className="absolute top-1.5 -left-[1.69rem] size-2 rounded-full bg-foreground ring-4 ring-background" />
            <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
              <div>
                <p className="text-sm font-medium">{event.event}</p>
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {event.time}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <SourceBadge source={event.source} />
                {event.transaction ? (
                  <TransactionLink hash={event.transaction} />
                ) : null}
              </div>
            </div>
          </li>
        ))}
      </ol>
    </section>
  )
}

export function CompliancePanel({ receivable }: { receivable: Receivable }) {
  const [eligible, setEligible] = React.useState<boolean>()

  React.useEffect(() => {
    fetch(`/api/cleanverse/status?receivableId=${receivable.id}`, {
      cache: "no-store",
    })
      .then((response) => (response.ok ? response.json() : Promise.reject()))
      .then((result) => setEligible(result.eligible === true))
      .catch(() => setEligible(false))
  }, [receivable.id])

  return (
    <Card
      className="rounded-xl shadow-none"
      data-receivable-status={receivable.status}
    >
      <CardHeader className="p-5 pb-2">
        <div className="flex items-center justify-between gap-3">
          <CardTitle className="text-sm">Verification</CardTitle>
          <Badge variant={eligible === undefined ? "secondary" : eligible ? "success" : "warning"}>
            {eligible === undefined ? "Checking" : eligible ? "Eligible" : "Review required"}
          </Badge>
        </div>
      </CardHeader>
      <CardPanel className="px-5 pb-5">
        <p className="text-sm text-muted-foreground">
          {eligible === undefined
            ? "Checking current Cleanverse A-Pass and asset eligibility."
            : eligible
              ? "Seller and buyer currently pass the Cleanverse sandbox check."
              : "One or more participant checks are unavailable or not eligible."}
        </p>
        <div className="mt-4 flex items-center gap-2 text-sm">
          <Check className="size-4 text-success" aria-hidden="true" />
          Settlement in <SettlementToken />
        </div>
      </CardPanel>
    </Card>
  )
}

export function DocumentPanel({ receivable }: { receivable: Receivable }) {
  return (
    <Card className="rounded-xl shadow-none">
      <CardHeader className="p-5 pb-3">
        <CardTitle className="text-sm">Invoice document</CardTitle>
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
        <p className="text-xs text-muted-foreground">Fingerprint</p>
        <div className="mt-1">
          <CopyableAddress
            value={receivable.fingerprint}
            display={`${receivable.fingerprint.slice(0, 10)}…${receivable.fingerprint.slice(-8)}`}
          />
        </div>
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
          { label: "Started", value: receivable.auctionOpensAt ?? "—" },
          { label: "Closes", value: receivable.auctionClosesAt ?? "—" },
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
          <Badge variant="outline">Onchain settlement</Badge>
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
          {receivable.status === "Repaid" ? "Repaid" : "Awaiting repayment"}
        </Badge>
      </div>
      <p className="text-2xl font-medium">
        <Money value={receivable.faceValue} />
      </p>
      <DetailRows
        rows={[
          { label: "Due", value: receivable.dueDate },
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
