import { PageHeader } from "@/components/page-header"
import { ReceivablesTabs } from "@/components/receivables-table"
import { CreateReceivableForm } from "@/components/transaction-actions"
import { getReceivables } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ReceivablesPage() {
  const receivables = await getReceivables()
  return (
    <div className="space-y-8">
      <PageHeader
        title="Receivables"
        description="Manage invoices submitted for financing."
      />
      <CreateReceivableForm />
      <ReceivablesTabs receivables={receivables} />
    </div>
  )
}
