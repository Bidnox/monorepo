import { notFound } from "next/navigation"

import { PageHeader } from "@/components/page-header"
import {
  BuyerConfirmationDialog,
  PrivateBidDialog,
} from "@/components/receivable-dialogs"
import {
  AuctionDetails,
  AuctionPanel,
  CompliancePanel,
  DocumentPanel,
  EvidenceTimeline,
  ReceivableSummary,
  RepaymentPanel,
  SettlementPanel,
} from "@/components/receivable-panels"
import { Money, ReceivableStatus } from "@/components/receivable-primitives"
import { Button } from "@/components/ui/button"
import { getReceivable, RECEIVABLES } from "@/lib/demo-data"

export function generateStaticParams() {
  return RECEIVABLES.map((receivable) => ({ id: receivable.id }))
}

export default async function ReceivableDetailPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const receivable = getReceivable(id)

  if (!receivable) notFound()

  const action =
    receivable.status === "Awaiting buyer" ? (
      <BuyerConfirmationDialog receivable={receivable} />
    ) : receivable.status === "Auction open" ? (
      <PrivateBidDialog receivable={receivable} />
    ) : receivable.status === "Buyer confirmed" ? (
      <Button>Open auction</Button>
    ) : undefined

  return (
    <div className="space-y-9">
      <PageHeader
        eyebrow={receivable.buyer}
        title={receivable.reference}
        description={`${receivable.seller} · ${receivable.dueDate}`}
        actions={action}
      />

      <div className="flex flex-wrap items-center gap-3 border-y py-4">
        <ReceivableStatus status={receivable.status} />
        <span className="text-sm text-muted-foreground">Face value</span>
        <Money value={receivable.faceValue} className="text-sm font-medium" />
        <span className="text-muted-foreground">·</span>
        <span className="text-sm text-muted-foreground">Settlement aUSDC</span>
      </div>

      <div className="grid gap-10 lg:grid-cols-[minmax(0,1.75fr)_minmax(18rem,0.85fr)]">
        <div className="min-w-0 space-y-10">
          <ReceivableSummary receivable={receivable} />
          <AuctionPanel receivable={receivable} />
          <SettlementPanel receivable={receivable} />
          <RepaymentPanel receivable={receivable} />
          <EvidenceTimeline receivable={receivable} />
        </div>
        <aside className="space-y-5">
          <CompliancePanel receivable={receivable} />
          <DocumentPanel receivable={receivable} />
          <AuctionDetails receivable={receivable} />
        </aside>
      </div>
    </div>
  )
}
