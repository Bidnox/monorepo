import {
  getAddress,
  isAddress,
  isHex,
  keccak256,
  recoverMessageAddress,
  stringToHex,
  type Hex,
} from "viem"

import { invoiceUploadRequestMessage } from "@/lib/protocol"
import { CleanverseApiError, verifyAPass } from "@/lib/server/cleanverse"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

const MAX_UPLOAD_BYTES = 10 * 1024 * 1024
const MAX_REQUEST_AGE_MS = 5 * 60 * 1000
const ALLOWED_TYPES = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "image/webp",
])

export async function POST(request: Request) {
  try {
    const input = await request.formData()
    const file = input.get("file")
    const callerValue = input.get("caller")
    const issuedAtValue = input.get("issuedAt")
    const authorization = input.get("authorization")

    if (!(file instanceof File) || typeof callerValue !== "string" ||
      !isAddress(callerValue) || typeof issuedAtValue !== "string" ||
      typeof authorization !== "string" || !isHex(authorization)) {
      return Response.json({ error: "Invalid invoice upload request." }, { status: 400 })
    }
    if (file.size === 0 || file.size > MAX_UPLOAD_BYTES || !ALLOWED_TYPES.has(file.type)) {
      return Response.json({ error: "Upload a PDF, JPEG, PNG, or WebP file no larger than 10 MB." }, { status: 400 })
    }

    const caller = getAddress(callerValue)
    const issuedAt = Number(issuedAtValue)
    const age = Date.now() - issuedAt
    if (!Number.isSafeInteger(issuedAt) || age < -30_000 || age > MAX_REQUEST_AGE_MS) {
      return Response.json({ error: "Wallet upload authorization has expired." }, { status: 401 })
    }
    const recovered = await recoverMessageAddress({
      message: invoiceUploadRequestMessage(caller, issuedAt),
      signature: authorization as Hex,
    })
    if (recovered !== caller) {
      return Response.json({ error: "Wallet upload authorization does not match the caller." }, { status: 401 })
    }

    const verification = await verifyAPass(caller)
    if (verification.code !== "0000" || !verification.data || verification.data.code !== 4) {
      return Response.json({ error: "Cleanverse did not approve this uploader." }, { status: 403 })
    }

    const jwt = process.env.PINATA_JWT?.trim()
    if (!jwt) return Response.json({ error: "Pinata is not configured." }, { status: 503 })

    const pinataForm = new FormData()
    pinataForm.set("network", "private")
    pinataForm.set("file", file, file.name)
    pinataForm.set("name", `bidnox-${caller.slice(2, 10)}-${Date.now()}-${file.name}`)
    const pinataResponse = await fetch("https://uploads.pinata.cloud/v3/files", {
      method: "POST",
      headers: { authorization: `Bearer ${jwt}` },
      body: pinataForm,
      signal: AbortSignal.timeout(30_000),
    })
    const result = await pinataResponse.json() as {
      data?: { cid?: string; id?: string; size?: number; mime_type?: string }
      error?: string
    }
    const cid = result.data?.cid
    if (!pinataResponse.ok || !cid) {
      console.error("Pinata upload failed", pinataResponse.status, result.error || "missing CID")
      return Response.json({ error: "Pinata upload failed." }, { status: 502 })
    }

    const reference = `ipfs://${cid}`
    return Response.json({
      cid,
      reference,
      documentHash: keccak256(stringToHex(reference)),
      fileName: file.name,
      size: result.data?.size ?? file.size,
      network: "private",
    }, { headers: { "cache-control": "no-store" } })
  } catch (error) {
    if (error instanceof CleanverseApiError) {
      return Response.json({ error: error.message, code: error.code }, { status: error.status })
    }
    console.error("Invoice upload failed", error instanceof Error ? error.message : error)
    return Response.json({ error: "Unable to upload the invoice." }, { status: 500 })
  }
}
