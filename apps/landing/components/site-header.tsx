import Link from "next/link"

import { social } from "@bidnox/site-config"

export function SiteHeader() {
  return (
    <div className="pointer-events-none fixed inset-x-0 top-4 z-50 flex justify-center px-4">
      <div className="pointer-events-auto flex items-center gap-3 rounded-full border border-border bg-card/95 p-1.5 pl-4 shadow-xs backdrop-blur">
        <Link href="/" className="font-heading text-base tracking-tight uppercase">
          bidnox
        </Link>

        <span className="h-5 w-px bg-border" />

        <div className="flex items-center gap-3 px-0.5 text-[13px] text-muted-foreground">
          <Link href={social.x} className="transition-colors hover:text-foreground">
            X
          </Link>
          <Link href={social.github} className="transition-colors hover:text-foreground">
            GitHub
          </Link>
        </div>

        <Link
          href="#cta"
          className="rounded-full bg-brand px-4 py-2 text-[13px] font-semibold text-brand-foreground transition-colors hover:opacity-90"
        >
          Get early access
        </Link>
      </div>
    </div>
  )
}
