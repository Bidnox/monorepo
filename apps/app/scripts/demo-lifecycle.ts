import { Lightning } from "@inco/lightning-js/lite"
import { handleTypes, type HexString } from "@inco/lightning-js"
import {
  bytesToHex,
  createPublicClient,
  createWalletClient,
  getAddress,
  http,
  keccak256,
  pad,
  stringToHex,
  toHex,
  type Abi,
  type Address,
  type Hex,
} from "viem"
import { privateKeyToAccount } from "viem/accounts"
import { baseSepolia } from "viem/chains"

import auctionArtifact from "../../../contracts/out/ConfidentialAuction.sol/ConfidentialAuction.json"
import gateArtifact from "../../../contracts/out/ComplianceGate.sol/ComplianceGate.json"
import registryArtifact from "../../../contracts/out/ReceivableRegistry.sol/ReceivableRegistry.json"

const CHAIN_ID = 84_532
const AUSDC = getAddress("0xaC0893567D43C3E7e6e35a72803df05416C1f20D")
const GATE = getAddress("0x12badb8fd1828AB70Ea5FD4F5142Bc8c9e8f537d")
const REGISTRY = getAddress("0xCad5d39Dc42757969323608a9207B283dbDE3b37")
const AUCTION = getAddress("0xDA6F7Fe360f7700d6E0d867bDC7f51C048E33c82")

const SELLER = getAddress("0xf653B0f43b0f920E590Bf3745997B332d916Aacb")
const BUYER = getAddress("0x376b7271dD22D14D82Ef594324ea14e7670ed5b2")
const FINANCIER = getAddress("0xc6377415Ee98A7b71161Ee963603eE52fF7750FC")

const SECOND_LENDER_KEY = keccak256(stringToHex("BIDNOX_SECOND_LENDER_2026"))

const registryAbi = registryArtifact.abi as Abi
const auctionAbi = auctionArtifact.abi as Abi
const gateAbi = gateArtifact.abi as Abi
const erc20Abi = [
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
] as const
const getFeeAbi = [
  {
    type: "function",
    name: "getFee",
    stateMutability: "pure",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
] as const

const actions = {
  create: keccak256(stringToHex("BIDNOX_CREATE_RECEIVABLE")),
  confirm: keccak256(stringToHex("BIDNOX_CONFIRM_RECEIVABLE")),
  bid: keccak256(stringToHex("BIDNOX_BID")),
  settle: keccak256(stringToHex("BIDNOX_SETTLE")),
  repay: keccak256(stringToHex("BIDNOX_REPAY")),
} as const

const permitTypes = {
  CompliancePermit: [
    { name: "wallet", type: "address" },
    { name: "action", type: "bytes32" },
    { name: "subjectId", type: "bytes32" },
    { name: "asset", type: "address" },
    { name: "checkedAt", type: "uint256" },
    { name: "expiresAt", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
} as const

const buyerConfirmationTypes = {
  BuyerConfirmation: [
    { name: "receivableId", type: "bytes32" },
    { name: "seller", type: "address" },
    { name: "buyer", type: "address" },
    { name: "faceValue", type: "uint256" },
    { name: "dueDate", type: "uint64" },
    { name: "fingerprint", type: "bytes32" },
  ],
} as const

function required(name: string): string {
  const value = process.env[name]?.trim()
  if (!value) throw new Error(`${name} is required`)
  return value
}

function privateKey(name: string): Hex {
  const value = required(name)
  if (!/^0x[0-9a-fA-F]{64}$/.test(value)) throw new Error(`${name} is invalid`)
  return value as Hex
}

async function main() {
  const rpcUrl = required("BASE_SEPOLIA_RPC_URL")
  const apiId = required("CLEANVERSE_API_ID")
  const seller = privateKeyToAccount(privateKey("SELLER_PRIVATE_KEY"))
  const buyer = privateKeyToAccount(privateKey("BUYER_PRIVATE_KEY"))
  const financier = privateKeyToAccount(privateKey("FINANCIER_PRIVATE_KEY"))
  const secondLender = privateKeyToAccount(SECOND_LENDER_KEY)

  if (seller.address !== SELLER || buyer.address !== BUYER || financier.address !== FINANCIER) {
    throw new Error("Demo private keys do not match the configured role addresses")
  }

  const publicClient = createPublicClient({ chain: baseSepolia, transport: http(rpcUrl) })
  const wallets = {
    seller: createWalletClient({ account: seller, chain: baseSepolia, transport: http(rpcUrl) }),
    buyer: createWalletClient({ account: buyer, chain: baseSepolia, transport: http(rpcUrl) }),
    financier: createWalletClient({ account: financier, chain: baseSepolia, transport: http(rpcUrl) }),
    secondLender: createWalletClient({ account: secondLender, chain: baseSepolia, transport: http(rpcUrl) }),
  }

  const zap = await Lightning.baseSepoliaTestnet({ hostChainRpcUrls: [rpcUrl] })
  const fee = await publicClient.readContract({
    address: zap.executorAddress as Address,
    abi: getFeeAbi,
    functionName: "getFee",
  })

  const evidence: Record<string, unknown> = {
    network: "base-sepolia",
    chainId: CHAIN_ID,
    contracts: { gate: GATE, registry: REGISTRY, auction: AUCTION, aUSDC: AUSDC },
    roles: { seller: SELLER, buyer: BUYER, financier: FINANCIER, secondLender: secondLender.address },
    transactions: {},
    cleanverseChecks: [],
  }
  const transactions = evidence.transactions as Record<string, Hex>
  const checks = evidence.cleanverseChecks as Array<Record<string, unknown>>

  async function wait(hash: Hex) {
    const receipt = await publicClient.waitForTransactionReceipt({ hash, confirmations: 1 })
    if (receipt.status !== "success") throw new Error(`Transaction reverted: ${hash}`)
    await new Promise((resolve) => setTimeout(resolve, 2_500))
    return hash
  }

  async function readReceivable(receivableId: Hex) {
    let lastError: unknown
    for (let attempt = 0; attempt < 6; attempt += 1) {
      try {
        return await publicClient.readContract({
          address: REGISTRY,
          abi: registryAbi,
          functionName: "getReceivable",
          args: [receivableId],
        }) as unknown as {
          seller: Address
          buyer: Address
          faceValue: bigint
          dueDate: bigint
          fingerprint: Hex
        }
      } catch (error) {
        lastError = error
        await new Promise((resolve) => setTimeout(resolve, 1_500))
      }
    }
    throw lastError
  }

  async function waitForStatus(receivableId: Hex, expected: number) {
    for (let attempt = 0; attempt < 20; attempt += 1) {
      const status = await publicClient.readContract({
        address: REGISTRY,
        abi: registryAbi,
        functionName: "statusOf",
        args: [receivableId],
      }) as number
      if (Number(status) === expected) return
      await new Promise((resolve) => setTimeout(resolve, 1_000))
    }
    throw new Error(`RPC state did not reach receivable status ${expected}`)
  }

  async function cleanverseCheck(role: string, address: Address, action: string) {
    const response = await fetch("https://uatapi.cleanverse.com/api/cooperate/verify_apass", {
      method: "POST",
      headers: { "content-type": "application/json", "api-id": apiId },
      body: JSON.stringify({ chain: "base", atoken: AUSDC, address }),
    }).then((result) => result.json()) as {
      code: string
      message: string
      data?: { code?: number; message?: string }
    }
    if (response.code !== "0000" || response.data?.code !== 4) {
      throw new Error(`Cleanverse rejected ${role} for ${action}: ${response.message}`)
    }
    checks.push({ role, address, action, result: response.data.code, checkedAt: new Date().toISOString() })
  }

  let nonce = BigInt(Date.now()) * 100n
  async function permit(wallet: Address, action: Hex, subjectId: Hex) {
    const latestBlock = await publicClient.getBlock()
    const message = {
      wallet,
      action,
      subjectId,
      asset: AUSDC,
      checkedAt: latestBlock.timestamp,
      expiresAt: latestBlock.timestamp + 120n,
      nonce: nonce++,
    }
    const signature = await buyer.signTypedData({
      domain: { name: "Bidnox ComplianceGate", version: "1", chainId: CHAIN_ID, verifyingContract: GATE },
      types: permitTypes,
      primaryType: "CompliancePermit",
      message,
    })
    return { message, signature }
  }

  const block = await publicClient.getBlock()
  const issueDate = block.timestamp
  const dueDate = issueDate + 30n * 24n * 60n * 60n
  const faceValue = 2_000_000n
  const invoiceReferenceHash = keccak256(stringToHex(`BIDNOX-LIVE-${block.number}`))
  const documentHash = keccak256(stringToHex("private-demo-invoice-v1"))
  const currency = pad(stringToHex("USD"), { size: 32, dir: "right" })
  const input = {
    buyer: BUYER,
    invoiceReferenceHash,
    documentHash,
    currency,
    faceValue,
    issueDate,
    dueDate,
    settlementAsset: AUSDC,
  }

  const fingerprint = await publicClient.readContract({
    address: REGISTRY,
    abi: registryAbi,
    functionName: "computeFingerprint",
    args: [SELLER, input],
  }) as Hex
  const computedReceivableId = await publicClient.readContract({
    address: REGISTRY,
    abi: registryAbi,
    functionName: "computeReceivableId",
    args: [fingerprint],
  }) as Hex
  const resumeReceivableId = process.env.RESUME_RECEIVABLE_ID as Hex | undefined
  const receivableId = resumeReceivableId ?? computedReceivableId
  evidence.receivableId = receivableId
  evidence.faceValue = faceValue.toString()

  if (!resumeReceivableId) {
    await cleanverseCheck("seller", SELLER, "create")
    const createPermit = await permit(SELLER, actions.create, receivableId)
    transactions.createReceivable = await wait(await wallets.seller.writeContract({
      address: REGISTRY,
      abi: registryAbi,
      functionName: "createReceivable",
      args: [input, createPermit.message, createPermit.signature],
    }))
  } else {
    transactions.createReceivable = process.env.RESUME_CREATE_TX as Hex
  }

  const receivable = await readReceivable(receivableId)
  if (process.env.RESUME_CONFIRMED !== "true") {
    const buyerSignature = await buyer.signTypedData({
      domain: { name: "Bidnox ReceivableRegistry", version: "1", chainId: CHAIN_ID, verifyingContract: REGISTRY },
      types: buyerConfirmationTypes,
      primaryType: "BuyerConfirmation",
      message: {
        receivableId,
        seller: receivable.seller,
        buyer: receivable.buyer,
        faceValue: receivable.faceValue,
        dueDate: receivable.dueDate,
        fingerprint: receivable.fingerprint,
      },
    })
    await cleanverseCheck("buyer", BUYER, "confirm")
    const confirmPermit = await permit(BUYER, actions.confirm, receivableId)
    transactions.confirmReceivable = await wait(await wallets.buyer.writeContract({
      address: REGISTRY,
      abi: registryAbi,
      functionName: "confirmReceivable",
      args: [receivableId, buyerSignature, confirmPermit.message, confirmPermit.signature],
    }))
    await waitForStatus(receivableId, 2)
  } else if (process.env.RESUME_CONFIRM_TX) {
    transactions.confirmReceivable = process.env.RESUME_CONFIRM_TX as Hex
  }

  const resumedAuctionId = process.env.RESUME_AUCTION_ID ? BigInt(process.env.RESUME_AUCTION_ID) : undefined
  let auctionId: bigint
  let closesAt: bigint
  if (resumedAuctionId) {
    auctionId = resumedAuctionId
    const existingAuction = await publicClient.readContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "getAuction",
      args: [auctionId],
    }) as unknown as { closesAt: bigint }
    closesAt = existingAuction.closesAt
  } else {
    const auctionBlock = await publicClient.getBlock()
    closesAt = auctionBlock.timestamp + 90n
    const previousAuctionCount = await publicClient.readContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "auctionCount",
    }) as bigint
    transactions.createAuction = await wait(await wallets.seller.writeContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "createAuction",
      args: [receivableId, closesAt, 1_500_000n],
    }))
    auctionId = previousAuctionCount
    for (let attempt = 0; attempt < 12 && auctionId <= previousAuctionCount; attempt += 1) {
      auctionId = await publicClient.readContract({
        address: AUCTION,
        abi: auctionAbi,
        functionName: "auctionCount",
      }) as bigint
      if (auctionId <= previousAuctionCount) await new Promise((resolve) => setTimeout(resolve, 1_000))
    }
    if (auctionId <= previousAuctionCount) throw new Error("Auction creation was mined but RPC state did not advance")
  }
  evidence.auctionId = auctionId.toString()

  async function submitBid(
    role: string,
    address: Address,
    amount: bigint,
    wallet: typeof wallets.financier
  ) {
    await cleanverseCheck(role, address, "bid")
    const bidPermit = await permit(address, actions.bid, pad(toHex(auctionId), { size: 32 }))
    const encryptedBid = await zap.encrypt(amount, {
      accountAddress: address,
      dappAddress: AUCTION,
      handleType: handleTypes.euint256,
    })
    const permitStatus = await publicClient.readContract({
      address: GATE,
      abi: gateAbi,
      functionName: "checkPermit",
      args: [
        bidPermit.message,
        bidPermit.signature,
        address,
        actions.bid,
        pad(toHex(auctionId), { size: 32 }),
      ],
    }) as number
    if (Number(permitStatus) !== 0) {
      throw new Error(`Bid permit preflight failed with status ${permitStatus}`)
    }
    return wait(await wallet.writeContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "submitBid",
      args: [auctionId, encryptedBid, bidPermit.message, bidPermit.signature],
      value: fee,
      gas: 2_500_000n,
    }))
  }

  if (process.env.RESUME_BIDS !== "true") {
    transactions.losingEncryptedBid = await submitBid(
      "secondaryLender",
      secondLender.address,
      1_600_000n,
      wallets.secondLender
    )
    transactions.winningEncryptedBid = await submitBid(
      "financier",
      FINANCIER,
      1_800_000n,
      wallets.financier
    )
  }

  while ((await publicClient.getBlock()).timestamp < closesAt) {
    await new Promise((resolve) => setTimeout(resolve, 2_000))
  }
  const beforeClose = await publicClient.readContract({
    address: AUCTION,
    abi: auctionAbi,
    functionName: "getAuction",
    args: [auctionId],
  }) as unknown as { revealRequested: boolean }
  if (!beforeClose.revealRequested) {
    transactions.closeAuction = await wait(await wallets.financier.writeContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "closeAuction",
      args: [auctionId],
    }))
  }

  if (process.env.RESUME_FINALIZED !== "true") {
    const auction = await publicClient.readContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "getAuction",
      args: [auctionId],
    }) as unknown as { highestBid: Hex; winningBidderIndex: Hex }
    const handles = [
      auction.highestBid as HexString,
      auction.winningBidderIndex as HexString,
    ]
    let revealed: Awaited<ReturnType<typeof zap.attestedReveal>> | undefined
    let revealError: unknown
    for (let attempt = 0; attempt < 12 && !revealed; attempt += 1) {
      try {
        revealed = await zap.attestedReveal(handles, {
          backoffConfig: { maxRetries: 8, baseDelayInMs: 500, backoffFactor: 1.35 },
        })
      } catch (error) {
        revealError = error
        await new Promise((resolve) => setTimeout(resolve, 5_000))
      }
    }
    if (!revealed) throw revealError
    const formatted = revealed.map((result) => ({
      value: result.plaintext.value as bigint,
      attestation: {
        handle: result.handle as Hex,
        value: pad(toHex(result.plaintext.value as bigint), { size: 32 }),
      },
      signatures: result.covalidatorSignatures.map((signature) => bytesToHex(signature)),
    }))
    evidence.reveal = {
      highestBid: formatted[0].value.toString(),
      winningIndex: formatted[1].value.toString(),
      losingBidRevealed: false,
    }
    transactions.finalizeAuction = await wait(await wallets.financier.writeContract({
      address: AUCTION,
      abi: auctionAbi,
      functionName: "finalizeAuction",
      args: [
        auctionId,
        formatted[0].value,
        formatted[1].value,
        formatted[0].attestation,
        formatted[0].signatures,
        formatted[1].attestation,
        formatted[1].signatures,
      ],
    }))
  } else {
    evidence.reveal = { highestBid: "1800000", winningIndex: "1", losingBidRevealed: false }
  }

  transactions.approveFunding = await wait(await wallets.financier.writeContract({
    address: AUSDC,
    abi: erc20Abi,
    functionName: "approve",
    args: [REGISTRY, 1_800_000n],
  }))
  await Promise.all([
    cleanverseCheck("financier", FINANCIER, "settle"),
    cleanverseCheck("seller", SELLER, "settle"),
  ])
  const financierSettle = await permit(FINANCIER, actions.settle, receivableId)
  const sellerSettle = await permit(SELLER, actions.settle, receivableId)
  transactions.fundReceivable = await wait(await wallets.financier.writeContract({
    address: REGISTRY,
    abi: registryAbi,
    functionName: "fundReceivable",
    args: [
      receivableId,
      financierSettle.message,
      financierSettle.signature,
      sellerSettle.message,
      sellerSettle.signature,
    ],
  }))

  transactions.approveRepayment = await wait(await wallets.buyer.writeContract({
    address: AUSDC,
    abi: erc20Abi,
    functionName: "approve",
    args: [REGISTRY, faceValue],
  }))
  await Promise.all([
    cleanverseCheck("buyer", BUYER, "repay"),
    cleanverseCheck("financier", FINANCIER, "repay"),
  ])
  const buyerRepay = await permit(BUYER, actions.repay, receivableId)
  const financierRepay = await permit(FINANCIER, actions.repay, receivableId)
  transactions.repayReceivable = await wait(await wallets.buyer.writeContract({
    address: REGISTRY,
    abi: registryAbi,
    functionName: "repayReceivable",
    args: [
      receivableId,
      buyerRepay.message,
      buyerRepay.signature,
      financierRepay.message,
      financierRepay.signature,
    ],
  }))

  const [sellerBalance, buyerBalance, financierBalance, status] = await Promise.all([
    publicClient.readContract({ address: AUSDC, abi: erc20Abi, functionName: "balanceOf", args: [SELLER] }),
    publicClient.readContract({ address: AUSDC, abi: erc20Abi, functionName: "balanceOf", args: [BUYER] }),
    publicClient.readContract({ address: AUSDC, abi: erc20Abi, functionName: "balanceOf", args: [FINANCIER] }),
    publicClient.readContract({ address: REGISTRY, abi: registryAbi, functionName: "statusOf", args: [receivableId] }),
  ])
  evidence.finalState = {
    status: Number(status),
    statusLabel: Number(status) === 6 ? "Repaid" : "Unexpected",
    balances: {
      seller: sellerBalance.toString(),
      buyer: buyerBalance.toString(),
      financier: financierBalance.toString(),
    },
  }

  console.log(JSON.stringify(evidence, null, 2))
}

await main().catch((error: unknown) => {
  const details: string[] = []
  let current: unknown = error
  for (let depth = 0; depth < 6 && current && typeof current === "object"; depth += 1) {
    const record = current as Record<string, unknown>
    for (const key of ["errorName", "data", "reason", "message"] as const) {
      const value = record[key]
      if (
        (typeof value === "string" || typeof value === "number") &&
        !String(value).includes("http") &&
        !details.includes(`${key}=${value}`)
      ) {
        details.push(`${key}=${value}`)
      }
    }
    current = record.cause
  }
  const message =
    error && typeof error === "object" && "shortMessage" in error
      ? String(error.shortMessage)
      : error instanceof Error
        ? error.message
        : "Unknown lifecycle failure"
  console.error(`Lifecycle failed: ${message}${details.length ? ` (${details.join(", ")})` : ""}`)
  process.exit(1)
})
