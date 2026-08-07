import { brand, sites, social } from "@bidnox/site-config"
import Link from "next/link"

const LINKS = [
  { label: "How it works", href: "#how" },
  { label: "Launch app", href: sites.app.url },
  { label: "GitHub", href: social.github },
  { label: "X", href: social.x },
]

export function SiteFooter() {
  return (
    <footer className="px-6 pb-16">
      <div className="mx-auto grid w-full max-w-295 gap-10 border-t border-border pt-12 md:grid-cols-[1.2fr_1fr] md:items-start">
        <div>
          <p className="font-heading text-2xl tracking-tight">bidnox</p>
          <p className="mt-3 max-w-56 text-[13px] leading-relaxed text-muted-foreground">
            Sealed-bid invoice financing. Amounts stay encrypted until settlement.
          </p>
        </div>

        <nav aria-label="Footer" className="md:justify-self-end">
          <ul className="flex flex-wrap gap-x-6 gap-y-3 md:max-w-76 md:justify-end">
            {LINKS.map((link) => (
              <li key={link.label}>
                <Link
                  href={link.href}
                  className="text-[13px] text-muted-foreground transition-colors hover:text-foreground"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
      </div>

      <div className="mx-auto mt-12 flex w-full max-w-295 flex-col gap-1 text-[12px] text-muted-foreground sm:flex-row sm:justify-between">
        <span>
          &copy; {new Date().getFullYear()} {brand.name}
        </span>
        <span>bidnox.xyz</span>
      </div>
    </footer>
  )
}
