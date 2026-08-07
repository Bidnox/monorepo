"use client"

import { ACTIVITY } from "@/lib/demo-data"
import {
  SourceBadge,
  TransactionLink,
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

const FILTERS = ["All", "Cleanverse", "Bidnox", "Inco", "Payments"] as const

export function ActivityTable() {
  return (
    <Tabs defaultValue="All" className="gap-5">
      <TabsList variant="underline" className="max-w-full overflow-x-auto">
        {FILTERS.map((filter) => (
          <TabsTab key={filter} value={filter}>
            {filter}
          </TabsTab>
        ))}
      </TabsList>
      {FILTERS.map((filter) => {
        const rows =
          filter === "All"
            ? ACTIVITY
            : ACTIVITY.filter((row) => row.source === filter)
        return (
          <TabsPanel key={filter} value={filter}>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Event</TableHead>
                  <TableHead>Receivable</TableHead>
                  <TableHead>Source</TableHead>
                  <TableHead>Time</TableHead>
                  <TableHead>Transaction</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={`${row.event}-${row.receivable}`}>
                    <TableCell className="font-medium">{row.event}</TableCell>
                    <TableCell>{row.receivable}</TableCell>
                    <TableCell>
                      <SourceBadge source={row.source} />
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {row.time}
                    </TableCell>
                    <TableCell>
                      <TransactionLink hash={row.transaction} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TabsPanel>
        )
      })}
    </Tabs>
  )
}
