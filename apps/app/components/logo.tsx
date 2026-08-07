import { cn } from "@/lib/utils"

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
          className={mono ? "fill-current" : "fill-zinc-500"}
        />
      ))}
      <rect
        x="3.5"
        y="15.7"
        width="13"
        height="4"
        rx="2"
        className={mono ? "fill-current" : "fill-emerald-500"}
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
