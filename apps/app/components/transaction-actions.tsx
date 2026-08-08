"use client"

import * as React from "react"
import { useRouter } from "next/navigation"
import {
  getAddress,
  keccak256,
  pad,
  parseUnits,
  stringToHex,
  toHex,
  type Hex,
} from "viem"
import {
  useAccount,
  usePublicClient,
  useSignMessage,
  useSignTypedData,
  useWriteContract,
} from "wagmi"

import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { toastManager } from "@/components/ui/toast"
import type { Receivable } from "@/lib/bidnox"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"
import {
  auctionAbi,
  buyerConfirmationTypes,
  DEMO_DOCUMENT_HASH,
  deserializePermit,
  erc20Abi,
  incoExecutorAbi,
  invoiceUploadRequestMessage,
  permitRequestMessage,
  registryAbi,
  registryDomain,
  type PermitAction,
  type ReceivableInput,
} from "@/lib/protocol"

type IssuedPermit = { permit: Record<string, string>; signature: Hex }

const DEMO_MODE = process.env.NEXT_PUBLIC_DEMO_MODE === "true"
const DEMO_BUYER = "0x376b7271dD22D14D82Ef594324ea14e7670ed5b2"

function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message.split("\n")[0]
  return "The wallet action failed."
}

function serializeInput(input: ReceivableInput) {
  return Object.fromEntries(
    Object.entries(input).map(([key, value]) => [key, typeof value === "bigint" ? value.toString() : value])
  )
}

function useTransactions() {
  const { address } = useAccount()
  const client = usePublicClient()
  const { signMessageAsync } = useSignMessage()
  const { signTypedDataAsync } = useSignTypedData()
  const { writeContractAsync } = useWriteContract()

  async function issuePermits(action: PermitAction, subjectId: Hex, extra: Record<string, unknown> = {}) {
    if (!address) throw new Error("Connect a wallet first.")
    const issuedAt = Date.now()
    const authorization = await signMessageAsync({ message: permitRequestMessage(address, action, subjectId, issuedAt) })
    const response = await fetch("/api/compliance/permit", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ caller: address, action, subjectId, issuedAt, authorization, ...extra }),
    })
    const result = await response.json() as { error?: string; permits?: IssuedPermit[] }
    if (!response.ok || !result.permits) throw new Error(result.error || "Compliance permit request failed.")
    return result.permits.map((item) => ({ permit: deserializePermit(item.permit), signature: item.signature }))
  }

  async function send(parameters: Record<string, unknown>) {
    if (!client) throw new Error("Base Sepolia client is unavailable.")
    const hash = await writeContractAsync(
      parameters as Parameters<typeof writeContractAsync>[0]
    )
    const receipt = await client.waitForTransactionReceipt({ hash })
    if (receipt.status !== "success") throw new Error("Transaction reverted.")
    return hash
  }

  return {
    address,
    client,
    issuePermits,
    send,
    signMessageAsync,
    signTypedDataAsync,
  }
}

function ActionStatus({ message, hash }: { message?: string; hash?: Hex }) {
  if (!message && !hash) return null
  return (
    <p className="mt-3 break-words text-xs text-muted-foreground" role="status">
      {message}
      {hash ? (
        <> · <a className="underline" href={`${BIDNOX_BASE_SEPOLIA.explorer}/tx/${hash}`} target="_blank" rel="noreferrer">View transaction</a></>
      ) : null}
    </p>
  )
}

export function CreateReceivableForm() {
  const router = useRouter()
  const { address, client, issuePermits, send, signMessageAsync } = useTransactions()
  const formRef = React.useRef<HTMLFormElement>(null)
  const [open, setOpen] = React.useState(false)
  const [busy, setBusy] = React.useState(false)
  const [message, setMessage] = React.useState<string>()

  const fillDemoData = React.useCallback(() => {
    const form = formRef.current
    if (!form) return
    const set = (name: string, value: string) => {
      const field = form.elements.namedItem(name)
      if (field instanceof HTMLInputElement) field.value = value
    }
    set("buyer", DEMO_BUYER)
    set("reference", `BIDNOX-DEMO-${Date.now()}`)
    set("faceValue", "2")
    set(
      "dueDate",
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
        .toISOString()
        .slice(0, 10)
    )
  }, [])

  React.useEffect(() => {
    if (open && DEMO_MODE) fillDemoData()
  }, [fillDemoData, open])

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!address || !client) return setMessage("Connect the seller wallet first.")
    const data = new FormData(event.currentTarget)
    try {
      setBusy(true)
      setMessage("Preparing receivable and checking Cleanverse eligibility…")
      const buyer = getAddress(String(data.get("buyer")))
      const latest = await client.getBlock()
      const dueDate = BigInt(Math.floor(new Date(String(data.get("dueDate"))).getTime() / 1000))
      let documentHash = DEMO_DOCUMENT_HASH
      if (!DEMO_MODE) {
        const file = data.get("document")
        if (!(file instanceof File) || file.size === 0) {
          throw new Error("Choose an invoice document to upload.")
        }
        setMessage("Authorize the private Pinata invoice upload…")
        const issuedAt = Date.now()
        const authorization = await signMessageAsync({
          message: invoiceUploadRequestMessage(address, issuedAt),
        })
        const upload = new FormData()
        upload.set("file", file)
        upload.set("caller", address)
        upload.set("issuedAt", issuedAt.toString())
        upload.set("authorization", authorization)
        const response = await fetch("/api/pinata/upload", {
          method: "POST",
          body: upload,
        })
        const result = await response.json() as {
          documentHash?: Hex
          error?: string
        }
        if (!response.ok || !result.documentHash) {
          throw new Error(result.error || "Invoice upload failed.")
        }
        documentHash = result.documentHash
      }
      const input: ReceivableInput = {
        buyer,
        invoiceReferenceHash: keccak256(stringToHex(String(data.get("reference")))),
        documentHash,
        currency: pad(stringToHex("USD"), { size: 32, dir: "right" }),
        faceValue: parseUnits(String(data.get("faceValue")), 6),
        issueDate: latest.timestamp,
        dueDate,
        settlementAsset: getAddress(BIDNOX_BASE_SEPOLIA.aUSDC),
      }
      const fingerprint = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "computeFingerprint", args: [address, input] })
      const receivableId = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "computeReceivableId", args: [fingerprint] })
      const [issued] = await issuePermits("create", receivableId, { input: serializeInput(input) })
      setMessage("Confirm creation in your wallet…")
      const hash = await send({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "createReceivable", args: [input, issued.permit, issued.signature] })
      toastManager.add({ title: "Receivable created", type: "success" })
      router.push(`/receivables/${receivableId}`)
      router.refresh()
      setMessage(`Created in ${hash.slice(0, 10)}…`)
    } catch (error) {
      setMessage(errorMessage(error))
      toastManager.add({ title: "Creation failed", description: errorMessage(error), type: "error" })
    } finally { setBusy(false) }
  }

  return (
    <section className="rounded-xl border p-4">
      <div className="flex items-center justify-between gap-4">
        <div><div className="flex items-center gap-2"><h2 className="text-sm font-medium">Seller workspace</h2>{DEMO_MODE ? <span className="rounded-full border px-2 py-0.5 text-[10px] text-muted-foreground">Demo mode</span> : null}</div><p className="mt-1 text-xs text-muted-foreground">Register a real Base Sepolia receivable settled in aUSDC.</p></div>
        <Button onClick={() => setOpen((value) => !value)} variant={open ? "secondary" : "default"}>{open ? "Close" : "Create receivable"}</Button>
      </div>
      {open ? (
        <form ref={formRef} className="mt-5 grid gap-4 sm:grid-cols-2" onSubmit={submit}>
          <label className="text-xs text-muted-foreground">Buyer wallet<Input className="mt-1" name="buyer" required placeholder="0x…" /></label>
          <label className="text-xs text-muted-foreground">Invoice reference<Input className="mt-1" name="reference" required placeholder="INV-2026-001" /></label>
          {DEMO_MODE ? (
            <div className="rounded-lg border border-dashed p-3 text-xs text-muted-foreground">Demo invoice hash: {DEMO_DOCUMENT_HASH.slice(0, 12)}…</div>
          ) : (
            <label className="text-xs text-muted-foreground">Private invoice file<Input accept="application/pdf,image/jpeg,image/png,image/webp" className="mt-1" name="document" required type="file" /></label>
          )}
          <label className="text-xs text-muted-foreground">Face value (aUSDC)<Input className="mt-1" name="faceValue" required min="0.000001" step="0.000001" type="number" /></label>
          <label className="text-xs text-muted-foreground">Due date<Input className="mt-1" name="dueDate" required type="date" /></label>
          <div className="flex items-end gap-2">{DEMO_MODE ? <Button onClick={fillDemoData} type="button" variant="secondary">Refill demo data</Button> : null}<Button className="flex-1" loading={busy} type="submit">Check A-Pass & create</Button></div>
          <div className="sm:col-span-2"><ActionStatus message={message} /></div>
        </form>
      ) : null}
    </section>
  )
}

export function ReceivableActions({ receivable }: { receivable: Receivable }) {
  const router = useRouter()
  const { address, client, issuePermits, send, signTypedDataAsync } = useTransactions()
  const [busy, setBusy] = React.useState<string>()
  const [message, setMessage] = React.useState<string>()
  const [hash, setHash] = React.useState<Hex>()

  const caller = address?.toLowerCase()
  const isSeller = caller === receivable.seller.toLowerCase()
  const isBuyer = caller === receivable.buyer.toLowerCase()
  const isFinancier = Boolean(receivable.financier && caller === receivable.financier.toLowerCase())

  async function run(label: string, action: () => Promise<Hex>) {
    try {
      setBusy(label); setHash(undefined); setMessage(`${label}…`)
      const transaction = await action()
      setHash(transaction); setMessage(`${label} confirmed on Base Sepolia.`)
      toastManager.add({ title: `${label} confirmed`, type: "success" })
      router.refresh()
    } catch (error) {
      setMessage(errorMessage(error))
      toastManager.add({ title: `${label} failed`, description: errorMessage(error), type: "error" })
    } finally { setBusy(undefined) }
  }

  async function readOnchain() {
    if (!client) throw new Error("Base Sepolia client is unavailable.")
    return client.readContract({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "getReceivable", args: [receivable.id as Hex] })
  }

  const confirm = () => run("Buyer confirmation", async () => {
    const value = await readOnchain()
    const buyerSignature = await signTypedDataAsync({
      domain: registryDomain, types: buyerConfirmationTypes, primaryType: "BuyerConfirmation",
      message: { receivableId: receivable.id as Hex, seller: value.seller, buyer: value.buyer, faceValue: value.faceValue, dueDate: value.dueDate, fingerprint: value.fingerprint },
    })
    const [issued] = await issuePermits("confirm", receivable.id as Hex)
    return send({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "confirmReceivable", args: [receivable.id as Hex, buyerSignature, issued.permit, issued.signature] })
  })

  async function openAuction(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    await run("Auction opening", async () => {
      if (!client) throw new Error("Base Sepolia client is unavailable.")
      const block = await client.getBlock()
      const closesAt = block.timestamp + BigInt(Math.floor(Number(form.get("duration")) * 3600))
      return send({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, abi: auctionAbi, functionName: "createAuction", args: [receivable.id as Hex, closesAt, parseUnits(String(form.get("reserve")), 6)] })
    })
  }

  async function bid(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const amount = String(new FormData(event.currentTarget).get("bid"))
    await run("Encrypted bid", async () => {
      if (!address || !client || !receivable.auctionId) throw new Error("Connect a wallet to an open auction.")
      const auctionId = BigInt(receivable.auctionId)
      const subjectId = pad(toHex(auctionId), { size: 32 })
      const [issued] = await issuePermits("bid", subjectId, { auctionId: auctionId.toString() })
      setMessage("Encrypting the bid for the Inco executor…")
      const [{ Lightning }, { handleTypes }] = await Promise.all([import("@inco/lightning-js/lite"), import("@inco/lightning-js")])
      const zap = await Lightning.baseSepoliaTestnet()
      if (getAddress(zap.executorAddress) !== getAddress(BIDNOX_BASE_SEPOLIA.incoExecutor)) throw new Error("Inco executor configuration mismatch.")
      const encryptedBid = await zap.encrypt(parseUnits(amount, 6), { accountAddress: address, dappAddress: BIDNOX_BASE_SEPOLIA.confidentialAuction, handleType: handleTypes.euint256 })
      const fee = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.incoExecutor, abi: incoExecutorAbi, functionName: "getFee" })
      return send({ address: BIDNOX_BASE_SEPOLIA.confidentialAuction, abi: auctionAbi, functionName: "submitBid", args: [auctionId, encryptedBid, issued.permit, issued.signature], value: fee })
    })
  }

  const fund = () => run("Funding", async () => {
    const value = await readOnchain()
    if (!client || !address) throw new Error("Connect the winning financier wallet.")
    const allowance = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.aUSDC, abi: erc20Abi, functionName: "allowance", args: [address, BIDNOX_BASE_SEPOLIA.receivableRegistry] })
    if (allowance < value.advanceAmount) {
      setMessage("Approve the aUSDC funding transfer in your wallet…")
      await send({ address: BIDNOX_BASE_SEPOLIA.aUSDC, abi: erc20Abi, functionName: "approve", args: [BIDNOX_BASE_SEPOLIA.receivableRegistry, value.advanceAmount] })
    }
    const [financier, seller] = await issuePermits("fund", receivable.id as Hex)
    return send({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "fundReceivable", args: [receivable.id as Hex, financier.permit, financier.signature, seller.permit, seller.signature] })
  })

  const repay = () => run("Repayment", async () => {
    const value = await readOnchain()
    if (!client || !address) throw new Error("Connect the buyer wallet.")
    const allowance = await client.readContract({ address: BIDNOX_BASE_SEPOLIA.aUSDC, abi: erc20Abi, functionName: "allowance", args: [address, BIDNOX_BASE_SEPOLIA.receivableRegistry] })
    if (allowance < value.faceValue) {
      setMessage("Approve the aUSDC repayment in your wallet…")
      await send({ address: BIDNOX_BASE_SEPOLIA.aUSDC, abi: erc20Abi, functionName: "approve", args: [BIDNOX_BASE_SEPOLIA.receivableRegistry, value.faceValue] })
    }
    const [buyer, financier] = await issuePermits("repay", receivable.id as Hex)
    return send({ address: BIDNOX_BASE_SEPOLIA.receivableRegistry, abi: registryAbi, functionName: "repayReceivable", args: [receivable.id as Hex, buyer.permit, buyer.signature, financier.permit, financier.signature] })
  })

  const hasAction = (receivable.status === "Awaiting buyer" && isBuyer) ||
    (receivable.status === "Buyer confirmed" && isSeller) || receivable.status === "Auction open" ||
    (receivable.status === "Auction closed" && isFinancier) || (receivable.status === "Funded" && isBuyer)

  if (!address) return <section className="rounded-xl border p-4 text-sm text-muted-foreground">Connect the relevant participant wallet to transact.</section>
  if (!hasAction) return null

  return (
    <section className="rounded-xl border p-4">
      <h2 className="text-sm font-medium">Onchain actions</h2>
      <p className="mt-1 text-xs text-muted-foreground">Each action checks the connected wallet, obtains a short-lived Cleanverse permit, and submits a real transaction.</p>
      <div className="mt-4 space-y-4">
        {receivable.status === "Awaiting buyer" && isBuyer ? <Button loading={busy === "Buyer confirmation"} onClick={confirm}>Confirm receivable</Button> : null}
        {receivable.status === "Buyer confirmed" && isSeller ? (
          <form className="grid gap-3 sm:grid-cols-3" onSubmit={openAuction}>
            <label className="text-xs text-muted-foreground">Reserve (aUSDC)<Input className="mt-1" defaultValue={DEMO_MODE ? (receivable.faceValue * 0.75).toFixed(6) : undefined} name="reserve" required step="0.000001" type="number" /></label>
            <label className="text-xs text-muted-foreground">Duration (hours)<Input className="mt-1" defaultValue={DEMO_MODE ? "0.05" : "24"} min="0.05" name="duration" required step="0.05" type="number" /></label>
            <div className="flex items-end"><Button className="w-full" loading={busy === "Auction opening"} type="submit">Open auction</Button></div>
          </form>
        ) : null}
        {receivable.status === "Auction open" ? (
          <form className="flex flex-col gap-3 sm:flex-row" onSubmit={bid}>
            <label className="flex-1 text-xs text-muted-foreground">Private bid (aUSDC)<Input className="mt-1" defaultValue={DEMO_MODE ? (receivable.faceValue * 0.9).toFixed(6) : undefined} name="bid" required step="0.000001" type="number" /></label>
            <div className="flex items-end"><Button loading={busy === "Encrypted bid"} type="submit">Encrypt & submit bid</Button></div>
          </form>
        ) : null}
        {receivable.status === "Auction closed" && isFinancier ? <Button loading={busy === "Funding"} onClick={fund}>Approve aUSDC & fund seller</Button> : null}
        {receivable.status === "Funded" && isBuyer ? <Button loading={busy === "Repayment"} onClick={repay}>Approve aUSDC & repay financier</Button> : null}
      </div>
      <ActionStatus hash={hash} message={message} />
    </section>
  )
}
