import { randomBytes } from "node:crypto"

import {
  bytesToBigInt,
  createPublicClient,
  getAddress,
  http,
  isAddress,
  isHex,
  pad,
  toHex,
  type Address,
  type Hex,
} from "viem"
import { privateKeyToAccount } from "viem/accounts"
import { baseSepolia } from "viem/chains"

import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"
import {
  auctionAbi,
  complianceActions,
  gateDomain,
  permitTypes,
  registryAbi,
  type CompliancePermit,
  type PermitAction,
  type ReceivableInput,
} from "@/lib/protocol"
import { CleanverseApiError, verifyAPass } from "@/lib/server/cleanverse"
import { requireWalletSession } from "@/lib/server/wallet-session"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

type PermitRequest = {
  caller?: string
  action?: PermitAction
  subjectId?: string
  auctionId?: string
  input?: Record<string, string>
}

function publicClient() {
  return createPublicClient({
    chain: baseSepolia,
    transport: http(process.env.BASE_SEPOLIA_RPC_URL),
  })
}

function signer() {
  const key = process.env.COMPLIANCE_SIGNER_PRIVATE_KEY?.trim()
  if (!key || !/^0x[0-9a-fA-F]{64}$/.test(key)) {
    throw new Error("Compliance signer is not configured")
  }
  const account = privateKeyToAccount(key as Hex)
  if (account.address !== getAddress(BIDNOX_BASE_SEPOLIA.complianceSigner)) {
    throw new Error("Configured key does not match the deployed compliance signer")
  }
  return account
}

function parseInput(value: PermitRequest["input"]): ReceivableInput {
  if (!value || !isAddress(value.buyer) || !isHex(value.invoiceReferenceHash, { strict: true }) ||
    !isHex(value.documentHash, { strict: true }) || !isHex(value.currency, { strict: true })) {
    throw new Error("Invalid receivable input")
  }
  return {
    buyer: getAddress(value.buyer),
    invoiceReferenceHash: value.invoiceReferenceHash as Hex,
    documentHash: value.documentHash as Hex,
    currency: value.currency as Hex,
    faceValue: BigInt(value.faceValue),
    issueDate: BigInt(value.issueDate),
    dueDate: BigInt(value.dueDate),
    settlementAsset: getAddress(value.settlementAsset),
  }
}

async function requireEligible(wallet: Address) {
  const result = await verifyAPass(wallet)
  if (result.code !== "0000" || !result.data || result.data.code !== 4) {
    throw new CleanverseApiError(`Cleanverse did not approve ${wallet}.`, 403, result.code)
  }
}

function serializePermit(permit: CompliancePermit) {
  return Object.fromEntries(
    Object.entries(permit).map(([key, value]) => [key, typeof value === "bigint" ? value.toString() : value])
  )
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as PermitRequest
    if (!body.caller || !isAddress(body.caller) || !body.action || !(body.action in complianceActions) ||
      !body.subjectId || !/^0x[0-9a-fA-F]{64}$/.test(body.subjectId)) {
      return Response.json({ error: "Invalid permit request." }, { status: 400 })
    }

    const caller = await requireWalletSession(body.caller)
    const action = body.action
    const subjectId = body.subjectId as Hex

    const client = publicClient()
    const targets: Address[] = []
    if (action === "create") {
      const input = parseInput(body.input)
      if (input.settlementAsset !== getAddress(BIDNOX_BASE_SEPOLIA.aUSDC) || input.buyer === caller) {
        return Response.json({ error: "Invalid receivable participants or settlement asset." }, { status: 400 })
      }
      const fingerprint = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "computeFingerprint",
        args: [caller, input],
      })
      const expectedId = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "computeReceivableId",
        args: [fingerprint],
      })
      if (expectedId !== subjectId) return Response.json({ error: "Receivable subject mismatch." }, { status: 400 })
      targets.push(caller)
    } else if (action === "bid") {
      if (!body.auctionId || BigInt(body.auctionId) < 1n || pad(toHex(BigInt(body.auctionId)), { size: 32 }) !== subjectId) {
        return Response.json({ error: "Auction subject mismatch." }, { status: 400 })
      }
      const auction = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, abi: auctionAbi, functionName: "getAuction", args: [BigInt(body.auctionId)] })
      const block = await client.getBlock()
      if (auction.finalized || auction.revealRequested || block.timestamp >= auction.closesAt) {
        return Response.json({ error: "Auction is not accepting bids." }, { status: 409 })
      }
      targets.push(caller)
    } else {
      const receivable = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "getReceivable", args: [subjectId] })
      if (action === "confirm" && (receivable.status !== 1 || receivable.buyer !== caller)) {
        return Response.json({ error: "Only the recorded buyer can confirm this receivable." }, { status: 403 })
      }
      if (action === "fund" && (receivable.status !== 4 || receivable.financier !== caller)) {
        return Response.json({ error: "Only the winning financier can fund this receivable." }, { status: 403 })
      }
      if (action === "repay" && (receivable.status !== 5 || receivable.buyer !== caller)) {
        return Response.json({ error: "Only the recorded buyer can repay this receivable." }, { status: 403 })
      }
      if (action === "confirm") targets.push(receivable.buyer)
      if (action === "fund") targets.push(receivable.financier, receivable.seller)
      if (action === "repay") targets.push(receivable.buyer, receivable.financier)
    }

    await Promise.all([...new Set(targets)].map(requireEligible))
    const latestBlock = await client.getBlock()
    const signingAccount = signer()
    const permits = await Promise.all(targets.map(async (wallet) => {
      const permit: CompliancePermit = {
        wallet,
        action: complianceActions[action],
        subjectId,
        asset: getAddress(BIDNOX_BASE_SEPOLIA.aUSDC),
        checkedAt: latestBlock.timestamp,
        expiresAt: latestBlock.timestamp + 120n,
        nonce: bytesToBigInt(randomBytes(24)),
      }
      const signature = await signingAccount.signTypedData({ domain: gateDomain, types: permitTypes, primaryType: "CompliancePermit", message: permit })
      return { permit: serializePermit(permit), signature }
    }))

    return Response.json({ subjectId, permits }, { headers: { "cache-control": "no-store" } })
  } catch (error) {
    if (error instanceof Error && error.message === "WALLET_SESSION_REQUIRED") {
      return Response.json({ error: "Sign in with the connected wallet first." }, { status: 401 })
    }
    if (error instanceof CleanverseApiError) {
      return Response.json({ error: error.message, code: error.code }, { status: error.status })
    }
    console.error("Compliance permit request failed", error instanceof Error ? error.message : error)
    return Response.json({ error: "Unable to issue a compliance permit." }, { status: 500 })
  }
}
