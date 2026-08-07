import { CreateReceivableForm } from "@/components/create-receivable-form"
import { PageHeader } from "@/components/page-header"

export default function NewReceivablePage() {
  return (
    <div className="space-y-10">
      <PageHeader
        title="Create receivable"
        description="Add an invoice and send it to the buyer for confirmation."
      />
      <CreateReceivableForm />
    </div>
  )
}
