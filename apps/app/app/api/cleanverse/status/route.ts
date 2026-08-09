import {
  CleanverseApiError,
  verifyAPass,
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
    const candidates = [
      { role: "Seller", wallet: receivable.seller },
      { role: "Buyer", wallet: receivable.buyer },
      ...receivable.sealedBids.map((bid, index) => ({ role: `Lender ${index + 1}`, wallet: bid.bidder })),
      ...(receivable.financier ? [{ role: "Winning financier", wallet: receivable.financier }] : []),
    ]
    const unique = candidates.filter((candidate, index) =>
      candidates.findIndex((item) => item.wallet.toLowerCase() === candidate.wallet.toLowerCase()) === index
    )
    const participants = await Promise.all(unique.map(async ({ role, wallet }) => ({
      role, wallet, verification: await verifyAPass(wallet),
    })))
    return Response.json({
      receivableId,
      eligible: participants.every(
        ({ verification }) =>
          verification.code === "0000" &&
          verification.data &&
          verification.data.code === 4
      ),
      participants: participants.map(({ role, wallet, verification }) => ({
        role,
        wallet,
        verified: verification.code === "0000" && Boolean(verification.data && verification.data.code === 4),
      })),
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
