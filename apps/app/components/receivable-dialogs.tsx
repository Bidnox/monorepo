"use client"

import * as React from "react"
import { Check, LockKeyhole } from "lucide-react"

import type { Receivable } from "@/lib/demo-data"
import { Money, ReceivableStatus } from "@/components/receivable-primitives"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogPanel,
  DialogPopup,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  NumberField,
  NumberFieldGroup,
  NumberFieldInput,
} from "@/components/ui/number-field"
import { Progress } from "@/components/ui/progress"
import { toastManager } from "@/components/ui/toast"

function Terms({
  rows,
}: {
  rows: Array<{ label: string; value: React.ReactNode }>
}) {
  return (
    <dl className="divide-y rounded-lg border px-4">
      {rows.map((row) => (
        <div
          key={row.label}
          className="flex items-center justify-between gap-4 py-3 text-sm"
        >
          <dt className="text-muted-foreground">{row.label}</dt>
          <dd className="text-right font-medium">{row.value}</dd>
        </div>
      ))}
    </dl>
  )
}

function SubmissionProgress({
  steps,
  current,
}: {
  steps: string[]
  current: number
}) {
  return (
    <div className="space-y-3 rounded-lg bg-muted p-4">
      <Progress value={((current + 1) / steps.length) * 100} />
      <div className="space-y-2">
        {steps.map((step, index) => (
          <div
            key={step}
            className={`flex items-center gap-2 text-sm ${index > current ? "text-muted-foreground" : "text-foreground"}`}
          >
            <span
              className={`grid size-4 place-items-center rounded-full border ${
                index < current
                  ? "border-primary bg-primary text-primary-foreground"
                  : ""
              }`}
            >
              {index < current ? <Check className="size-2.5" /> : null}
            </span>
            {step}
          </div>
        ))}
      </div>
    </div>
  )
}

export function BuyerConfirmationDialog({
  receivable,
}: {
  receivable: Receivable
}) {
  const [open, setOpen] = React.useState(false)
  const [step, setStep] = React.useState<number | null>(null)
  const [confirmed, setConfirmed] = React.useState(false)
  const steps = [
    "Checking Cleanverse eligibility",
    "Signing confirmation",
    "Submitting transaction",
  ]

  async function confirm() {
    for (let index = 0; index < steps.length; index += 1) {
      setStep(index)
      await new Promise((resolve) => setTimeout(resolve, 450))
    }
    setConfirmed(true)
    setStep(null)
    setOpen(false)
    toastManager.add({
      title: "Receivable confirmed",
      description: `${receivable.reference} is ready for financing.`,
      type: "success",
    })
  }

  if (confirmed) {
    return <ReceivableStatus status="Buyer confirmed" />
  }

  return (
    <Dialog open={open} onOpenChange={(nextOpen) => setOpen(nextOpen)}>
      <DialogTrigger render={<Button />}>Confirm receivable</DialogTrigger>
      <DialogPopup>
        <DialogHeader>
          <DialogTitle>Confirm receivable</DialogTitle>
          <DialogDescription>
            Review the invoice terms before signing the EIP-712 confirmation.
          </DialogDescription>
        </DialogHeader>
        <DialogPanel className="space-y-5">
          <Terms
            rows={[
              { label: "Seller", value: receivable.seller },
              { label: "Invoice", value: receivable.reference },
              {
                label: "Amount",
                value: <Money value={receivable.faceValue} />,
              },
              { label: "Due", value: receivable.dueDate },
            ]}
          />
          {step !== null ? (
            <SubmissionProgress steps={steps} current={step} />
          ) : null}
        </DialogPanel>
        <DialogFooter>
          <Button
            variant="ghost"
            onClick={() => setOpen(false)}
            disabled={step !== null}
          >
            Cancel
          </Button>
          <Button onClick={confirm} loading={step !== null}>
            Confirm and sign
          </Button>
        </DialogFooter>
      </DialogPopup>
    </Dialog>
  )
}

export function PrivateBidDialog({ receivable }: { receivable: Receivable }) {
  const [open, setOpen] = React.useState(false)
  const [advance, setAdvance] = React.useState(920_000)
  const [step, setStep] = React.useState<number | null>(null)
  const [submitted, setSubmitted] = React.useState(false)
  const steps = [
    "Checking eligibility",
    "Encrypting bid",
    "Submitting transaction",
  ]

  async function submitBid() {
    for (let index = 0; index < steps.length; index += 1) {
      setStep(index)
      await new Promise((resolve) => setTimeout(resolve, 500))
    }
    setSubmitted(true)
    setStep(null)
    setOpen(false)
    toastManager.add({
      title: "Bid submitted privately",
      description: "Your offer is encrypted. No rank is disclosed.",
      type: "success",
    })
  }

  return (
    <Dialog open={open} onOpenChange={(nextOpen) => setOpen(nextOpen)}>
      <DialogTrigger render={<Button disabled={submitted} />}>
        {submitted ? "Bid submitted privately" : "Place bid"}
      </DialogTrigger>
      <DialogPopup>
        <DialogHeader>
          <DialogTitle>Place private bid</DialogTitle>
          <DialogDescription>
            Submit the amount you can advance today. Your offer stays sealed
            until close.
          </DialogDescription>
        </DialogHeader>
        <DialogPanel className="space-y-5">
          <div>
            <p className="text-xs text-muted-foreground">Invoice value</p>
            <p className="mt-1 text-2xl font-medium">
              <Money value={receivable.faceValue} />
            </p>
          </div>
          <NumberField
            value={advance}
            min={1}
            max={receivable.faceValue}
            onValueChange={(value) => setAdvance(value ?? 0)}
          >
            <label className="text-sm font-medium">Your advance</label>
            <NumberFieldGroup>
              <span className="flex items-center ps-3 text-sm text-muted-foreground">
                ₹
              </span>
              <NumberFieldInput className="text-left" />
            </NumberFieldGroup>
          </NumberField>
          <Terms
            rows={[
              { label: "You provide today", value: <Money value={advance} /> },
              {
                label: "You receive at maturity",
                value: <Money value={receivable.faceValue} />,
              },
              {
                label: "Gross difference",
                value: (
                  <Money value={Math.max(0, receivable.faceValue - advance)} />
                ),
              },
            ]}
          />
          <div className="flex gap-3 rounded-lg bg-muted p-4 text-sm">
            <LockKeyhole
              className="mt-0.5 size-4 shrink-0"
              aria-hidden="true"
            />
            <div>
              <p>Your offer is encrypted before submission.</p>
              <p className="mt-1 text-muted-foreground">
                Other lenders and the seller cannot see it until the auction
                closes.
              </p>
              <Badge variant="outline" className="mt-3">
                Powered by Inco
              </Badge>
            </div>
          </div>
          {step !== null ? (
            <SubmissionProgress steps={steps} current={step} />
          ) : null}
        </DialogPanel>
        <DialogFooter>
          <Button
            variant="ghost"
            onClick={() => setOpen(false)}
            disabled={step !== null}
          >
            Cancel
          </Button>
          <Button onClick={submitBid} loading={step !== null}>
            Submit private bid
          </Button>
        </DialogFooter>
      </DialogPopup>
    </Dialog>
  )
}
