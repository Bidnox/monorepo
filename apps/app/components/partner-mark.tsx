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
