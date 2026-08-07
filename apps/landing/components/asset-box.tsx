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
  tone = "bg-neutral-200",
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
      <span className="rounded-md bg-black/8 px-2.5 py-1 text-[11px] font-semibold tracking-tight text-black/55">
        {label} &middot; {ratio}
      </span>
    </div>
  )
}
