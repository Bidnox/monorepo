import "server-only"

import { getAddress, isAddress, type Address } from "viem"

export const CLEANVERSE_AUSDC = getAddress(
  "0xaC0893567D43C3E7e6e35a72803df05416C1f20D"
)

const DEFAULT_BASE_URL = "https://uatapi.cleanverse.com/api/cooperate"
const REQUEST_TIMEOUT_MS = 12_000

export const DEMO_WALLETS = {
  buyer: getAddress("0x376b7271dD22D14D82Ef594324ea14e7670ed5b2"),
  seller: getAddress("0xf653B0f43b0f920E590Bf3745997B332d916Aacb"),
  financier: getAddress("0xc6377415Ee98A7b71161Ee963603eE52fF7750FC"),
} as const

export type DemoRole = keyof typeof DEMO_WALLETS

type CleanverseEnvelope<T> = {
  code: string
  message: string
  data: T | "" | null
}

export type APassRecord = {
  cvRecordId: string
  subTier: number
  tier: string
  status: number
  expirationTime: number
  subGroup: string
  currentKycHash: string
  group: string
  countries: string[]
}

export type APassVerification = {
  chain: string
  atoken: Address
  address: Address
  code: number
  message: string
  magickLink?: string
}

export type DepositAddressRecord = {
  address: Address
  chain: string
  txHash: string
  aPassAddress: string
  depositUSDCWallet: Address
  depositUSDTWallet: Address
}

export type FaucetReceipt = {
  chain: string
  symbol: string
  deposit_address: Address
  amount: string
  tx_hash: `0x${string}`
}

export class CleanverseApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
    readonly code?: string
  ) {
    super(message)
    this.name = "CleanverseApiError"
  }
}

function requireApiId() {
  const apiId = process.env.CLEANVERSE_API_ID?.trim()
  if (!apiId) {
    throw new CleanverseApiError(
      "Cleanverse server credentials are not configured.",
      503
    )
  }
  return apiId
}

function normalizeAddress(value: string): Address {
  if (!isAddress(value)) {
    throw new CleanverseApiError("Invalid wallet address.", 400)
  }
  return getAddress(value)
}

async function postCleanverse<T>(
  endpoint: string,
  body: Record<string, unknown>
): Promise<CleanverseEnvelope<T>> {
  const baseUrl = process.env.CLEANVERSE_API_URL?.trim() || DEFAULT_BASE_URL
  const response = await fetch(`${baseUrl}/${endpoint}`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "api-id": requireApiId(),
    },
    body: JSON.stringify(body),
    cache: "no-store",
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  })

  if (!response.ok) {
    throw new CleanverseApiError(
      `Cleanverse request failed with HTTP ${response.status}.`,
      response.status
    )
  }

  const envelope = (await response.json()) as CleanverseEnvelope<T>
  if (!envelope || typeof envelope.code !== "string") {
    throw new CleanverseApiError("Malformed Cleanverse response.", 502)
  }
  return envelope
}

export function queryAPass(address: string) {
  return postCleanverse<APassRecord>("query_apass", {
    chain: "base",
    address: normalizeAddress(address),
  })
}

export function verifyAPass(address: string) {
  return postCleanverse<APassVerification>("verify_apass", {
    chain: "base",
    atoken: CLEANVERSE_AUSDC,
    address: normalizeAddress(address),
  })
}

export function queryDepositAddress(address: string) {
  return postCleanverse<DepositAddressRecord>("query_deposit_address", {
    chain: "base",
    address: normalizeAddress(address),
  })
}

export async function getCleanverseWalletStatus(address: string) {
  const wallet = normalizeAddress(address)
  const [apass, verification, deposit] = await Promise.all([
    queryAPass(wallet),
    verifyAPass(wallet),
    queryDepositAddress(wallet),
  ])

  return {
    wallet,
    asset: CLEANVERSE_AUSDC,
    apass,
    verification,
    deposit,
    checkedAt: new Date().toISOString(),
  }
}

/**
 * Development/admin-only faucet. The destination is selected from a fixed
 * server-side role map; callers cannot supply an arbitrary wallet address.
 */
export async function faucetDemoRole(
  role: DemoRole,
  amount: string,
  symbol: "usdc" | "ausdc" = "ausdc"
) {
  if (process.env.CLEANVERSE_FAUCET_ENABLED !== "true") {
    throw new CleanverseApiError("Sandbox faucet is disabled.", 403)
  }
  if (!/^(?:[1-9]\d{0,2})(?:\.\d{1,6})?$/.test(amount)) {
    throw new CleanverseApiError("Invalid faucet amount.", 400)
  }

  const wallet = DEMO_WALLETS[role]
  const destination =
    symbol === "ausdc"
      ? wallet
      : await queryDepositAddress(wallet).then((result) => {
          if (result.code !== "0000" || !result.data) {
            throw new CleanverseApiError(
              "Cleanverse deposit address is unavailable.",
              502,
              result.code
            )
          }
          return result.data.depositUSDCWallet
        })

  return postCleanverse<FaucetReceipt>("faucet", {
    chain: "base",
    symbol,
    depositAddress: destination,
    amount,
  })
}
