import Link from "next/link"
import { ArrowLeft } from "lucide-react"

import { CreateReceivableForm } from "@/components/transaction-actions"
import { Card, CardHeader, CardPanel, CardTitle, CardDescription } from "@/components/ui/card"

export default function NewReceivablePage() {
  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <Link href="/receivables" className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="size-4" />
        Receivables
      </Link>
      <Card className="rounded-xl shadow-none">
        <CardHeader className="border-b p-5 sm:p-6">
          <CardTitle className="text-lg">New receivable</CardTitle>
          <CardDescription>Upload the invoice and set the financing terms. Cleanverse eligibility is checked before the on-chain write.</CardDescription>
        </CardHeader>
        <CardPanel className="p-5 sm:p-6">
          <CreateReceivableForm />
        </CardPanel>
      </Card>
    </div>
  )
}
