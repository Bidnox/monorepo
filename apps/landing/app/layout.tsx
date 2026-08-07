import { createMetadata } from "@bidnox/site-config"
import type { Metadata } from "next"
import { Anton, Geist_Mono, Inter } from "next/font/google"

import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"
import { cn } from "@/lib/utils";

export const metadata: Metadata = createMetadata("landing")

// stand-in for Helvetica Now Display Cn Bold
const display = Anton({ subsets: ["latin"], weight: "400", variable: "--font-heading" })

const sans = Inter({ subsets: ["latin"], variable: "--font-sans" })

const geistMono = Geist_Mono({subsets:['latin'],variable:'--font-mono'})

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={cn("antialiased", sans.variable, display.variable, geistMono.variable)}
    >
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  )
}
