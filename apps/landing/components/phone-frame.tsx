import { cn } from "@/lib/utils"

type PhoneFrameProps = {
  children?: React.ReactNode
  island?: boolean
  className?: string
  screenClassName?: string
}

export function PhoneFrame({
  children,
  island = true,
  className,
  screenClassName,
}: PhoneFrameProps) {
  return (
    <div
      className={cn(
        "relative w-full rounded-[13%/6.2%] bg-neutral-900 p-[2.2%] shadow-[0_24px_60px_-20px_rgba(0,0,0,0.45)] ring-1 ring-white/10 ring-inset",
        className,
      )}
    >
      <span className="absolute top-[16%] -left-[0.7%] h-[5%] w-[0.7%] rounded-l-sm bg-neutral-800" />
      <span className="absolute top-[25%] -left-[0.7%] h-[8%] w-[0.7%] rounded-l-sm bg-neutral-800" />
      <span className="absolute top-[36%] -left-[0.7%] h-[8%] w-[0.7%] rounded-l-sm bg-neutral-800" />
      <span className="absolute top-[27%] -right-[0.7%] h-[11%] w-[0.7%] rounded-r-sm bg-neutral-800" />

      <div
        className={cn(
          "relative aspect-[9/19.5] w-full overflow-hidden rounded-[11%/5.4%] bg-background",
          screenClassName,
        )}
      >
        {children}

        {island ? (
          <span className="absolute top-[1.4%] left-1/2 h-[3.4%] w-[30%] -translate-x-1/2 rounded-full bg-neutral-950" />
        ) : null}
      </div>
    </div>
  )
}

export function PhoneScreenPlaceholder({ label = "App screen" }: { label?: string }) {
  return (
    <div className="flex size-full items-center justify-center bg-background">
      <span className="rounded-md bg-muted px-2.5 py-1 text-[11px] font-semibold tracking-tight text-muted-foreground">
        {label} &middot; 1179 x 2556
      </span>
    </div>
  )
}
