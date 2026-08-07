"use client"

import * as React from "react"
import {
  darkTheme,
  lightTheme,
  RainbowKitProvider,
} from "@rainbow-me/rainbowkit"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { useTheme } from "next-themes"
import { WagmiProvider } from "wagmi"

import { baseSepolia, wagmiConfig } from "@/lib/wagmi"

const queryClient = new QueryClient()

const sharedTheme = {
  borderRadius: "small",
  fontStack: "system",
  overlayBlur: "small",
} as const

export function Web3Provider({ children }: { children: React.ReactNode }) {
  const { resolvedTheme } = useTheme()
  const rainbowTheme =
    resolvedTheme === "dark"
      ? darkTheme({
          ...sharedTheme,
          accentColor: "#f5f5f5",
          accentColorForeground: "#262626",
        })
      : lightTheme({
          ...sharedTheme,
          accentColor: "#262626",
          accentColorForeground: "#fafafa",
        })

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          initialChain={baseSepolia}
          theme={rainbowTheme}
          appInfo={{ appName: "Bidnox", learnMoreUrl: "https://bidnox.xyz" }}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}
