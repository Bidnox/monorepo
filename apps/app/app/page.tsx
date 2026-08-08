import { PageHeader } from "@/components/page-header"
import { Money } from "@/components/receivable-primitives"
import { ReceivablesTable } from "@/components/receivables-table"
import { getReceivables } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function OverviewPage() {
  if (process.env.NEXT_PUBLIC_DEMO_MODE === "true") redirect("/receivables")

  const receivables = await getReceivables()
  const metrics = [
    {
      label: "Outstanding",
      value: (
        <Money
          value={receivables
            .filter((item) => !["Repaid", "Cancelled"].includes(item.status))
            .reduce((sum, item) => sum + item.faceValue, 0)}
        />
      ),
    },
    {
      label: "Financed",
      value: (
        <Money
          value={receivables.reduce(
            (sum, item) => sum + (item.advance ?? 0),
            0
          )}
        />
      ),
    },
    {
      label: "Active auctions",
      value: String(
        receivables.filter((item) => item.status === "Auction open").length
      ),
    },
    { label: "Total", value: String(receivables.length) },
  ]
  return (
    <div className="space-y-10">
      <PageHeader
        title="Overview"
        description="Your receivables and financing activity."
      />

      <section className="grid grid-cols-2 border-y md:grid-cols-4">
        {metrics.map((metric, index) => (
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
          receivables={receivables.filter((item) =>
            ["Awaiting buyer", "Buyer confirmed", "Auction open"].includes(
              item.status
            )
          )}
        />
      </section>
    </div>
  )
}
import { redirect } from "next/navigation"
