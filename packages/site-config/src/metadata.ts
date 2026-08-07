import type { Metadata } from "next"

import { brand } from "./brand"
import { sites, type SiteKey } from "./sites"

export function createMetadata(key: SiteKey, overrides: Metadata = {}): Metadata {
  const site = sites[key]

  return {
    metadataBase: new URL(site.url),
    title: { default: site.title, template: site.titleTemplate },
    description: site.description,
    applicationName: brand.name,
    robots: site.index ? undefined : { index: false, follow: false },
    openGraph: {
      title: site.title,
      description: site.socialDescription,
      type: "website",
      url: "/",
      siteName: brand.name,
      images: [site.ogImage],
    },
    twitter: {
      card: "summary_large_image",
      title: site.title,
      description: site.socialDescription,
      site: `@${brand.x}`,
      creator: `@${brand.x}`,
      images: [site.ogImage.url],
    },
    ...overrides,
  }
}
