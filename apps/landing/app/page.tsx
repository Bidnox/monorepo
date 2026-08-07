import Image from "next/image"
import Link from "next/link"
import { sites } from "@bidnox/site-config"

import { AssetBox } from "@/components/asset-box"
import { MediaTile } from "@/components/media-tile"
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
    src: "/assets/approved-invoice.png",
    alt: "Buyer-confirmed receivable ready for sealed bids",
    title: "Confirm",
    lines: ["Create the receivable.", "The buyer signs the exact terms."],
  },
  {
    src: "/assets/bids-leaderboard.png",
    alt: "Leaderboard of verified lenders bidding",
    title: "Bid",
    lines: [
      "Banks, NBFCs and fintechs compete.",
      "No lender sees another bid.",
    ],
  },
  {
    src: "/assets/working-capital.png",
    alt: "Clean capital for a buyer-confirmed receivable",
    title: "Settle",
    lines: ["Recheck both parties.", "Move aUSDC to the seller."],
  },
]

const ENABLES = [
  {
    src: "/assets/list-invoice.png",
    alt: "Bidnox receivable financing lifecycle",
    ratio: "4 / 3",
    title: "One complete lifecycle",
    lines: ["Create, confirm, check and bid.", "Then settle and repay."],
  },
  {
    src: "/assets/funding-options.png",
    alt: "Cleanverse settlement preflight",
    ratio: "4 / 3",
    title: "Compliance before settlement",
    lines: [
      "Winner and seller rechecked.",
      "aUSDC confirmed before value moves.",
    ],
  },
  {
    src: "/assets/open-invoices.png",
    alt: "Live sealed receivable auctions",
    ratio: "5 / 4",
    title: "Track sealed auctions",
    lines: ["See counts, not competing offers.", "Bid values remain private."],
  },
  {
    src: "/assets/bidder-card.png",
    alt: "Eligible financier entering a sealed auction",
    ratio: "5 / 4",
    title: "Only eligible financiers bid",
    lines: ["A-Pass must be active.", "aUSDC eligibility is checked."],
  },
]

// TODO: real numbers
const STATS = [
  { value: "—", label: "invoices funded" },
  { value: "—", label: "verified lenders" },
  { value: "0", label: "bids ever leaked" },
]

const FAQ = [
  {
    q: "Who can see my bid?",
    a: "No other lender. Bids are encrypted when they are submitted. At close, only the winning rate is revealed so the invoice can be funded. Losing bids stay sealed permanently.",
  },
  {
    q: "What stops the supplier from peeking at bids?",
    a: "The supplier never holds the key material for an open auction. They see how many bids exist, not what they are.",
  },
  {
    q: "How is the winning bid chosen?",
    a: "The best rate above your floor wins at close. The comparison happens over encrypted values, so no intermediate result leaks.",
  },
  {
    q: "What if no bid clears my floor?",
    a: "The auction closes with no winner, nothing is revealed, and you can relist with different terms.",
  },
]

export default function Page() {
  return (
    <div className="min-h-svh bg-background">
      <SiteHeader />

      <main>
        <section className="px-6 pt-32 pb-20 text-center sm:pt-40">
          <h1 className="mx-auto max-w-5xl font-heading text-[clamp(2.75rem,9vw,7.5rem)] leading-[0.86] tracking-[-0.03em]">
            Your lenders
            <br />
            see nothing
          </h1>

          <div className="mx-auto mt-14 w-full max-w-[26rem]">
            <div className="relative aspect-[719/1410] w-full">
              <Image
                src="/app-screen/light-mode.png"
                alt="Bidnox buyer-confirmed receivable and sealed auction"
                draggable={false}
                fill
                priority
                unoptimized
                sizes="(max-width: 640px) calc(100vw - 3rem), 416px"
                className="object-contain dark:hidden"
              />
              <Image
                src="/app-screen/dark-mode.png"
                alt=""
                draggable={false}
                fill
                unoptimized
                sizes="(max-width: 640px) calc(100vw - 3rem), 416px"
                className="hidden object-contain dark:block"
              />
            </div>
          </div>

          <p className="mt-6 text-[13px] font-semibold">
            Sealed-bid invoice financing, for suppliers who hate leaking price.
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
                  <MediaTile src={step.src} alt={step.alt} ratio="4 / 5" />
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
                  <MediaTile src={item.src} alt={item.alt} ratio={item.ratio} />
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
                <p className="mt-2 text-[13px] text-muted-foreground">
                  {stat.label}
                </p>
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
                <AssetBox
                  label="Walkthrough video"
                  ratio="16 / 9"
                  tone="bg-muted"
                />
                <p className="mt-4 text-[13px] font-semibold">
                  Watch an auction close
                </p>
                <p className="text-[13px] text-muted-foreground">
                  Ninety seconds, listing to funded.
                </p>
              </div>
              <div>
                <div className="relative flex aspect-[16/9] w-full items-end justify-center overflow-hidden rounded-xl bg-neutral-900">
                  <div className="relative aspect-[719/1410] w-[38%] translate-y-[14%]">
                    <Image
                      src="/app-screen/dark-mode.png"
                      alt="Bidnox app in dark mode"
                      draggable={false}
                      fill
                      unoptimized
                      sizes="180px"
                      className="object-contain"
                    />
                  </div>
                </div>
                <p className="mt-4 text-[13px] font-semibold">
                  Every contract is public
                </p>
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
                <AccordionItem
                  key={item.q}
                  value={item.q}
                  className="border-border"
                >
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
            <h2 className="mx-auto max-w-3xl font-heading text-[clamp(2rem,6vw,4.5rem)] leading-[0.9] tracking-[-0.03em] text-primary-foreground">
              Stop leaking
              <br />
              your pricing
            </h2>
            <p className="mx-auto mt-6 max-w-md text-[13px] text-primary-foreground/70">
              Choose your view and enter the private invoice marketplace.
            </p>
            <Link
              href={sites.app.url}
              className="mt-8 inline-flex rounded-full bg-brand px-6 py-3 text-[13px] font-semibold text-brand-foreground transition-transform hover:-translate-y-0.5"
            >
              Launch app
            </Link>
          </div>
        </section>
      </main>

      <SiteFooter />
    </div>
  )
}
