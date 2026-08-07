import { cn } from "@/lib/utils"

/**
 * Bidnox mark: an invoice with its amount sealed.
 * Monochrome, inherits `currentColor`.
 */
export function LogoMark({ className, ...props }: React.ComponentProps<"svg">) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
      className={cn("size-6", className)}
      {...props}
    >
      <g
        stroke="currentColor"
        strokeWidth={1.75}
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M6 5.25A1.75 1.75 0 0 1 7.75 3.5h8.5A1.75 1.75 0 0 1 18 5.25V20.5l-2-1.25-2 1.25-2-1.25-2 1.25-2-1.25z" />
        <path d="M9 8.5h6" />
      </g>
      <rect x="9" y="11.5" width="6" height="2.5" rx="1.25" fill="currentColor" />
    </svg>
  )
}

export function Logo({ className, ...props }: React.ComponentProps<"div">) {
  return (
    <div className={cn("flex items-center gap-2", className)} {...props}>
      <LogoMark />
      <span className="font-mono text-base font-medium tracking-tighter lowercase">
        bidnox
      </span>
      <span className="sr-only">Bidnox</span>
    </div>
  )
}
