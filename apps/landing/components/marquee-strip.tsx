const ITEMS = [
  "sealed bids",
  "encrypted amounts",
  "no leaked pricing",
  "onchain settlement",
  "one invoice, many bidders",
]

export function MarqueeStrip() {
  const loop = [...ITEMS, ...ITEMS, ...ITEMS, ...ITEMS]

  return (
    <div className="overflow-hidden border-y border-border bg-emerald-500 py-3">
      <div className="flex w-max animate-marquee items-center gap-8">
        {loop.map((item, i) => (
          <span
            key={`${item}-${i}`}
            className="flex shrink-0 items-center gap-8 text-sm font-bold tracking-tight text-emerald-950 uppercase"
          >
            {item}
            <span className="size-1.5 rounded-full bg-emerald-950/40" />
          </span>
        ))}
      </div>
    </div>
  )
}
