import { createPublicClient, getAddress, http, isAddress, isHex, keccak256, stringToHex, type Hex } from "viem"
import { baseSepolia } from "viem/chains"

import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"
import { registryAbi } from "@/lib/protocol"
import { requireWalletSession } from "@/lib/server/wallet-session"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

type PinataFile = { cid?: string }

async function findCid(documentHash: Hex) {
  const jwt = process.env.PINATA_JWT?.trim()
  if (!jwt) return undefined
  let pageToken: string | undefined
  for (let page = 0; page < 5; page += 1) {
    const url = new URL("https://api.pinata.cloud/v3/files/public")
    url.searchParams.set("limit", "100")
    if (pageToken) url.searchParams.set("pageToken", pageToken)
    const response = await fetch(url, {
      headers: { authorization: `Bearer ${jwt}` },
      cache: "no-store",
      signal: AbortSignal.timeout(15_000),
    })
    if (!response.ok) return undefined
    const result = await response.json() as {
      data?: { files?: PinataFile[]; next_page_token?: string }
    }
    const match = result.data?.files?.find((file) =>
      file.cid && keccak256(stringToHex(`ipfs://${file.cid}`)) === documentHash
    )
    if (match?.cid) return match.cid
    pageToken = result.data?.next_page_token
    if (!pageToken) break
  }
  return undefined
}

export async function GET(request: Request) {
  try {
    const params = new URL(request.url).searchParams
    const callerValue = params.get("caller") || undefined
    const receivableId = params.get("receivableId")
    if (!callerValue || !isAddress(callerValue) || !receivableId || !isHex(receivableId) || !/^0x[0-9a-fA-F]{64}$/.test(receivableId)) {
      return Response.json({ error: "Invalid document request." }, { status: 400 })
    }
    const caller = await requireWalletSession(callerValue)
    const client = createPublicClient({ chain: baseSepolia, transport: http(process.env.BASE_SEPOLIA_RPC_URL) })
    const receivable = await client.readContract({
      address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
      abi: registryAbi,
      functionName: "getReceivable",
      args: [receivableId as Hex],
    })
    const participants = [receivable.seller, receivable.buyer, receivable.financier].map((value) => value.toLowerCase())
    if (!participants.includes(getAddress(caller).toLowerCase())) {
      return Response.json({ error: "Only receivable participants can resolve the IPFS reference." }, { status: 403 })
    }
    const cid = await findCid(receivable.documentHash)
    if (!cid) return Response.json({ error: "IPFS reference not found." }, { status: 404 })
    const gatewayUrl = `https://gateway.pinata.cloud/ipfs/${cid}`
    return Response.json(
      { cid, reference: `ipfs://${cid}`, gatewayUrl },
      { headers: { "cache-control": "no-store" } }
    )
  } catch (error) {
    if (error instanceof Error && error.message === "WALLET_SESSION_REQUIRED") {
      return Response.json({ error: "Sign in with the connected wallet first." }, { status: 401 })
    }
    return Response.json({ error: "Unable to resolve the IPFS reference." }, { status: 500 })
  }
}
