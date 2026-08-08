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
import { Money, ReceivableStatus } from "@/components/receivable-primitives"
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
    <div className="space-y-7">
      <Link
        href="/receivables"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        Receivables
      </Link>
      <PageHeader
        title={receivable.reference}
        description={`${receivable.seller} → ${receivable.buyer}`}
      />

      <div className="grid grid-cols-2 divide-x rounded-xl border sm:grid-cols-3">
        <div className="p-4">
          <p className="mb-2 text-xs text-muted-foreground">Status</p>
          <ReceivableStatus status={receivable.status} />
        </div>
        <div className="p-4">
          <p className="text-xs text-muted-foreground">Face value</p>
          <Money
            value={receivable.faceValue}
            className="mt-1 block font-medium"
          />
        </div>
        <div className="col-span-2 border-t p-4 sm:col-span-1 sm:border-t-0">
          <p className="text-xs text-muted-foreground">Due date</p>
          <p className="mt-1 font-medium">{receivable.dueDate}</p>
        </div>
      </div>

      <div className="grid gap-8 lg:grid-cols-[minmax(0,1.7fr)_minmax(17rem,0.8fr)]">
        <div className="min-w-0 space-y-8">
          <AuctionPanel receivable={receivable} />
          <SettlementPanel receivable={receivable} />
          <RepaymentPanel receivable={receivable} />
          <details className="group border-t pt-5">
            <summary className="flex cursor-pointer list-none items-center justify-between text-sm font-medium [&::-webkit-details-marker]:hidden">
              Activity & evidence
              <ChevronDown className="size-4 text-muted-foreground transition-transform group-open:rotate-180" />
            </summary>
            <div className="pt-6">
              <EvidenceTimeline receivable={receivable} showHeading={false} />
            </div>
          </details>
        </div>
        <aside className="space-y-5">
          <DocumentPanel receivable={receivable} />
          <CompliancePanel receivable={receivable} />
        </aside>
      </div>
    </div>
  )
}
