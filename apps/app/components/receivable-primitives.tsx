"use client"

import * as React from "react"
import Image from "next/image"
import {
  Blocks,
  Building2,
  Check,
  Copy,
  ExternalLink,
  LockKeyhole,
  ShieldCheck,
  Sparkles,
} from "lucide-react"

import type { ReceivableStatus as ReceivableStatusValue } from "@/lib/demo-data"
import { formatMoney } from "@/lib/demo-data"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge, type BadgeProps } from "@/components/ui/badge"
import { toastManager } from "@/components/ui/toast"
import { cn } from "@/lib/utils"

export const CLEANVERSE_AUSDC = {
  name: "Access USDC",
  symbol: "aUSDC",
  address: "0xaC0893567D43C3E7e6e35a72803df05416C1f20D",
  chainId: 84532,
  image: "/tokens/cleanverse-ausdc.svg",
} as const

export function SettlementToken({
  showName = false,
  className,
}: {
  showName?: boolean
  className?: string
}) {
  return (
    <span
      className={cn("inline-flex items-center gap-1.5", className)}
      title={`${CLEANVERSE_AUSDC.name} on Base Sepolia`}
    >
      <Image
        src={CLEANVERSE_AUSDC.image}
        width={24}
        height={24}
        alt=""
        className="size-5 shrink-0 rounded-full"
      />
      <span>{showName ? CLEANVERSE_AUSDC.name : CLEANVERSE_AUSDC.symbol}</span>
    </span>
  )
}

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

export function CopyableAddress({
  value,
  display = value,
}: {
  value: string
  display?: string
}) {
  const [copied, setCopied] = React.useState(false)

  async function copy() {
    await navigator.clipboard.writeText(value)
    setCopied(true)
    toastManager.add({ title: "Copied to clipboard", type: "success" })
    window.setTimeout(() => setCopied(false), 1200)
  }

  return (
    <button
      type="button"
      onClick={copy}
      className="inline-flex items-center gap-1.5 rounded-md font-mono text-xs text-muted-foreground hover:text-foreground focus-visible:outline-2 focus-visible:outline-ring"
    >
      {display}
      {copied ? <Check className="size-3" /> : <Copy className="size-3" />}
      <span className="sr-only">Copy address</span>
    </button>
  )
}

export function CompanyIdentity({ name }: { name: string }) {
  return (
    <span className="inline-flex items-center gap-2">
      <span className="grid size-6 shrink-0 place-items-center rounded-md bg-muted text-muted-foreground">
        <Building2 className="size-3.5" aria-hidden="true" />
      </span>
      <span>{name}</span>
    </span>
  )
}

export function FinancierIdentity() {
  return (
    <span className="inline-flex items-center gap-2">
      <Avatar className="size-6 border">
        <AvatarImage src="/avatars/lender.svg" alt="" draggable={false} />
        <AvatarFallback>LF</AvatarFallback>
      </Avatar>
      <Address value="0x817…924" />
    </span>
  )
}

const SOURCE_ICONS = {
  Bidnox: Sparkles,
  Inco: LockKeyhole,
  Cleanverse: ShieldCheck,
  Blockchain: Blocks,
  Payments: Blocks,
} as const

export function SourceBadge({ source }: { source: keyof typeof SOURCE_ICONS }) {
  const Icon = SOURCE_ICONS[source]
  return (
    <Badge variant="secondary">
      <Icon aria-hidden="true" />
      {source}
    </Badge>
  )
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
