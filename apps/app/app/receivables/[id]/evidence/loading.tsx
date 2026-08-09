export default function EvidenceLoading() {
  return (
    <div
      className="mx-auto max-w-3xl space-y-6"
      aria-busy="true"
      aria-label="Loading on-chain evidence"
    >
      <div className="h-5 w-32 animate-pulse rounded bg-muted" />
      <div className="space-y-3">
        <div className="h-8 w-56 animate-pulse rounded bg-muted" />
        <div className="h-4 w-80 max-w-full animate-pulse rounded bg-muted" />
      </div>
      <div className="space-y-3 rounded-xl border p-5">
        {[0, 1, 2, 3].map((item) => (
          <div className="h-14 animate-pulse rounded-lg bg-muted" key={item} />
        ))}
      </div>
    </div>
  )
}
