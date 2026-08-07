import Image from "next/image"

import { cn } from "@/lib/utils"

type MediaTileProps = {
  src: string
  alt: string
  ratio: string
  priority?: boolean
  className?: string
}

export function MediaTile({ src, alt, ratio, priority, className }: MediaTileProps) {
  return (
    <div
      className={cn("relative w-full overflow-hidden rounded-xl bg-muted", className)}
      style={{ aspectRatio: ratio }}
    >
      <Image
        src={src}
        alt={alt}
        fill
        priority={priority}
        sizes="(max-width: 640px) 100vw, 50vw"
        className="object-cover"
      />
    </div>
  )
}
