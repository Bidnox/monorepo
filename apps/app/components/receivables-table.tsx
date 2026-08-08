"use client"

import { useRouter } from "next/navigation"
import { ChevronRight } from "lucide-react"

import type { Receivable } from "@/lib/bidnox"
import {
  CompanyIdentity,
  Money,
  ReceivableStatus,
} from "@/components/receivable-primitives"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { Tabs, TabsList, TabsPanel, TabsTab } from "@/components/ui/tabs"

function Rows({
  receivables,
  compact = false,
}: {
  receivables: Receivable[]
  compact?: boolean
}) {
  const router = useRouter()

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>{compact ? "Invoice" : "Reference"}</TableHead>
          {!compact ? <TableHead>Buyer</TableHead> : null}
          <TableHead>Face value</TableHead>
          {!compact ? <TableHead>Advance</TableHead> : null}
          {!compact ? <TableHead>Due</TableHead> : null}
          <TableHead>Status</TableHead>
          <TableHead className="hidden w-8 md:table-cell">
            <span className="sr-only">Open</span>
          </TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {receivables.map((receivable) => (
          <TableRow
            key={receivable.id}
            tabIndex={0}
            role="link"
            aria-label={`Open ${receivable.reference}`}
            className="group cursor-pointer focus-visible:bg-muted focus-visible:outline-2 focus-visible:outline-ring"
            onClick={() => router.push(`/receivables/${receivable.id}`)}
            onKeyDown={(event) => {
              if (event.key === "Enter" || event.key === " ") {
                event.preventDefault()
                router.push(`/receivables/${receivable.id}`)
              }
            }}
          >
            <TableCell className="font-medium">
              {receivable.reference}
            </TableCell>
            {!compact ? <TableCell>
              <CompanyIdentity name={receivable.buyer} />
            </TableCell> : null}
            <TableCell>
              <Money value={receivable.faceValue} />
            </TableCell>
            {!compact ? <TableCell>
              {receivable.advance ? (
                <Money value={receivable.advance} />
              ) : (
                <span className="text-muted-foreground">—</span>
              )}
            </TableCell> : null}
            {!compact ? <TableCell>{receivable.dueShort}</TableCell> : null}
            <TableCell>
              <ReceivableStatus status={receivable.status} />
            </TableCell>
            <TableCell className="hidden md:table-cell">
              <ChevronRight className="size-4 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  )
}

export function ReceivablesTable({
  receivables,
  compact = false,
}: {
  receivables: Receivable[]
  compact?: boolean
}) {
  return <Rows receivables={receivables} compact={compact} />
}

export function ReceivablesTabs({
  receivables,
}: {
  receivables: Receivable[]
}) {
  const filters = [
    { value: "all", label: "All", items: receivables },
    {
      value: "active",
      label: "Active",
      items: receivables.filter((item) =>
        [
          "Awaiting buyer",
          "Buyer confirmed",
          "Auction open",
          "Auction closed",
        ].includes(item.status)
      ),
    },
    {
      value: "funded",
      label: "Funded",
      items: receivables.filter((item) => item.status === "Funded"),
    },
    {
      value: "completed",
      label: "Completed",
      items: receivables.filter((item) =>
        ["Repaid", "Overdue"].includes(item.status)
      ),
    },
  ]

  return (
    <Tabs defaultValue="all" className="gap-5">
      <TabsList variant="underline">
        {filters.map((filter) => (
          <TabsTab key={filter.value} value={filter.value}>
            {filter.label}
          </TabsTab>
        ))}
      </TabsList>
      {filters.map((filter) => (
        <TabsPanel key={filter.value} value={filter.value}>
          <Rows receivables={filter.items} />
        </TabsPanel>
      ))}
    </Tabs>
  )
}
