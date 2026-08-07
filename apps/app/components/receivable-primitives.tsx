import { ExternalLink } from "lucide-react"

import type { ReceivableStatus as ReceivableStatusValue } from "@/lib/demo-data"
import { formatMoney } from "@/lib/demo-data"
import { cn } from "@/lib/utils"
import { Badge, type BadgeProps } from "@/components/ui/badge"

export function Money({
  value,
  className,
}: {
  value: number
  className?: string
}) {
  return (
    <span className={cn("tabular-nums", className)}>{formatMoney(value)}</span>
  )
}

export function Address({
  value,
  className,
}: {
  value: string
  className?: string
}) {
  return <span className={cn("font-mono text-xs", className)}>{value}</span>
}

export function CleanverseStatus({ verified = true }: { verified?: boolean }) {
  return (
    <Badge variant={verified ? "success" : "warning"}>
      {verified ? "Verified" : "Verification required"}
    </Badge>
  )
}

const STATUS_VARIANTS: Record<ReceivableStatusValue, BadgeProps["variant"]> = {
  Draft: "secondary",
  "Awaiting buyer": "warning",
  "Buyer confirmed": "info",
  "Auction open": "success",
  "Auction closed": "secondary",
  Funded: "success",
  Repaid: "outline",
  Overdue: "error",
}

export function ReceivableStatus({
  status,
}: {
  status: ReceivableStatusValue
}) {
  return <Badge variant={STATUS_VARIANTS[status]}>{status}</Badge>
}

export function TransactionLink({ hash }: { hash: string }) {
  if (hash === "—") return <span className="text-muted-foreground">—</span>

  return (
    <a
      href={`https://sepolia.basescan.org/tx/${hash.replace("…", "")}`}
      target="_blank"
      rel="noreferrer"
      className="inline-flex items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground"
    >
      {hash}
      <ExternalLink className="size-3" aria-hidden="true" />
    </a>
  )
}
