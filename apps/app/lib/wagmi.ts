import { getDefaultConfig } from "@rainbow-me/rainbowkit"
import { injectedWallet } from "@rainbow-me/rainbowkit/wallets"
import { http } from "wagmi"
import { baseSepolia } from "wagmi/chains"

const walletConnectProjectId =
  process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID ??
  "00000000000000000000000000000000"

export const wagmiConfig = getDefaultConfig({
  appName: "Bidnox",
  projectId: walletConnectProjectId,
  chains: [baseSepolia],
  wallets: [
    {
      groupName: "Browser wallets",
      wallets: [injectedWallet],
    },
  ],
  transports: {
    [baseSepolia.id]: http(),
  },
  ssr: true,
})

export { baseSepolia }
