import {
  CleanverseApiError,
  getCleanverseWalletStatus,
} from "@/lib/server/cleanverse"
import { getReceivableById } from "@/lib/server/bidnox"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const receivableId = new URL(request.url).searchParams.get("receivableId")
  if (!receivableId || !/^0x[0-9a-fA-F]{64}$/.test(receivableId)) {
    return Response.json(
      { error: "A valid receivable ID is required." },
      { status: 400 }
    )
  }

  try {
    const receivable = await getReceivableById(receivableId)
    if (!receivable) {
      return Response.json({ error: "Receivable not found." }, { status: 404 })
    }
    const participants = await Promise.all(
      [receivable.seller, receivable.buyer].map(getCleanverseWalletStatus)
    )
    return Response.json({
      receivableId,
      eligible: participants.every(
        ({ verification }) =>
          verification.code === "0000" &&
          verification.data &&
          verification.data.code === 4
      ),
      checkedAt: new Date().toISOString(),
    }, {
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
