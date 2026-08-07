# bidnox branding

The mark is a set of invoice rows with the total sealed. The rows sit back in a muted
grey so the emerald seal is the thing you look at.

```
mark          rows 9 / 13.5 / 17 wide, 1.9 tall, on a 24 grid
seal          13 wide, 4 tall, rx 2, sitting one row-pitch below
wordmark      bidnox, lowercase, mono, 500, tracking -0.6
```

## Colour

| role | light background | dark background |
| --- | --- | --- |
| rows | `#a1a1aa` zinc-400 | `#71717a` zinc-500 |
| seal | `#059669` emerald-600 | `#34d399` emerald-400 |
| wordmark | `#0a0a0a` | `#fafafa` |

Emerald is the only accent. It marks sealed or encrypted values, and nothing else.

## Which file to use

**In the apps, use the React component, not these files** — it inherits `currentColor`
and swaps the emerald on theme change:

```tsx
import { Logo, LogoMark } from "@/components/logo"

<Logo />            // mark + wordmark
<LogoMark />        // mark alone
<LogoMark mono />   // single colour, for emerald or photo backgrounds
```

| purpose | file |
| --- | --- |
| Embedding where the theme is unknown | `mark/mark-auto.svg`, `lockup/lockup-auto.svg` |
| Light background | `mark/mark-light.svg`, `lockup/lockup-light.svg` |
| Dark background | `mark/mark-dark.svg`, `lockup/lockup-dark.svg` |
| One colour: print, stamps, engraving | `mark/mark-mono-black.svg` |
| On emerald, on photos, over video | `mark/mark-mono-white.svg` |
| Favicon, PWA, browser tab | `app-icon/tile-dark.svg` (shipped as `apps/*/app/icon.svg`) |
| iOS home screen | `app-icon/apple-icon-180.png` (full bleed, no radius) |
| Slides, decks, README badges | the `.png` beside each `.svg` |
| Social cards | `social/og.png`, 1200x630 |
| Everything at a glance | `preview.png` |

PNG sizes: marks 1024x1024, lockups 1094x320, tiles 512x512, apple icon 180x180.
All transparent except the tiles, apple icon, and og card.

## Rules

- The app icon drops to **two rows**. Three rows blur below about 20px, so never
  scale the full mark down into a favicon.
- Never distinguish the seal by colour alone. It is always heavier and rounder than
  the rows, so the mark still works in monochrome.
- Keep clear space of one row-pitch (about 16% of the mark's width) on all sides.
- Do not recolour the rows to full black in the two-colour version; the contrast
  between muted rows and the emerald seal is the mark.

## Regenerating

The lockup `.svg` files set the wordmark as `<text>` with a mono font stack, so a
viewer without Geist Mono falls back to its own monospace. For anything typeset
where that matters, use the `.png` or the React component.
