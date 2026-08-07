import { PageHeader } from "@/components/page-header"
import { Money } from "@/components/receivable-primitives"
import { ReceivablesTable } from "@/components/receivables-table"
import { RECEIVABLES } from "@/lib/demo-data"

const METRICS = [
  { label: "Outstanding", value: <Money value={1_000_000} /> },
  { label: "Financed", value: <Money value={920_000} /> },
  { label: "Active auctions", value: "1" },
  { label: "Due soon", value: "1" },
]

export default function OverviewPage() {
  return (
    <div className="space-y-10">
      <PageHeader
        title="Overview"
        description="Your receivables and financing activity."
      />

      <section className="grid grid-cols-2 border-y md:grid-cols-4">
        {METRICS.map((metric, index) => (
          <div
            key={metric.label}
            className={`py-5 ${index % 2 === 0 ? "pr-5" : "border-l pl-5"} md:px-6 md:first:pl-0 md:last:pr-0 md:[&:not(:first-child)]:border-l`}
          >
            <p className="text-xs text-muted-foreground">{metric.label}</p>
            <p className="mt-2 text-xl font-medium tabular-nums sm:text-2xl">
              {metric.value}
            </p>
          </div>
        ))}
      </section>

      <section>
        <div className="mb-4">
          <h2 className="text-base font-medium">Active receivables</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Invoices currently moving through financing.
          </p>
        </div>
        <ReceivablesTable
          compact
          receivables={RECEIVABLES.filter((item) =>
            ["Awaiting buyer", "Buyer confirmed", "Auction open"].includes(
              item.status
            )
          )}
        />
      </section>
    </div>
  )
}
