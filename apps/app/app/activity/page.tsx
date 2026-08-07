import { ActivityTable } from "@/components/activity-table"
import { PageHeader } from "@/components/page-header"

export default function ActivityPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Activity"
        description="Workflow, privacy, compliance, and payment events."
      />
      <ActivityTable />
    </div>
  )
}
