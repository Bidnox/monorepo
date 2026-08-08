"use client"

import * as React from "react"
import { Check, FileText, ShieldCheck } from "lucide-react"

import {
  CLOSED_EVIDENCE_EVENTS,
  EVIDENCE_EVENTS,
  type EvidenceEvent,
  type Receivable,
} from "@/lib/demo-data"
import {
  CompanyIdentity,
  CopyableAddress,
  FinancierIdentity,
  Money,
  SettlementToken,
  SourceBadge,
  TransactionLink,
} from "@/components/receivable-primitives"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardHeader, CardPanel, CardTitle } from "@/components/ui/card"
import {
  Empty,
  EmptyContent,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Separator } from "@/components/ui/separator"
import { toastManager } from "@/components/ui/toast"

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
            <EmptyContent>
              <Button size="sm">Open auction</Button>
            </EmptyContent>
          </Empty>
        </div>
      ) : null}

      {isActive ? (
        <div className="border-y py-5">
          <div className="grid gap-6 sm:grid-cols-3">
            <div>
              <p className="text-xs text-muted-foreground">Auction closes in</p>
              <p className="mt-1 text-xl font-medium tabular-nums">01:42:18</p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Private bids</p>
              <p className="mt-1 text-xl font-medium tabular-nums">
                {receivable.bidders ?? 0}
              </p>
            </div>
            <div>
              <p className="text-xs text-muted-foreground">Your bid</p>
              <p className="mt-1 text-xl font-medium">
                <Money value={900_000} />
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
            <Money value={receivable.advance ?? 920_000} />
          </p>
          <DetailRows
            rows={[
              { label: "Financier", value: <FinancierIdentity /> },
              {
                label: "Discount",
                value: (
                  <Money
                    value={
                      receivable.faceValue - (receivable.advance ?? 920_000)
                    }
                  />
                ),
              },
            ]}
          />
          <p className="text-sm text-muted-foreground">
            2 losing bids remain private.
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
  const events: EvidenceEvent[] = [
    "Funded",
    "Repaid",
    "Auction closed",
  ].includes(receivable.status)
    ? CLOSED_EVIDENCE_EVENTS
    : receivable.status === "Awaiting buyer"
      ? EVIDENCE_EVENTS.slice(0, 1)
      : receivable.status === "Buyer confirmed"
        ? EVIDENCE_EVENTS.slice(0, 2)
        : EVIDENCE_EVENTS

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
  return (
    <Card
      className="rounded-xl shadow-none"
      data-receivable-status={receivable.status}
    >
      <CardHeader className="p-5 pb-2">
        <div className="flex items-center justify-between gap-3">
          <CardTitle className="text-sm">Verification</CardTitle>
          <Badge variant="success">Eligible</Badge>
        </div>
      </CardHeader>
      <CardPanel className="px-5 pb-5">
        <p className="text-sm text-muted-foreground">
          Seller and buyer are verified for this transaction.
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
            display="0xf4a1…82de"
          />
        </div>
        <Button variant="secondary" size="sm" className="mt-4 w-full">
          View document
        </Button>
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
          { label: "Started", value: "08 Aug, 10:20" },
          { label: "Closes", value: "08 Aug, 11:00" },
          { label: "Bidders", value: receivable.bidders ?? 3 },
          { label: "Privacy", value: "Sealed bids" },
        ]}
      />
    </section>
  )
}

export function SettlementPanel({ receivable }: { receivable: Receivable }) {
  const [funded, setFunded] = React.useState(receivable.status === "Funded")
  const [loading, setLoading] = React.useState(false)

  if (!["Auction closed", "Funded"].includes(receivable.status)) return null

  async function fund() {
    setLoading(true)
    await new Promise((resolve) => setTimeout(resolve, 950))
    setFunded(true)
    setLoading(false)
    toastManager.add({ title: "Funding complete", type: "success" })
  }

  return (
    <section className="border-y py-5">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-sm font-medium">
          {funded ? "Funding complete" : "Ready to fund"}
        </h2>
        <Badge variant="success">Cleanverse preflight</Badge>
      </div>
      {funded ? (
        <div>
          <p className="text-2xl font-medium">
            <Money value={receivable.advance ?? 920_000} />
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            <SettlementToken /> sent to {receivable.seller}
          </p>
          <Button variant="secondary" size="sm" className="mt-4">
            View transaction
          </Button>
        </div>
      ) : (
        <>
          <div className="grid gap-2 text-sm sm:grid-cols-2">
            {[
              { key: "seller", content: "Seller eligible" },
              { key: "winner", content: "Winner eligible" },
              {
                key: "asset",
                content: (
                  <span className="inline-flex items-center gap-1">
                    Settlement asset: <SettlementToken />
                  </span>
                ),
              },
              { key: "buyer", content: "Buyer confirmed" },
            ].map((check) => (
              <div key={check.key} className="flex items-center gap-2">
                <Check className="size-3.5 text-success" aria-hidden="true" />
                {check.content}
              </div>
            ))}
          </div>
          <Button className="mt-5" loading={loading} onClick={fund}>
            Fund <Money value={receivable.advance ?? 920_000} />
          </Button>
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
    </section>
  )
}
