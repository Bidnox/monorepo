import Link from "next/link"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/page-header"
import { ReceivablesTabs } from "@/components/receivables-table"
import { Button } from "@/components/ui/button"
import { getReceivables } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ReceivablesPage() {
  const receivables = await getReceivables()
  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <PageHeader
          title="Receivables"
          description="Invoices financed privately and settled in aUSDC."
        />
        <Button render={<Link href="/receivables/new" />}>
          <Plus />
          New receivable
        </Button>
      </div>
      <section>
        <ReceivablesTabs receivables={receivables} />
      </section>
    </div>
  )
}
