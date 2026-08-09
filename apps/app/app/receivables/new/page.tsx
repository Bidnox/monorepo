import Link from "next/link"
import { ArrowLeft } from "lucide-react"

import { CreateReceivableForm } from "@/components/transaction-actions"
import { PartnerMark } from "@/components/partner-mark"
import {
  Card,
  CardAction,
  CardHeader,
  CardPanel,
  CardTitle,
  CardDescription,
} from "@/components/ui/card"

export default function NewReceivablePage() {
  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <Link
        href="/receivables"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground"
      >
        <ArrowLeft className="size-4" />
        Receivables
      </Link>
      <Card className="rounded-xl shadow-none">
        <CardHeader className="border-b p-5 sm:p-6">
          <CardTitle className="text-lg">New receivable</CardTitle>
          <CardDescription>Upload the invoice and set the financing terms.</CardDescription>
          <CardAction className="flex items-center gap-3 text-xs text-muted-foreground">
            <span className="inline-flex items-center gap-1.5"><PartnerMark compact partner="cleanverse" />A-Pass required</span>
            <span className="h-3 w-px bg-border" aria-hidden="true" />
            <a className="hover:text-foreground hover:underline" href="/demo/sample-invoice.pdf" download>Sample PDF</a>
          </CardAction>
        </CardHeader>
        <CardPanel className="p-5 sm:p-6">
          <CreateReceivableForm />
        </CardPanel>
      </Card>
    </div>
  )
}
