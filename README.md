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

Not locked yet. Candidates: `apps/landing/public/icon-options.png` (16 marks, each at 68 / 26 / 16px).

`apps/*/components/logo.tsx` holds the current placeholder (option 01, receipt with a sealed
total). It is monochrome and inherits `currentColor`:

```tsx
import { Logo, LogoMark } from "@/components/logo"
```

Once a mark is picked, exports go to `apps/*/public` (svg + png, black/white) and favicons
land on the Next file convention: `apps/*/app/icon.svg` and `apple-icon.png`.
