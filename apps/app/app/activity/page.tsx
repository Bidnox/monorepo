import { ActivityTable } from "@/components/activity-table"
import { PageHeader } from "@/components/page-header"
import { getActivity } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export default async function ActivityPage() {
  const activity = await getActivity()
  return (
    <div className="space-y-8">
      <PageHeader
        title="Activity"
        description="The latest workflow, privacy, and payment events from Base Sepolia."
      />
      <ActivityTable activity={activity} />
    </div>
  )
}
