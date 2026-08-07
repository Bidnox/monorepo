import Link from "next/link"

import { social } from "@bidnox/site-config"

export function SiteHeader() {
  return (
    <div className="pointer-events-none fixed inset-x-0 top-4 z-50 flex justify-center px-4">
      <div className="pointer-events-auto flex items-center gap-3 rounded-full bg-white/95 p-1.5 pl-4 shadow-[0_1px_2px_rgba(0,0,0,0.08)] backdrop-blur">
        <Link href="/" className="font-heading text-base tracking-tight uppercase">
          bidnox
        </Link>

        <span className="h-5 w-px bg-black/10" />

        <div className="flex items-center gap-3 px-0.5 text-[13px] text-black/55">
          <Link href={social.x} className="transition-colors hover:text-black">
            X
          </Link>
          <Link href={social.github} className="transition-colors hover:text-black">
            GitHub
          </Link>
        </div>

        <Link
          href="#cta"
          className="rounded-full bg-neutral-900 px-4 py-2 text-[13px] font-semibold text-white transition-colors hover:bg-black"
        >
          Get early access
        </Link>
      </div>
    </div>
  )
}
