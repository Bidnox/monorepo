"use client"

import type { ActivityRow } from "@/lib/bidnox"
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

export function ActivityTable({ activity }: { activity: ActivityRow[] }) {
  const filters = ["All", ...new Set(activity.map((row) => row.source))]
  return (
    <Tabs defaultValue="All" className="gap-5">
      <TabsList variant="underline" className="max-w-full overflow-x-auto">
        {filters.map((filter) => (
          <TabsTab key={filter} value={filter}>
            {filter}
          </TabsTab>
        ))}
      </TabsList>
      {filters.map((filter) => {
        const rows =
          filter === "All"
            ? activity
            : activity.filter((row) => row.source === filter)
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
                {rows.length ? (
                  rows.map((row, index) => (
                    <TableRow key={`${row.transaction}-${row.event}-${index}`}>
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
                  ))
                ) : (
                  <TableRow>
                    <TableCell
                      colSpan={5}
                      className="h-24 text-center text-muted-foreground"
                    >
                      No recent activity is available. Reload in a moment.
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TabsPanel>
        )
      })}
    </Tabs>
  )
}
