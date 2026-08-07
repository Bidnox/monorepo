import { cn } from "@/lib/utils"

/** Row widths, top to bottom. The sealed total sits below them. */
const ROWS = [
  { y: 4.3, width: 9 },
  { y: 8.1, width: 13.5 },
  { y: 11.9, width: 17 },
]

export function LogoMark({
  mono = false,
  className,
  ...props
}: React.ComponentProps<"svg"> & { mono?: boolean }) {
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden="true"
      className={cn("size-6", className)}
      {...props}
    >
      {ROWS.map((row) => (
        <rect
          key={row.y}
          x="3.5"
          y={row.y}
          width={row.width}
          height="1.9"
          rx="0.95"
          fill="currentColor"
          opacity={mono ? 1 : 0.38}
        />
      ))}
      <rect
        x="3.5"
        y="15.7"
        width="13"
        height="4"
        rx="2"
        fill={mono ? "currentColor" : undefined}
        className={mono ? undefined : "fill-emerald-600 dark:fill-emerald-400"}
      />
    </svg>
  )
}

export function Logo({
  mono = false,
  className,
  ...props
}: React.ComponentProps<"div"> & { mono?: boolean }) {
  return (
    <div className={cn("flex items-center gap-2", className)} {...props}>
      <LogoMark mono={mono} />
      <span className="font-mono text-base font-medium tracking-tighter lowercase">
        bidnox
      </span>
      <span className="sr-only">Bidnox</span>
    </div>
  )
}
