# bidnox

Private invoice bidding.

## Structure

```
apps/landing     marketing site   (next 16, port 3000)
apps/app         product          (next 16, port 3001)
contracts/       solidity         (empty)
docs/brand/      logo exports
```

Bun workspace. Both apps are scaffolded with `shadcn@latest init @coss/style` (base-ui components, Inter + Geist Mono, css variables).

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

Invoice rows with the total sealed. Muted grey rows, emerald seal. Full asset set and
usage rules in [branding/](branding/README.md), everything at a glance in
`branding/preview.png`.

In the apps, use the component rather than the static files:

```tsx
import { Logo, LogoMark } from "@/components/logo"

<Logo />            // mark + wordmark
<LogoMark />        // mark alone
<LogoMark mono />   // single colour, for emerald or photo backgrounds
```

Emerald (`emerald-600` on light, `emerald-400` on dark) marks sealed or encrypted
values, and nothing else. Favicons use the Next file convention: `apps/*/app/icon.svg`
and `apple-icon.png`.
