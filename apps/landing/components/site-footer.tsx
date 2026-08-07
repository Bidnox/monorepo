import { brand, social } from "@bidnox/site-config"
import Link from "next/link"

const GROUPS = [
  {
    title: "Product",
    links: [
      { label: "How it works", href: "#how" },
      { label: "Suppliers", href: "#enables" },
      { label: "Financiers", href: "#enables" },
      { label: "Settlement", href: "#enables" },
    ],
  },
  {
    title: "Resources",
    links: [
      { label: "Docs", href: "#faq" },
      { label: "Contracts", href: social.github },
      { label: "Status", href: "#faq" },
      { label: "Support", href: "#cta" },
    ],
  },
  {
    title: "Company",
    links: [
      { label: "X", href: social.x },
      { label: "GitHub", href: social.github },
      { label: "Privacy", href: "#faq" },
      { label: "Terms", href: "#faq" },
    ],
  },
]

export function SiteFooter() {
  return (
    <footer className="px-6 pb-16">
      <div className="mx-auto grid w-full max-w-295 gap-12 border-t border-black/8 pt-12 md:grid-cols-[1.6fr_repeat(3,1fr)]">
        <div>
          <p className="font-heading text-2xl tracking-tight uppercase">bidnox</p>
          <p className="mt-3 max-w-56 text-[13px] leading-relaxed text-black/55">
            Sealed-bid invoice financing. Amounts stay encrypted until settlement.
          </p>
        </div>

        {GROUPS.map((group) => (
          <div key={group.title}>
            <h3 className="text-[13px] font-semibold">{group.title}</h3>
            <ul className="mt-3 flex flex-col gap-2">
              {group.links.map((link) => (
                <li key={link.label}>
                  <Link
                    href={link.href}
                    className="text-[13px] text-black/55 transition-colors hover:text-black"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="mx-auto mt-12 flex w-full max-w-295 flex-col gap-1 text-[12px] text-black/40 sm:flex-row sm:justify-between">
        <span>
          &copy; {new Date().getFullYear()} {brand.name}
        </span>
        <span>bidnox.xyz</span>
      </div>
    </footer>
  )
}
