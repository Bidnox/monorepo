"use client"

import * as React from "react"
import Image from "next/image"
import {
  Blocks,
  Building2,
  CircleDot,
  Check,
  Copy,
  ExternalLink,
} from "lucide-react"

import type { ReceivableStatus as ReceivableStatusValue } from "@/lib/bidnox"
import { formatMoney } from "@/lib/bidnox"
import { Badge, type BadgeProps } from "@/components/ui/badge"
import { toastManager } from "@/components/ui/toast"
import { PartnerMark } from "@/components/partner-mark"
import { cn } from "@/lib/utils"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"

export const CLEANVERSE_AUSDC = {
  name: "Access USDC",
  symbol: "aUSDC",
  address: BIDNOX_BASE_SEPOLIA.aUSDC,
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
  return <span className={cn("break-all font-mono text-xs", className)}>{value}</span>
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
      className="inline-flex max-w-full min-w-0 items-center gap-1.5 break-all rounded-md text-left font-mono text-xs text-muted-foreground hover:text-foreground focus-visible:outline-2 focus-visible:outline-ring"
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
      {/^0x[0-9a-fA-F]{40}$/.test(name) ? <ExplorerAddress value={name} /> : <span>{name}</span>}
    </span>
  )
}

export function ExplorerAddress({
  value,
  display = `${value.slice(0, 8)}…${value.slice(-6)}`,
}: {
  value: string
  display?: string
}) {
  const [copied, setCopied] = React.useState(false)

  async function copy(event: React.MouseEvent<HTMLButtonElement>) {
    event.stopPropagation()
    await navigator.clipboard.writeText(value)
    setCopied(true)
    toastManager.add({ title: "Address copied", type: "success" })
    window.setTimeout(() => setCopied(false), 1200)
  }

  return (
    <span className="inline-flex min-w-0 max-w-full items-center gap-1.5">
      <a
        href={`${BIDNOX_BASE_SEPOLIA.explorer}/address/${value}`}
        target="_blank"
        rel="noreferrer"
        title={value}
        onClick={(event) => event.stopPropagation()}
        className="inline-flex min-w-0 items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground"
      >
        <span className="truncate">{display}</span>
        <ExternalLink className="size-3 shrink-0" aria-hidden="true" />
      </a>
      <button type="button" onClick={copy} className="shrink-0 text-muted-foreground hover:text-foreground" aria-label="Copy address">
        {copied ? <Check className="size-3" /> : <Copy className="size-3" />}
      </button>
    </span>
  )
}

const SOURCE_ICONS = {
  Bidnox: CircleDot,
  Blockchain: Blocks,
  Payments: Blocks,
} as const

export function SourceBadge({
  source,
}: {
  source: "Bidnox" | "Inco" | "Cleanverse" | "Blockchain" | "Payments"
}) {
  if (source === "Inco" || source === "Cleanverse") {
    return (
      <Badge variant="secondary">
        <PartnerMark partner={source === "Inco" ? "inco" : "cleanverse"} />
      </Badge>
    )
  }

  const Icon = SOURCE_ICONS[source]
  return (
    <Badge variant="secondary">
      <Icon aria-hidden="true" />
      {source}
    </Badge>
  )
}

export function CleanverseStatus({ verified }: { verified?: boolean }) {
  if (verified === undefined)
    return (
      <Badge variant="secondary">
        <PartnerMark compact partner="cleanverse" />
        A-Pass check
      </Badge>
    )
  return (
    <Badge variant={verified ? "success" : "warning"}>
      <PartnerMark compact partner="cleanverse" />
      {verified ? "Verified" : "Verification required"}
    </Badge>
  )
}

const STATUS_VARIANTS: Record<ReceivableStatusValue, BadgeProps["variant"]> = {
  "Awaiting buyer": "warning",
  "Buyer confirmed": "info",
  "Auction open": "success",
  "Auction closed": "secondary",
  Funded: "success",
  Repaid: "outline",
  Overdue: "error",
  Cancelled: "error",
}

export function ReceivableStatus({
  status,
}: {
  status: ReceivableStatusValue
}) {
  const label =
    status === "Auction closed" ? "Winner selected · awaiting funding" : status
  return <Badge variant={STATUS_VARIANTS[status]}>{label}</Badge>
}

export function TransactionLink({ hash }: { hash: string }) {
  if (hash === "—") return <span className="text-muted-foreground">—</span>

  return (
    <a
      href={`https://sepolia.basescan.org/tx/${hash}`}
      target="_blank"
      rel="noreferrer"
      className="inline-flex items-center gap-1 font-mono text-xs text-muted-foreground hover:text-foreground"
    >
      {hash.length > 18 ? `${hash.slice(0, 10)}…${hash.slice(-8)}` : hash}
      <ExternalLink className="size-3" aria-hidden="true" />
    </a>
  )
}

const subscribeToHydration = () => () => undefined

export function LocalDateTime({
  timestamp,
  className,
  compact = false,
}: {
  timestamp?: number
  className?: string
  compact?: boolean
}) {
  const hydrated = React.useSyncExternalStore(
    subscribeToHydration,
    () => true,
    () => false
  )
  const value = timestamp && hydrated
    ? compact
      ? `${new Intl.DateTimeFormat(undefined, {
          day: "2-digit",
          month: "short",
        }).format(new Date(timestamp * 1000))} · ${new Intl.DateTimeFormat(
          undefined,
          { hour: "2-digit", minute: "2-digit" }
        ).format(new Date(timestamp * 1000))}`
      : new Intl.DateTimeFormat(undefined, {
          day: "2-digit",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
          timeZoneName: "short",
        }).format(new Date(timestamp * 1000))
    : undefined

  return (
    <time
      className={cn("tabular-nums", className)}
      dateTime={
        timestamp ? new Date(timestamp * 1000).toISOString() : undefined
      }
    >
      {value ?? (timestamp ? "Local time" : "—")}
    </time>
  )
}
