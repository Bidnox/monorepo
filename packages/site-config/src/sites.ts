import { brand } from "./brand"

export type SiteKey = "landing" | "app"

export type Site = {
  key: SiteKey
  url: string
  title: string
  titleTemplate: string
  description: string
  socialDescription: string
  ogImage: { url: string; width: number; height: number; alt: string }
  index: boolean
}

// TODO: replace placeholder copy
const tagline = "Private invoice bidding"
const summary =
  "Bid on invoices without revealing your numbers. Amounts stay encrypted until settlement."

const ogImage = {
  url: "/og.jpg",
  width: 1200,
  height: 675,
  alt: `${brand.name}, private invoice bidding`,
}

export const sites: Record<SiteKey, Site> = {
  landing: {
    key: "landing",
    url: "https://bidnox.xyz",
    title: `${brand.name} | ${tagline}`,
    titleTemplate: `%s | ${brand.name}`,
    description: summary,
    socialDescription: summary,
    ogImage,
    index: true,
  },
  app: {
    key: "app",
    url: "https://app.bidnox.xyz",
    title: `${brand.name} | ${tagline}`,
    titleTemplate: `%s | ${brand.name}`,
    description: summary,
    socialDescription: summary,
    ogImage,
    index: false,
  },
}
