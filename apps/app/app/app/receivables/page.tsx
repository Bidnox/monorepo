import Link from "next/link"
import { Plus } from "lucide-react"

import { PageHeader } from "@/components/page-header"
import { ReceivablesTabs } from "@/components/receivables-table"
import { Button } from "@/components/ui/button"
import { RECEIVABLES } from "@/lib/demo-data"

export default function ReceivablesPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Receivables"
        description="Manage invoices submitted for financing."
        actions={
          <Button render={<Link href="/app/receivables/new" />}>
            <Plus />
            New receivable
          </Button>
        }
      />
      <ReceivablesTabs receivables={RECEIVABLES} />
    </div>
  )
}
