# bidnox

Private invoice bidding.

## Structure

```
apps/landing            marketing site, bidnox.xyz          (next 16, port 3000)
apps/app                product, app.bidnox.xyz             (next 16, port 3001)
packages/site-config    shared brand + metadata config
contracts/              solidity (empty)
branding/               logo kits
```

Bun workspace. Both apps are scaffolded with `shadcn@latest init @coss/style` (base-ui components, Inter + Geist Mono, css variables).

## Shared config

`@bidnox/site-config` holds everything both apps must agree on: brand colours, social
handles, per-site urls, and the metadata builder.

```tsx
// apps/*/app/layout.tsx
import { createMetadata } from "@bidnox/site-config"

export const metadata: Metadata = createMetadata("landing")  // or "app"
```

That produces `metadataBase`, title template, description, openGraph, and twitter tags
from one source. `app` is set `noindex` so the product does not compete with the
marketing site in search. Both apps list the package in `transpilePackages`.

Copy in `packages/site-config/src/sites.ts` is a placeholder &mdash; replace the tagline
and summary there and both apps pick it up.

## Develop

```bash
bun install
bun run dev          # both apps
bun run dev:landing  # http://localhost:3000
bun run dev:app      # http://localhost:3001
```

## Build

```bash
bun run build
```

## Brand

Invoice rows with the lender bid sealed. Two kits, `colour` and `mono`, both readable on any
background so there is no light/dark split. Assets and rules in
[branding/](branding/README.md), everything at a glance in `branding/preview.png`.

In the apps, use the component rather than the static files:

```tsx
import { Logo, LogoMark } from "@/components/logo"

<Logo />            // mark + wordmark
<LogoMark />        // mark alone
<LogoMark mono />   // single colour, for emerald or photo backgrounds
```

Rows are `zinc-500`, the seal is `emerald-500`. Emerald marks sealed or encrypted
values, and nothing else. Favicons use the Next file convention: `apps/*/app/icon.svg`
and `apple-icon.png`.

## App modes and invoice storage

`NEXT_PUBLIC_DEMO_MODE=true` provides one-click form fixtures and a deterministic
invoice hash. Transactions are still signed by the connected wallet, mined on Base
Sepolia, and checked for a successful receipt. With demo mode disabled, invoice PDFs
or images are uploaded to Pinata's private IPFS network through a wallet-authorized,
Cleanverse-gated server route. `PINATA_JWT` is server-only.
