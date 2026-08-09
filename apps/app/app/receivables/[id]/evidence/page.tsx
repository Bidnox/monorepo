import Link from "next/link"
import { notFound } from "next/navigation"
import { ArrowLeft, Blocks } from "lucide-react"

import { PageHeader } from "@/components/page-header"
import { EvidenceTimeline } from "@/components/receivable-panels"
import { getReceivableById } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ReceivableEvidencePage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const receivable = await getReceivableById(id)

  if (!receivable) notFound()

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <Link
        href={`/receivables/${receivable.id}`}
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" aria-hidden="true" />
        {receivable.reference}
      </Link>
      <div className="flex items-start gap-3">
        <span className="mt-0.5 grid size-10 shrink-0 place-items-center rounded-xl bg-muted text-muted-foreground">
          <Blocks className="size-4" aria-hidden="true" />
        </span>
        <PageHeader
          title="On-chain evidence"
          description="A focused audit trail for this receivable on Base Sepolia."
        />
      </div>
      <div className="rounded-xl border bg-card p-4 sm:p-6">
        <EvidenceTimeline receivable={receivable} />
      </div>
    </div>
  )
}
