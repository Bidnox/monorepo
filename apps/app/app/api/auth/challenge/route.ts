import { getAddress, isAddress } from "viem"

import { createWalletChallenge } from "@/lib/server/wallet-session"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

export async function POST(request: Request) {
  const body = await request.json().catch(() => ({})) as { address?: string }
  if (!body.address || !isAddress(body.address)) {
    return Response.json({ error: "A valid wallet address is required." }, { status: 400 })
  }
  const address = getAddress(body.address)
  const message = await createWalletChallenge(address)
  return Response.json({ address, message }, { headers: { "cache-control": "no-store" } })
}
