import { PageHeader } from "@/components/page-header"
import { PrivacySummary } from "@/components/receivable-panels"
import { ReceivablesTable, ReceivablesTabs } from "@/components/receivables-table"
import { CreateReceivableForm } from "@/components/transaction-actions"
import { getReceivables } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ReceivablesPage() {
  const receivables = await getReceivables()
  const demoMode = process.env.NEXT_PUBLIC_DEMO_MODE === "true"
  return (
    <div className={demoMode ? "mx-auto max-w-4xl space-y-6" : "space-y-8"}>
      <PageHeader
        title={demoMode ? "Private financing demo" : "Receivables"}
        description={demoMode ? "Follow one real invoice from creation to repayment." : "Manage invoices submitted for financing."}
      />
      {demoMode ? <PrivacySummary /> : null}
      <CreateReceivableForm />
      <section>
        <div className="mb-3">
          <h2 className="text-sm font-medium">{demoMode ? "Continue a live demo" : "Receivables"}</h2>
          {demoMode ? <p className="mt-1 text-xs text-muted-foreground">Open a transaction already in progress, then connect the wallet required for its next step.</p> : null}
        </div>
        {demoMode ? <ReceivablesTable compact receivables={receivables} /> : <ReceivablesTabs receivables={receivables} />}
      </section>
    </div>
  )
}
