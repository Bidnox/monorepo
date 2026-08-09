import Link from "next/link"
import { notFound } from "next/navigation"
import { ArrowLeft, ChevronDown } from "lucide-react"

import { PageHeader } from "@/components/page-header"
import {
  AuctionPanel,
  CompliancePanel,
  DocumentPanel,
  EvidenceTimeline,
  RepaymentPanel,
  SettlementPanel,
} from "@/components/receivable-panels"
import { LocalDateTime, Money, ReceivableStatus } from "@/components/receivable-primitives"
import { ReceivableActions } from "@/components/transaction-actions"
import { getReceivableById } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ReceivableDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const receivable = await getReceivableById(id)

  if (!receivable) notFound()
  return (
    <div className="space-y-5">
      <Link
        href="/receivables"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        Receivables
      </Link>
      <PageHeader
        title={receivable.reference}
        description="Confidential receivable financing on Base Sepolia"
      />

      <div className="grid grid-cols-2 divide-x overflow-hidden rounded-xl border bg-card sm:grid-cols-3">
        <div className="p-3.5 sm:p-4">
          <p className="mb-1.5 text-xs text-muted-foreground">Status</p>
          <ReceivableStatus status={receivable.status} />
        </div>
        <div className="p-3.5 sm:p-4">
          <p className="text-xs text-muted-foreground">Face value</p>
          <Money
            value={receivable.faceValue}
            className="mt-1 block font-medium"
          />
        </div>
        <div className="col-span-2 border-t p-3.5 sm:col-span-1 sm:border-t-0 sm:p-4">
          <p className="text-xs text-muted-foreground">Due</p>
          <LocalDateTime className="mt-1 block text-sm font-medium" timestamp={receivable.dueDateTimestamp} />
        </div>
      </div>

      <ReceivableActions receivable={receivable} />
      <CompliancePanel receivable={receivable} />

      <div className="grid gap-6 lg:grid-cols-[minmax(0,1.5fr)_minmax(18rem,0.75fr)]">
        <div className="min-w-0 space-y-6 rounded-xl border bg-card p-4 sm:p-5">
          <AuctionPanel receivable={receivable} />
          <SettlementPanel receivable={receivable} />
          <RepaymentPanel receivable={receivable} />
        </div>
        <aside className="space-y-4">
          <DocumentPanel receivable={receivable} />
          <details className="group rounded-xl border bg-card p-4">
            <summary className="flex cursor-pointer list-none items-center justify-between text-sm font-medium [&::-webkit-details-marker]:hidden">
              On-chain evidence
              <ChevronDown className="size-4 text-muted-foreground transition-transform group-open:rotate-180" />
            </summary>
            <div className="pt-4">
              <EvidenceTimeline receivable={receivable} showHeading={false} />
            </div>
          </details>
        </aside>
      </div>
    </div>
  )
}
