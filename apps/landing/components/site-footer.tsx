import { brand, social } from "@bidnox/site-config"
import Link from "next/link"

import { Logo } from "@/components/logo"

const GROUPS = [
  {
    title: "Product",
    links: [
      { label: "How it works", href: "#how" },
      { label: "For suppliers", href: "#suppliers" },
      { label: "For financiers", href: "#financiers" },
      { label: "Settlement", href: "#settlement" },
    ],
  },
  {
    title: "Resources",
    links: [
      { label: "Docs", href: "#faq" },
      { label: "Contracts", href: "#trust" },
      { label: "Status", href: "#trust" },
      { label: "Changelog", href: "#trust" },
    ],
  },
  {
    title: "Company",
    links: [
      { label: "X", href: social.x },
      { label: "GitHub", href: social.github },
      { label: "Privacy", href: "#trust" },
      { label: "Terms", href: "#trust" },
    ],
  },
]

export function SiteFooter() {
  return (
    <footer className="border-t border-border">
      <div className="mx-auto grid w-full max-w-6xl gap-10 px-5 py-14 md:grid-cols-[1.4fr_repeat(3,1fr)]">
        <div className="flex flex-col gap-3">
          <Logo />
          <p className="max-w-64 text-sm text-muted-foreground">
            Sealed-bid invoice financing. Amounts stay encrypted until settlement.
          </p>
        </div>

        {GROUPS.map((group) => (
          <div key={group.title} className="flex flex-col gap-3">
            <h3 className="text-xs font-bold tracking-widest uppercase">{group.title}</h3>
            <ul className="flex flex-col gap-2">
              {group.links.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-sm text-muted-foreground transition-colors hover:text-foreground"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mx-auto flex w-full max-w-6xl flex-col gap-2 border-t border-border px-5 py-6 text-xs text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <span>
          &copy; {new Date().getFullYear()} {brand.name}. All rights reserved.
        </span>
        <span>bidnox.xyz</span>
      </div>
    </footer>
  )
}
