import { cn } from "@/lib/utils"

type AssetBoxProps = {
  label: string
  ratio?: string
  className?: string
}

export function AssetBox({ label, ratio = "16 / 9", className }: AssetBoxProps) {
  return (
    <div
      className={cn(
        "relative flex w-full items-center justify-center overflow-hidden rounded-2xl border border-dashed border-border bg-muted/40",
        className,
      )}
      style={{ aspectRatio: ratio }}
    >
      <div className="flex flex-col items-center gap-1 px-6 text-center">
        <span className="text-sm font-semibold tracking-tight">{label}</span>
        <span className="text-xs text-muted-foreground">{ratio}</span>
      </div>
      <span className="absolute top-3 left-3 size-1.5 rounded-full bg-emerald-500" />
    </div>
  )
}
