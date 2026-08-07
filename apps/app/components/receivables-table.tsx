"use client"

import { useRouter } from "next/navigation"

import type { Receivable } from "@/lib/demo-data"
import { Money, ReceivableStatus } from "@/components/receivable-primitives"
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
          <TableHead>Buyer</TableHead>
          <TableHead>Face value</TableHead>
          <TableHead>{compact ? "Best status" : "Advance"}</TableHead>
          <TableHead>{compact ? "Due date" : "Due"}</TableHead>
          <TableHead>Status</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {receivables.map((receivable) => (
          <TableRow
            key={receivable.id}
            tabIndex={0}
            role="link"
            aria-label={`Open ${receivable.reference}`}
            className="cursor-pointer focus-visible:bg-muted focus-visible:outline-2 focus-visible:outline-ring"
            onClick={() => router.push(`/app/receivables/${receivable.id}`)}
            onKeyDown={(event) => {
              if (event.key === "Enter" || event.key === " ") {
                event.preventDefault()
                router.push(`/app/receivables/${receivable.id}`)
              }
            }}
          >
            <TableCell className="font-medium">
              {receivable.reference}
            </TableCell>
            <TableCell>{receivable.buyer}</TableCell>
            <TableCell>
              <Money value={receivable.faceValue} />
            </TableCell>
            <TableCell>
              {compact ? (
                receivable.status === "Auction open" ? (
                  "Auction open"
                ) : (
                  receivable.status
                )
              ) : receivable.advance ? (
                <Money value={receivable.advance} />
              ) : (
                <span className="text-muted-foreground">—</span>
              )}
            </TableCell>
            <TableCell>{receivable.dueShort}</TableCell>
            <TableCell>
              <ReceivableStatus status={receivable.status} />
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
