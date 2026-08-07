import Link from "next/link"

import { Logo } from "@/components/logo"
import { Button } from "@/components/ui/button"

const NAV = [
  { label: "How it works", href: "#how" },
  { label: "For suppliers", href: "#suppliers" },
  { label: "For financiers", href: "#financiers" },
  { label: "FAQ", href: "#faq" },
]

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-border bg-background/85 backdrop-blur">
      <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between gap-6 px-5">
        <Link href="/" className="shrink-0">
          <Logo />
        </Link>

        <nav className="hidden items-center gap-7 md:flex">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" render={<Link href="#faq" />}>
            Docs
          </Button>
          <Button size="sm" render={<Link href="#cta" />}>
            Get early access
          </Button>
        </div>
      </div>
    </header>
  )
}
