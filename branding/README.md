# bidnox branding

Invoice rows with the total sealed. The rows sit back in grey so the emerald seal is
the thing you look at.

Two kits, no light/dark split. Every colour is chosen to read on paper **and** on ink,
so one file covers both. There is no wordmark lockup file: the app sets the wordmark in
type, so it always matches the surrounding UI.

```
branding/
  colour/   mark.svg  mark.png  tile.svg  tile.png  tile-bleed.svg  apple-icon.png
  mono/     mark.svg  mark.png  tile.svg  tile.png  tile-bleed.svg  apple-icon.png
  social/   og.jpg  og-source.png
  preview.png
```

## Colour

| role | value | |
| --- | --- | --- |
| rows | `#71717a` | zinc-500 |
| seal | `#10b981` | emerald-500 |
| ink | `#0a0a0a` | tile and og backgrounds |
| paper | `#fafaf9` | og background |

Emerald marks sealed or encrypted values, and nothing else. The same values live in
code at `@bidnox/site-config` &rarr; `brand.colors`.

## Which kit

**colour** is the default. Grey rows, emerald seal, on any background.

**mono** is black, single colour. Use it for print, stamps, engraving, and anywhere the
mark sits on emerald, on a photo, or over video.

| purpose | file |
| --- | --- |
| Anywhere in a document or deck | `colour/mark.svg`, `colour/mark.png` |
| One colour, or on emerald / photos | `mono/mark.svg`, `mono/mark.png` |
| Favicon, PWA, browser tab | `colour/tile.svg` &rarr; shipped as `apps/*/app/icon.svg` |
| iOS home screen | `colour/apple-icon.png` (full bleed, no radius) |
| Social cards | `social/og.jpg` |
| Everything at a glance | `preview.png` |

PNG sizes: marks 1024x1024 transparent, tiles 512x512, apple icons 180x180.

The social card is `social/og.jpg`, 1200x675, served from both apps at `/og.jpg`. The
master lives beside it as `social/og-source.png` at 1672x941; regenerate the jpg from it
with `sips -s format jpeg -s formatOptions 86 --resampleHeightWidth 675 1200`.

## In the apps

Use the component, not the files &mdash; `mono` swaps to `currentColor`:

```tsx
import { Logo, LogoMark } from "@/components/logo"

<Logo />            // mark + wordmark
<LogoMark />        // mark alone
<LogoMark mono />   // single colour
```

Each app serves `/logo.svg` (colour) and `/logo-mono.svg` for anything outside React.

## Rules

- The tile drops to **two rows**. Three 1.9-unit rows blur below about 20px, so never
  scale the full mark down into a favicon; use the tile.
- The seal is heavier and rounder than the rows, never just greener. That is what keeps
  the mark readable in the mono kit.
- Keep clear space of one row-pitch, about 16% of the mark's width, on all sides.
- Do not darken the rows to full black in the colour kit. The contrast between muted
  rows and the emerald seal is the mark.
