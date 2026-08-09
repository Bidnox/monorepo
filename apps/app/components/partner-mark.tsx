import Image from "next/image"

import { cn } from "@/lib/utils"

const PARTNERS = {
  cleanverse: {
    name: "Cleanverse",
    image: "/integrations/cleanverse.svg",
  },
  inco: {
    name: "Inco",
    image: "/inco-mark.svg",
  },
} as const

export function PartnerMark({
  partner,
  compact = false,
  className,
}: {
  partner: keyof typeof PARTNERS
  compact?: boolean
  className?: string
}) {
  const value = PARTNERS[partner]

  return (
    <span
      className={cn("inline-flex items-center gap-1.5", className)}
      aria-label={value.name}
    >
      <Image
        src={value.image}
        width={24}
        height={24}
        alt=""
        className={cn(
          "size-4 shrink-0",
          partner === "cleanverse" && "dark:invert"
        )}
      />
      {compact ? (
        <span className="sr-only">{value.name}</span>
      ) : (
        <span>{value.name}</span>
      )}
    </span>
  )
}

export function PartnerRoute() {
  return (
    <span className="inline-flex items-center gap-2 text-xs text-muted-foreground">
      <PartnerMark partner="cleanverse" />
      <span aria-hidden="true">→</span>
      <PartnerMark partner="inco" />
    </span>
  )
}

export function EncryptionProgress({
  message = "Encrypting your bid",
}: {
  message?: string
}) {
  return (
    <div className="overflow-hidden rounded-xl border border-blue-500/15 bg-blue-500/[0.04] p-5 text-center">
      <div className="relative mx-auto grid size-20 place-items-center">
        <span className="absolute inset-0 rounded-full border border-blue-500/20 motion-safe:animate-[spin_5s_linear_infinite]" />
        <span className="absolute inset-2 rounded-full border border-dashed border-blue-500/30 motion-safe:animate-[spin_3s_linear_infinite_reverse]" />
        <span className="grid size-10 place-items-center rounded-xl bg-background shadow-sm ring-1 ring-blue-500/15">
          <PartnerMark partner="inco" compact className="[&_img]:size-6" />
        </span>
        <span className="absolute top-0 left-1/2 size-2 -translate-x-1/2 rounded-full bg-blue-500 shadow-[0_0_12px_rgba(54,115,245,0.75)] motion-safe:animate-pulse" />
      </div>
      <p className="mt-3 text-sm font-medium">{message}</p>
      <p className="mt-1 text-xs text-muted-foreground">
        Your amount is sealed before it leaves this device.
      </p>
      <div className="mx-auto mt-4 flex max-w-40 gap-1.5" aria-hidden="true">
        {["w-2/3", "w-full", "w-1/2"].map((width, index) => (
          <span
            key={width}
            className="h-1 flex-1 overflow-hidden rounded-full bg-blue-500/10"
          >
            <span
              className={cn(
                "block h-full rounded-full bg-blue-500 motion-safe:animate-pulse",
                width,
                index === 1 && "[animation-delay:180ms]",
                index === 2 && "[animation-delay:360ms]"
              )}
            />
          </span>
        ))}
      </div>
    </div>
  )
}
