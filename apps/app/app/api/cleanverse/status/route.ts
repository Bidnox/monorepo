import { isAddress } from "viem"

import {
  CleanverseApiError,
  getCleanverseWalletStatus,
} from "@/lib/server/cleanverse"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const address = new URL(request.url).searchParams.get("address")
  if (!address || !isAddress(address)) {
    return Response.json(
      { error: "A valid wallet address is required." },
      { status: 400 }
    )
  }

  try {
    return Response.json(await getCleanverseWalletStatus(address), {
      headers: { "cache-control": "no-store" },
    })
  } catch (error) {
    if (error instanceof CleanverseApiError) {
      return Response.json(
        { error: error.message, code: error.code },
        { status: error.status }
      )
    }
    return Response.json(
      { error: "Cleanverse is temporarily unavailable." },
      { status: 502 }
    )
  }
}
