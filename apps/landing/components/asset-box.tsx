import { cn } from "@/lib/utils"

type AssetBoxProps = {
  label: string
  ratio?: string
  tone?: string
  className?: string
}

export function AssetBox({
  label,
  ratio = "16 / 9",
  tone = "bg-muted",
  className,
}: AssetBoxProps) {
  return (
    <div
      className={cn(
        "relative flex w-full items-center justify-center overflow-hidden rounded-xl",
        tone,
        className,
      )}
      style={{ aspectRatio: ratio }}
    >
      <span className="rounded-md bg-background/80 px-2.5 py-1 text-[11px] font-semibold tracking-tight text-muted-foreground">
        {label} &middot; {ratio}
      </span>
    </div>
  )
}
