import { getAddress, isAddress, isHex, type Hex } from "viem"

import { verifyWalletChallenge, walletSession } from "@/lib/server/wallet-session"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

export async function GET(request: Request) {
  try {
    const address = new URL(request.url).searchParams.get("address") || undefined
    const session = await walletSession(address)
    return session
      ? Response.json({ authenticated: true, address: session.address }, { headers: { "cache-control": "no-store" } })
      : Response.json({ authenticated: false }, { status: 401, headers: { "cache-control": "no-store" } })
  } catch {
    return Response.json(
      { error: "Wallet session service is unavailable." },
      { status: 503, headers: { "cache-control": "no-store" } }
    )
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json().catch(() => ({})) as { address?: string; signature?: string }
    if (!body.address || !isAddress(body.address) || !body.signature || !isHex(body.signature)) {
      return Response.json({ error: "Invalid wallet authorization." }, { status: 400 })
    }
    const address = getAddress(body.address)
    const verified = await verifyWalletChallenge(address, body.signature as Hex)
    return verified
      ? Response.json({ authenticated: true, address }, { headers: { "cache-control": "no-store" } })
      : Response.json({ error: "Wallet authorization could not be verified." }, { status: 401 })
  } catch {
    return Response.json(
      { error: "Wallet session service is unavailable." },
      { status: 503, headers: { "cache-control": "no-store" } }
    )
  }
}
