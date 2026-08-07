import { ArrowUpRight, Lock, ShieldCheck } from "lucide-react"
import Link from "next/link"

import { AssetBox } from "@/components/asset-box"
import { LogoMark } from "@/components/logo"
import { MarqueeStrip } from "@/components/marquee-strip"
import { SiteFooter } from "@/components/site-footer"
import { SiteHeader } from "@/components/site-header"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"
import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"

const PILLARS = [
  {
    n: "01",
    title: "List",
    lead: "Put an invoice up",
    body: "Upload the invoice, set your floor, choose how long bidding stays open.",
  },
  {
    n: "02",
    title: "Bid",
    lead: "Nobody sees a number",
    body: "Every bid is encrypted on submission. No bidder learns another bid, win or lose.",
  },
  {
    n: "03",
    title: "Settle",
    lead: "Best bid wins onchain",
    body: "At close, only the winning amount is revealed. Everything else stays sealed.",
  },
]

const CAPABILITIES = [
  {
    id: "suppliers",
    eyebrow: "For suppliers",
    title: "Get paid early without showing your hand",
    body: "List a receivable and let financiers compete for it. Because bids are sealed, nobody can anchor to a competitor and nobody learns what your cashflow looks like.",
    points: ["Set a private floor", "Pick your settlement window", "Accept or walk away"],
    asset: "Supplier dashboard",
  },
  {
    id: "financiers",
    eyebrow: "For financiers",
    title: "Price on merit, not on who blinked first",
    body: "You see the invoice, the obligor, and the history. You do not see the other bids, so you price what the paper is actually worth.",
    points: ["Blind bidding", "Portfolio view", "Automated settlement"],
    asset: "Bid ticket",
  },
  {
    id: "settlement",
    eyebrow: "Settlement",
    title: "Encrypted until the moment it matters",
    body: "Amounts are encrypted end to end and only decrypted to settle the winning bid. Losing bids are never revealed, to anyone, at any point.",
    points: ["Encrypted amounts", "Onchain settlement", "Auditable trail"],
    asset: "Settlement flow diagram",
  },
]

// TODO: real numbers
const STATS = [
  { value: "—", label: "Invoices listed" },
  { value: "—", label: "Volume settled" },
  { value: "—", label: "Active financiers" },
  { value: "0", label: "Bids ever leaked" },
]

const TILES = [
  {
    title: "Read the docs",
    body: "How sealed bidding and settlement work, end to end.",
    cta: "Docs",
  },
  {
    title: "Read the contracts",
    body: "Every contract that touches an amount, in the open.",
    cta: "GitHub",
  },
  {
    title: "Talk to us",
    body: "Bringing a book of receivables? Start here.",
    cta: "Contact",
  },
]

const FAQ = [
  {
    q: "Who can see my bid?",
    a: "Nobody. Bids are encrypted when you submit them. At close, only the winning amount is decrypted so the trade can settle. Losing bids stay sealed permanently.",
  },
  {
    q: "What stops the seller from peeking at bids?",
    a: "The seller never holds the key material for an open auction. They see that bids exist and how many, not what they are.",
  },
  {
    q: "How is the winner chosen?",
    a: "The best bid above your floor wins at close. The comparison happens over encrypted values, so no intermediate result leaks.",
  },
  {
    q: "What happens if nothing clears my floor?",
    a: "The auction closes with no winner, nothing is revealed, and you can relist with different terms.",
  },
  {
    q: "Which chain does this settle on?",
    a: "Settlement is onchain and the contracts are public. Network details are in the docs.",
  },
]

export default function Page() {
  return (
    <div className="flex min-h-svh flex-col">
      <SiteHeader />

      <main className="flex-1">
        <section className="mx-auto w-full max-w-6xl px-5 pt-16 pb-14 md:pt-24">
          <div className="flex flex-col items-start gap-6">
            <span className="inline-flex -rotate-1 items-center gap-2 rounded-full bg-emerald-500 px-3 py-1 text-xs font-bold tracking-wide text-emerald-950 uppercase">
              <Lock className="size-3" />
              Sealed bids, encrypted amounts
            </span>

            <h1 className="max-w-4xl text-5xl leading-[0.92] font-black tracking-tighter uppercase sm:text-7xl md:text-8xl">
              Bid on invoices
              <br />
              without showing
              <br />
              <span className="text-emerald-500">your numbers</span>
            </h1>

            <p className="max-w-xl text-base text-muted-foreground sm:text-lg">
              bidnox is a sealed-bid marketplace for receivables. Financiers compete blind,
              amounts stay encrypted, and only the winning bid is ever revealed.
            </p>

            <div className="flex flex-wrap items-center gap-3">
              <Button size="xl" render={<Link href="#cta" />}>
                Get early access
              </Button>
              <Button size="xl" variant="outline" render={<Link href="#how" />}>
                See how it works
              </Button>
            </div>
          </div>

          <div className="mt-14">
            <AssetBox label="Product shot, hero" ratio="16 / 9" />
          </div>
        </section>

        <MarqueeStrip />

        <section id="how" className="mx-auto w-full max-w-6xl px-5 py-20">
          <h2 className="max-w-2xl text-3xl font-black tracking-tighter uppercase sm:text-5xl">
            Three steps, one sealed auction
          </h2>

          <div className="mt-12 grid gap-5 md:grid-cols-3">
            {PILLARS.map((pillar) => (
              <div
                key={pillar.n}
                className="flex flex-col gap-3 rounded-2xl border border-border p-6"
              >
                <span className="text-sm font-bold text-emerald-500">{pillar.n}</span>
                <h3 className="text-2xl font-black tracking-tight uppercase">{pillar.title}</h3>
                <p className="text-sm font-semibold">{pillar.lead}</p>
                <p className="text-sm text-muted-foreground">{pillar.body}</p>
              </div>
            ))}
          </div>
        </section>

        <div className="border-y border-border bg-muted/30">
          <div className="mx-auto grid w-full max-w-6xl grid-cols-2 gap-8 px-5 py-14 md:grid-cols-4">
            {STATS.map((stat) => (
              <div key={stat.label} className="flex flex-col gap-1">
                <span className="text-4xl font-black tracking-tighter sm:text-6xl">
                  {stat.value}
                </span>
                <span className="text-xs tracking-widest text-muted-foreground uppercase">
                  {stat.label}
                </span>
              </div>
            ))}
          </div>
        </div>

        {CAPABILITIES.map((cap, i) => (
          <section
            key={cap.id}
            id={cap.id}
            className="mx-auto w-full max-w-6xl px-5 py-20 md:py-24"
          >
            <div className="grid items-center gap-10 md:grid-cols-2 md:gap-16">
              <div className={cn(i % 2 === 1 && "md:order-2")}>
                <span className="text-xs font-bold tracking-widest text-emerald-500 uppercase">
                  {cap.eyebrow}
                </span>
                <h2 className="mt-4 text-3xl font-black tracking-tighter uppercase sm:text-4xl">
                  {cap.title}
                </h2>
                <p className="mt-4 text-base text-muted-foreground">{cap.body}</p>
                <ul className="mt-6 flex flex-col gap-2">
                  {cap.points.map((point) => (
                    <li key={point} className="flex items-center gap-2 text-sm font-medium">
                      <LogoMark className="size-4" />
                      {point}
                    </li>
                  ))}
                </ul>
              </div>
              <AssetBox
                label={cap.asset}
                ratio="4 / 3"
                className={cn(i % 2 === 1 && "md:order-1")}
              />
            </div>
          </section>
        ))}

        <section id="trust" className="border-y border-border">
          <div className="mx-auto grid w-full max-w-6xl gap-10 px-5 py-16 md:grid-cols-[1fr_1.2fr]">
            <div>
              <span className="inline-flex items-center gap-2 text-xs font-bold tracking-widest uppercase">
                <ShieldCheck className="size-4" />
                Verify it yourself
              </span>
              <h2 className="mt-4 text-3xl font-black tracking-tighter uppercase">
                Do not take our word for the privacy
              </h2>
              <p className="mt-4 text-sm text-muted-foreground">
                The contracts that hold and compare encrypted amounts are public. Read them,
                run them, break them.
              </p>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {TILES.map((tile) => (
                <Link
                  key={tile.title}
                  href="#cta"
                  className="group flex flex-col gap-2 rounded-2xl border border-border p-5 transition-colors hover:bg-muted/50"
                >
                  <span className="flex items-center justify-between text-sm font-bold tracking-tight uppercase">
                    {tile.title}
                    <ArrowUpRight className="size-4 transition-transform group-hover:-translate-y-0.5" />
                  </span>
                  <span className="text-sm text-muted-foreground">{tile.body}</span>
                  <span className="mt-1 text-xs font-bold tracking-widest text-emerald-500 uppercase">
                    {tile.cta}
                  </span>
                </Link>
              ))}
            </div>
          </div>
        </section>

        <section className="mx-auto w-full max-w-6xl px-5 py-20">
          <div className="grid gap-10 md:grid-cols-[1fr_1.4fr] md:gap-16">
            <div>
              <h2 className="text-3xl font-black tracking-tighter uppercase sm:text-4xl">
                Watch a sealed auction close
              </h2>
              <p className="mt-4 text-sm text-muted-foreground">
                Ninety seconds, start to settlement, with nothing revealed that should not be.
              </p>
            </div>
            <AssetBox label="Walkthrough video" ratio="16 / 9" />
          </div>
        </section>

        <section id="faq" className="border-t border-border">
          <div className="mx-auto grid w-full max-w-6xl gap-10 px-5 py-20 md:grid-cols-[1fr_1.4fr]">
            <h2 className="text-3xl font-black tracking-tighter uppercase sm:text-4xl">
              Questions
            </h2>
            <Accordion className="w-full">
              {FAQ.map((item) => (
                <AccordionItem key={item.q} value={item.q}>
                  <AccordionTrigger className="text-base font-semibold">
                    {item.q}
                  </AccordionTrigger>
                  <AccordionContent className="text-sm text-muted-foreground">
                    {item.a}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>
        </section>

        <section id="cta" className="border-t border-border bg-emerald-500">
          <div className="mx-auto flex w-full max-w-6xl flex-col items-start gap-6 px-5 py-20 text-emerald-950">
            <h2 className="max-w-3xl text-4xl leading-[0.95] font-black tracking-tighter uppercase sm:text-6xl">
              Stop leaking your pricing
            </h2>
            <p className="max-w-lg text-base text-emerald-950/80">
              Early access is opening in batches. Tell us whether you are selling invoices or
              buying them.
            </p>
            <div className="flex flex-wrap gap-3">
              <Button
                size="xl"
                className="border-emerald-950 bg-emerald-950 text-emerald-50 hover:bg-emerald-950/90"
                render={<Link href="#cta" />}
              >
                Get early access
              </Button>
              <Button
                size="xl"
                variant="outline"
                className="border-emerald-950/25 bg-transparent text-emerald-950 hover:bg-emerald-950/10"
                render={<Link href="#faq" />}
              >
                Read the docs
              </Button>
            </div>
          </div>
        </section>
      </main>

      <SiteFooter />
    </div>
  )
}
