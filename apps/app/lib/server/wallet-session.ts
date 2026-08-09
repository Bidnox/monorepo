import "server-only"

import { createHmac, randomBytes, timingSafeEqual } from "node:crypto"
import { cookies } from "next/headers"
import { getAddress, isAddress, recoverMessageAddress, type Address, type Hex } from "viem"

import { walletSessionMessage } from "@/lib/protocol"

const CHALLENGE_COOKIE = "bidnox_wallet_challenge"
const SESSION_COOKIE = "bidnox_wallet_session"
const CHALLENGE_TTL_SECONDS = 5 * 60
const SESSION_TTL_SECONDS = 12 * 60 * 60

type SignedPayload = {
  address: Address
  nonce: string
  expiresAt: number
}

function secret() {
  const value = process.env.WALLET_SESSION_SECRET?.trim() ||
    process.env.COMPLIANCE_SIGNER_PRIVATE_KEY?.trim()
  if (!value || value.length < 32) throw new Error("Wallet sessions are not configured")
  return value
}

function encode(payload: SignedPayload) {
  const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url")
  const signature = createHmac("sha256", secret()).update(encoded).digest("base64url")
  return `${encoded}.${signature}`
}

function decode(value?: string): SignedPayload | undefined {
  if (!value) return undefined
  const [encoded, signature] = value.split(".")
  if (!encoded || !signature) return undefined
  const expected = createHmac("sha256", secret()).update(encoded).digest()
  const actual = Buffer.from(signature, "base64url")
  if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) return undefined
  try {
    const payload = JSON.parse(Buffer.from(encoded, "base64url").toString()) as SignedPayload
    if (!isAddress(payload.address) || !payload.nonce || payload.expiresAt <= Date.now()) return undefined
    return { ...payload, address: getAddress(payload.address) }
  } catch {
    return undefined
  }
}

const cookieOptions = {
  httpOnly: true,
  sameSite: "strict" as const,
  secure: process.env.NODE_ENV === "production",
  path: "/",
}

export async function createWalletChallenge(address: Address) {
  const payload: SignedPayload = {
    address: getAddress(address),
    nonce: randomBytes(16).toString("hex"),
    expiresAt: Date.now() + CHALLENGE_TTL_SECONDS * 1000,
  }
  const store = await cookies()
  store.set(CHALLENGE_COOKIE, encode(payload), {
    ...cookieOptions,
    maxAge: CHALLENGE_TTL_SECONDS,
  })
  return walletSessionMessage(payload.address, payload.nonce, payload.expiresAt)
}

export async function verifyWalletChallenge(address: Address, signature: Hex) {
  const store = await cookies()
  const challenge = decode(store.get(CHALLENGE_COOKIE)?.value)
  const caller = getAddress(address)
  if (!challenge || challenge.address !== caller) return false
  const recovered = await recoverMessageAddress({
    message: walletSessionMessage(caller, challenge.nonce, challenge.expiresAt),
    signature,
  })
  if (recovered !== caller) return false

  const session: SignedPayload = {
    address: caller,
    nonce: randomBytes(16).toString("hex"),
    expiresAt: Date.now() + SESSION_TTL_SECONDS * 1000,
  }
  store.set(SESSION_COOKIE, encode(session), {
    ...cookieOptions,
    maxAge: SESSION_TTL_SECONDS,
  })
  store.delete(CHALLENGE_COOKIE)
  return true
}

export async function walletSession(address?: string) {
  if (!address || !isAddress(address)) return undefined
  const store = await cookies()
  const session = decode(store.get(SESSION_COOKIE)?.value)
  const caller = getAddress(address)
  return session?.address === caller ? session : undefined
}

export async function requireWalletSession(address?: string) {
  const session = await walletSession(address)
  if (!session) throw new Error("WALLET_SESSION_REQUIRED")
  return session.address
}
