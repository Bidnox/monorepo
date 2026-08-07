"use client"

import * as React from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { CalendarDays, Check, FileText, Upload } from "lucide-react"

import { CleanverseStatus } from "@/components/receivable-primitives"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  NumberField,
  NumberFieldGroup,
  NumberFieldInput,
} from "@/components/ui/number-field"
import { Popover, PopoverPopup, PopoverTrigger } from "@/components/ui/popover"
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import { toastManager } from "@/components/ui/toast"

function formatDate(date: Date) {
  return new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(date)
}

function DateField({
  label,
  value,
  onChange,
}: {
  label: string
  value: Date
  onChange: (date: Date) => void
}) {
  return (
    <Field>
      <FieldLabel>{label}</FieldLabel>
      <Popover>
        <PopoverTrigger
          render={
            <Button
              variant="outline"
              className="w-full justify-start font-normal"
            />
          }
        >
          <CalendarDays />
          {formatDate(value)}
        </PopoverTrigger>
        <PopoverPopup align="start">
          <Calendar
            mode="single"
            selected={value}
            onSelect={(date) => {
              if (date) onChange(date)
            }}
          />
        </PopoverPopup>
      </Popover>
    </Field>
  )
}

export function CreateReceivableForm() {
  const router = useRouter()
  const [issueDate, setIssueDate] = React.useState(new Date(2026, 7, 8))
  const [dueDate, setDueDate] = React.useState(new Date(2026, 8, 30))
  const [buyerWallet, setBuyerWallet] = React.useState(
    "0x817c2a5dfA82b1B37129E38A4c52924"
  )
  const [fileName, setFileName] = React.useState("invoice-041.pdf")
  const [step, setStep] = React.useState<number | null>(null)
  const steps = [
    "Checking Cleanverse eligibility",
    "Creating fingerprint",
    "Submitting transaction",
  ]
  const walletChecked = buyerWallet.length > 12

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    for (let index = 0; index < steps.length; index += 1) {
      setStep(index)
      await new Promise((resolve) => setTimeout(resolve, 550))
    }
    toastManager.add({
      title: "Receivable created",
      description: "INV-2026-041 is ready for buyer confirmation.",
      type: "success",
    })
    router.push("/app/receivables/inv-2026-041")
  }

  return (
    <form onSubmit={submit} className="mx-auto max-w-3xl">
      <section className="py-8 first:pt-0">
        <div className="mb-6">
          <h2 className="text-base font-medium">Invoice</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Core terms from the seller&apos;s invoice.
          </p>
        </div>
        <div className="grid gap-5 sm:grid-cols-2">
          <Field>
            <FieldLabel>Invoice reference</FieldLabel>
            <Input defaultValue="INV-2026-041" required />
          </Field>
          <NumberField defaultValue={1_000_000} min={1}>
            <label className="text-sm font-medium">Face value</label>
            <NumberFieldGroup>
              <span className="flex items-center ps-3 text-sm text-muted-foreground">
                $
              </span>
              <NumberFieldInput className="text-left" />
            </NumberFieldGroup>
          </NumberField>
          <DateField
            label="Issue date"
            value={issueDate}
            onChange={setIssueDate}
          />
          <DateField label="Due date" value={dueDate} onChange={setDueDate} />
        </div>
      </section>

      <Separator />

      <section className="py-8">
        <div className="mb-6">
          <h2 className="text-base font-medium">Buyer</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            The buyer confirms these terms from their wallet.
          </p>
        </div>
        <div className="grid gap-5 sm:grid-cols-2">
          <Field>
            <FieldLabel>Buyer wallet</FieldLabel>
            <Input
              value={buyerWallet}
              onChange={(event) => setBuyerWallet(event.target.value)}
              required
            />
          </Field>
          <Field>
            <FieldLabel>Buyer name</FieldLabel>
            <Input defaultValue="Acme Retail" required />
            <FieldDescription>
              Application metadata, not an identity attestation.
            </FieldDescription>
          </Field>
        </div>
        <div className="mt-5 flex items-center justify-between border-y py-3 text-sm">
          <div>
            <p className="font-medium">Cleanverse</p>
            <p className="text-xs text-muted-foreground">
              Wallet eligibility · demo check
            </p>
          </div>
          <CleanverseStatus verified={walletChecked} />
        </div>
      </section>

      <Separator />

      <section className="py-8">
        <div className="mb-6">
          <h2 className="text-base font-medium">Invoice document</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            The source file remains private.
          </p>
        </div>
        <label className="flex cursor-pointer items-center justify-between gap-4 rounded-xl border border-dashed p-5 hover:bg-muted/50">
          <span className="flex min-w-0 items-center gap-3">
            <span className="grid size-10 shrink-0 place-items-center rounded-lg bg-muted">
              {fileName ? (
                <FileText className="size-4" />
              ) : (
                <Upload className="size-4" />
              )}
            </span>
            <span className="min-w-0">
              <span className="block truncate text-sm font-medium">
                {fileName || "Choose invoice PDF"}
              </span>
              <span className="block text-xs text-muted-foreground">
                {fileName ? "184 KB" : "PDF up to 10 MB"}
              </span>
            </span>
          </span>
          <Badge variant="secondary">Choose file</Badge>
          <input
            type="file"
            accept="application/pdf"
            className="sr-only"
            onChange={(event) =>
              setFileName(event.target.files?.[0]?.name ?? "")
            }
          />
        </label>
        {fileName ? (
          <div className="mt-5 border-y py-3">
            <div className="flex items-center justify-between gap-4 text-sm">
              <span className="text-muted-foreground">
                Document fingerprint
              </span>
              <span className="font-mono text-xs">0xf4a1…82de</span>
            </div>
            <p className="mt-2 text-xs text-muted-foreground">
              The document remains private. Only its cryptographic fingerprint
              is recorded onchain.
            </p>
          </div>
        ) : null}
      </section>

      {step !== null ? (
        <div className="mb-5 rounded-xl bg-muted p-5">
          <Progress value={((step + 1) / steps.length) * 100} />
          <div className="mt-4 space-y-2">
            {steps.map((label, index) => (
              <div key={label} className="flex items-center gap-2 text-sm">
                <span
                  className={`grid size-4 place-items-center rounded-full border ${index < step ? "bg-primary text-primary-foreground" : ""}`}
                >
                  {index < step ? <Check className="size-2.5" /> : null}
                </span>
                <span className={index > step ? "text-muted-foreground" : ""}>
                  {label}
                </span>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      <div className="sticky bottom-0 -mx-4 flex items-center justify-end gap-2 border-t bg-background/95 px-4 py-4 backdrop-blur sm:mx-0 sm:px-0">
        <Button
          variant="ghost"
          disabled={step !== null}
          render={<Link href="/app/receivables" />}
        >
          Cancel
        </Button>
        <Button type="submit" loading={step !== null}>
          Create receivable
        </Button>
      </div>
    </form>
  )
}
