import Link from "next/link"

import { AssetBox } from "@/components/asset-box"
import { SiteFooter } from "@/components/site-footer"
import { SiteHeader } from "@/components/site-header"
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion"

const STEPS = [
  {
    asset: "Listing screen",
    tone: "bg-chart-4",
    title: "List",
    lines: ["Upload the invoice.", "Set a private floor."],
  },
  {
    asset: "Sealed bid ticket",
    tone: "bg-muted",
    title: "Bid",
    lines: ["Financiers bid blind.", "Nobody sees a number."],
  },
  {
    asset: "Settlement screen",
    tone: "bg-chart-3",
    title: "Settle",
    lines: ["Best bid wins onchain.", "Losing bids stay sealed."],
  },
]

const ENABLES = [
  {
    asset: "Supplier dashboard",
    tone: "bg-chart-2",
    ratio: "5 / 4",
    title: "Get paid early, quietly",
    lines: ["List a receivable and let financiers compete.", "Your pricing never leaks."],
  },
  {
    asset: "Bid ticket",
    tone: "bg-muted",
    ratio: "5 / 4",
    title: "Price on merit",
    lines: ["You see the paper, not the other bids.", "No anchoring, no blinking first."],
  },
  {
    asset: "Encryption flow",
    tone: "bg-chart-1",
    ratio: "5 / 4",
    title: "Encrypted until settlement",
    lines: ["Amounts decrypt only to settle the winner.", "Everything else stays sealed."],
  },
  {
    asset: "Portfolio view",
    tone: "bg-chart-5",
    ratio: "5 / 4",
    title: "Every trade, one place",
    lines: ["Track open auctions and settled paper.", "Export whenever you need it."],
  },
]

// TODO: real numbers
const STATS = [
  { value: "—", label: "invoices listed" },
  { value: "—", label: "volume settled" },
  { value: "0", label: "bids ever leaked" },
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
    q: "What if nothing clears my floor?",
    a: "The auction closes with no winner, nothing is revealed, and you can relist with different terms.",
  },
]

export default function Page() {
  return (
    <div className="min-h-svh bg-background">
      <SiteHeader />

      <main>
        <section className="px-6 pt-32 pb-20 text-center sm:pt-40">
          <h1 className="mx-auto max-w-5xl font-heading text-[clamp(2.75rem,9vw,7.5rem)] leading-[0.86] tracking-[-0.03em] uppercase">
            Your bidders
            <br />
            see nothing
          </h1>

          <div className="mx-auto mt-14 w-full max-w-95">
            <AssetBox label="App screen" ratio="1 / 2" tone="bg-secondary" />
          </div>

          <p className="mt-6 text-[13px] font-semibold">
            Sealed-bid invoice financing, for people who hate leaking price.
          </p>
        </section>

        <section id="how" className="px-6 py-16">
          <div className="mx-auto w-full max-w-295">
            <h2 className="max-w-md text-[clamp(1.6rem,3.4vw,2.4rem)] leading-[1.08] font-bold tracking-[-0.02em]">
              How a sealed auction
              <br />
              works on bidnox
            </h2>

            <div className="mt-8 grid gap-5 sm:grid-cols-3">
              {STEPS.map((step) => (
                <div key={step.title}>
                  <AssetBox label={step.asset} ratio="1 / 1" tone={step.tone} />
                  <p className="mt-4 text-[13px] font-semibold">{step.title}</p>
                  {step.lines.map((line) => (
                    <p key={line} className="text-[13px] text-muted-foreground">
                      {line}
                    </p>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </section>

        <section id="enables" className="px-6 py-16">
          <div className="mx-auto w-full max-w-295">
            <h2 className="max-w-md text-[clamp(1.6rem,3.4vw,2.4rem)] leading-[1.08] font-bold tracking-[-0.02em]">
              What bidnox enables
            </h2>

            <div className="mt-8 grid gap-5 sm:grid-cols-2">
              {ENABLES.map((item) => (
                <div key={item.title}>
                  <AssetBox label={item.asset} ratio={item.ratio} tone={item.tone} />
                  <p className="mt-4 text-[13px] font-semibold">{item.title}</p>
                  {item.lines.map((line) => (
                    <p key={line} className="text-[13px] text-muted-foreground">
                      {line}
                    </p>
                  ))}
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="px-6 py-16">
          <div className="mx-auto flex w-full max-w-295 flex-wrap gap-x-20 gap-y-8">
            {STATS.map((stat) => (
              <div key={stat.label}>
                <p className="font-heading text-[clamp(2.5rem,6vw,4.5rem)] leading-none tracking-[-0.03em]">
                  {stat.value}
                </p>
                <p className="mt-2 text-[13px] text-muted-foreground">{stat.label}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="px-6 py-16">
          <div className="mx-auto w-full max-w-295">
            <h2 className="max-w-md text-[clamp(1.6rem,3.4vw,2.4rem)] leading-[1.08] font-bold tracking-[-0.02em]">
              Do not trust us,
              <br />
              read the contracts
            </h2>

            <div className="mt-8 grid gap-5 sm:grid-cols-2">
              <div>
                <AssetBox label="Walkthrough video" ratio="16 / 9" tone="bg-muted" />
                <p className="mt-4 text-[13px] font-semibold">Watch an auction close</p>
                <p className="text-[13px] text-muted-foreground">
                  Ninety seconds, listing to settlement.
                </p>
              </div>
              <div>
                <AssetBox label="Contracts" ratio="16 / 9" tone="bg-secondary" />
                <p className="mt-4 text-[13px] font-semibold">Every contract is public</p>
                <p className="text-[13px] text-muted-foreground">
                  Read them, run them, try to break them.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section id="faq" className="px-6 py-16">
          <div className="mx-auto grid w-full max-w-295 gap-8 md:grid-cols-[1fr_1.6fr]">
            <h2 className="text-[clamp(1.6rem,3.4vw,2.4rem)] leading-[1.08] font-bold tracking-[-0.02em]">
              Questions
            </h2>
            <Accordion className="w-full">
              {FAQ.map((item) => (
                <AccordionItem key={item.q} value={item.q} className="border-border">
                  <AccordionTrigger className="text-[15px] font-semibold">
                    {item.q}
                  </AccordionTrigger>
                  <AccordionContent className="text-[13px] text-muted-foreground">
                    {item.a}
                  </AccordionContent>
                </AccordionItem>
              ))}
            </Accordion>
          </div>
        </section>

        <section id="cta" className="px-6 py-16">
          <div className="mx-auto w-full max-w-295 rounded-3xl bg-primary px-8 py-20 text-center sm:px-12">
            <h2 className="mx-auto max-w-3xl font-heading text-[clamp(2rem,6vw,4.5rem)] leading-[0.9] tracking-[-0.03em] text-primary-foreground uppercase">
              Stop leaking
              <br />
              your pricing
            </h2>
            <p className="mx-auto mt-6 max-w-md text-[13px] text-primary-foreground/70">
              Early access opens in batches. Tell us whether you are selling invoices or
              buying them.
            </p>
            <Link
              href="#cta"
              className="mt-8 inline-flex rounded-full bg-background px-6 py-3 text-[13px] font-semibold text-foreground transition-transform hover:-translate-y-0.5"
            >
              Get early access
            </Link>
          </div>
        </section>
      </main>

      <SiteFooter />
    </div>
  )
}
