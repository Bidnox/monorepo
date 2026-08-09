"use client"

import * as React from "react"
import type { HexString } from "@inco/lightning-js"
import { useRouter } from "next/navigation"
import {
  CalendarDays,
  Check,
  FileText,
  LockKeyhole,
  Upload,
  X,
} from "lucide-react"
import {
  bytesToHex,
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
import { Badge } from "@/components/ui/badge"
import { Calendar } from "@/components/ui/calendar"
import {
  Dialog,
  DialogClose,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogPanel,
  DialogPopup,
  DialogTitle,
} from "@/components/ui/dialog"
import { Field, FieldDescription, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Popover, PopoverPopup, PopoverTrigger } from "@/components/ui/popover"
import { toastManager } from "@/components/ui/toast"
import {
  EncryptionProgress,
  PartnerMark,
  PartnerRoute,
} from "@/components/partner-mark"
import type { Receivable } from "@/lib/bidnox"
import { BIDNOX_BASE_SEPOLIA } from "@/lib/contracts"
import {
  auctionAbi,
  buyerConfirmationTypes,
  deserializePermit,
  erc20Abi,
  incoExecutorAbi,
  registryAbi,
  registryDomain,
  type PermitAction,
  type ReceivableInput,
} from "@/lib/protocol"

type IssuedPermit = { permit: Record<string, string>; signature: Hex }

function errorMessage(error: unknown) {
  if (error instanceof Error) return error.message.split("\n")[0]
  return "The wallet action failed."
}

function serializeInput(input: ReceivableInput) {
  return Object.fromEntries(
    Object.entries(input).map(([key, value]) => [
      key,
      typeof value === "bigint" ? value.toString() : value,
    ])
  )
}

function useTransactions() {
  const { address } = useAccount()
  const client = usePublicClient()
  const { signMessageAsync } = useSignMessage()
  const { signTypedDataAsync } = useSignTypedData()
  const { writeContractAsync } = useWriteContract()

  async function ensureWalletSession() {
    if (!address) throw new Error("Connect a wallet first.")
    const current = await fetch(`/api/auth/verify?address=${address}`, {
      cache: "no-store",
    })
    if (current.ok) return
    const challengeResponse = await fetch("/api/auth/challenge", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ address }),
    })
    const challenge = (await challengeResponse.json()) as {
      message?: string
      error?: string
    }
    if (!challengeResponse.ok || !challenge.message)
      throw new Error(challenge.error || "Unable to start wallet sign-in.")
    const signature = await signMessageAsync({ message: challenge.message })
    const verification = await fetch("/api/auth/verify", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ address, signature }),
    })
    const result = (await verification.json()) as { error?: string }
    if (!verification.ok)
      throw new Error(result.error || "Wallet sign-in failed.")
  }

  async function issuePermits(
    action: PermitAction,
    subjectId: Hex,
    extra: Record<string, unknown> = {}
  ) {
    if (!address) throw new Error("Connect a wallet first.")
    await ensureWalletSession()
    const response = await fetch("/api/compliance/permit", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ caller: address, action, subjectId, ...extra }),
    })
    const result = (await response.json()) as {
      error?: string
      permits?: IssuedPermit[]
    }
    if (!response.ok || !result.permits)
      throw new Error(result.error || "Compliance permit request failed.")
    return result.permits.map((item) => ({
      permit: deserializePermit(item.permit),
      signature: item.signature,
    }))
  }

  async function send(parameters: Record<string, unknown>) {
    if (!client) throw new Error("Base Sepolia client is unavailable.")
    const hash = await writeContractAsync(
      parameters as Parameters<typeof writeContractAsync>[0]
    )
    const receipt = await client.waitForTransactionReceipt({
      hash,
      confirmations: 2,
    })
    if (receipt.status !== "success") throw new Error("Transaction reverted.")
    return hash
  }

  return {
    address,
    client,
    ensureWalletSession,
    issuePermits,
    send,
    signMessageAsync,
    signTypedDataAsync,
  }
}

function ActionStatus({ message, hash }: { message?: string; hash?: Hex }) {
  if (!message && !hash) return null
  const partner = message?.includes("Cleanverse")
    ? "cleanverse"
    : message?.includes("Inco")
      ? "inco"
      : undefined
  return (
    <p
      className="mt-3 flex flex-wrap items-center gap-1.5 text-xs break-words text-muted-foreground"
      role="status"
    >
      {partner ? <PartnerMark compact partner={partner} /> : null}
      {message}
      {hash ? (
        <>
          {" "}
          ·{" "}
          <a
            className="underline"
            href={`${BIDNOX_BASE_SEPOLIA.explorer}/tx/${hash}`}
            target="_blank"
            rel="noreferrer"
          >
            View transaction
          </a>
        </>
      ) : null}
    </p>
  )
}

export function CreateReceivableForm() {
  const router = useRouter()
  const { address, client, ensureWalletSession, issuePermits, send } =
    useTransactions()
  const [busy, setBusy] = React.useState(false)
  const [message, setMessage] = React.useState<string>()
  const [sessionReady, setSessionReady] = React.useState<boolean>()
  const [file, setFile] = React.useState<File>()
  const [dragging, setDragging] = React.useState(false)
  const [dateOpen, setDateOpen] = React.useState(false)
  const [dueDay, setDueDay] = React.useState<Date>()
  const [dueTime, setDueTime] = React.useState("17:00")
  const fileInput = React.useRef<HTMLInputElement>(null)

  React.useEffect(() => {
    const timer = window.setTimeout(() => {
      const defaultDate = new Date()
      defaultDate.setDate(defaultDate.getDate() + 30)
      setDueDay(defaultDate)
    }, 0)
    return () => window.clearTimeout(timer)
  }, [])

  React.useEffect(() => {
    if (!address) return
    fetch(`/api/auth/verify?address=${address}`, { cache: "no-store" })
      .then((response) => setSessionReady(response.ok))
      .catch(() => setSessionReady(false))
  }, [address])

  async function authenticate() {
    try {
      setBusy(true)
      setMessage("Confirm the one-time, gasless wallet sign-in…")
      await ensureWalletSession()
      setSessionReady(true)
      setMessage("Wallet secured. Complete the form and create the receivable.")
    } catch (error) {
      setMessage(errorMessage(error))
    } finally {
      setBusy(false)
    }
  }

  const dueDateValue = React.useMemo(() => {
    if (!dueDay || !dueTime) return ""
    const year = dueDay.getFullYear()
    const month = String(dueDay.getMonth() + 1).padStart(2, "0")
    const day = String(dueDay.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}T${dueTime}`
  }, [dueDay, dueTime])

  function chooseFile(next?: File) {
    if (!next) return
    setFile(next)
    setMessage(undefined)
  }

  async function submit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!address || !client)
      return setMessage("Connect the seller wallet first.")
    const data = new FormData(event.currentTarget)
    try {
      setBusy(true)
      setMessage("Preparing receivable and checking Cleanverse eligibility…")
      const buyer = getAddress(String(data.get("buyer")))
      const latest = await client.getBlock()
      const dueDateMs = new Date(String(data.get("dueDate"))).getTime()
      if (!Number.isFinite(dueDateMs))
        throw new Error("Choose a valid due date and time.")
      const dueDate = BigInt(Math.floor(dueDateMs / 1000))
      if (dueDate <= latest.timestamp)
        throw new Error("Due date and time must be in the future.")
      const reference = String(data.get("reference"))
      const faceValue = String(data.get("faceValue"))
      if (!file || file.size === 0) {
        throw new Error("Choose an invoice document to upload.")
      }
      setMessage("Signing in once for private upload and compliance checks…")
      await ensureWalletSession()
      setMessage("Uploading the private invoice to Pinata…")
      const upload = new FormData()
      upload.set("file", file)
      upload.set("caller", address)
      const response = await fetch("/api/pinata/upload", {
        method: "POST",
        body: upload,
      })
      const result = (await response.json()) as {
        documentHash?: Hex
        error?: string
      }
      if (!response.ok || !result.documentHash)
        throw new Error(result.error || "Invoice upload failed.")
      const documentHash = result.documentHash
      const input: ReceivableInput = {
        buyer,
        invoiceReferenceHash: keccak256(stringToHex(reference)),
        documentHash,
        currency: pad(stringToHex("USD"), { size: 32, dir: "right" }),
        faceValue: parseUnits(faceValue, 6),
        issueDate: latest.timestamp,
        dueDate,
        settlementAsset: getAddress(BIDNOX_BASE_SEPOLIA.aUSDC),
      }
      const fingerprint = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "computeFingerprint",
        args: [address, input],
      })
      const receivableId = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "computeReceivableId",
        args: [fingerprint],
      })
      const [issued] = await issuePermits("create", receivableId, {
        input: serializeInput(input),
      })
      setMessage("Confirm creation in your wallet…")
      const hash = await send({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "createReceivable",
        args: [input, issued.permit, issued.signature],
      })
      toastManager.add({ title: "Receivable created", type: "success" })
      router.push(`/receivables/${receivableId}`)
      router.refresh()
      setMessage(`Created in ${hash.slice(0, 10)}…`)
    } catch (error) {
      setMessage(errorMessage(error))
      toastManager.add({
        title: "Creation failed",
        description: errorMessage(error),
        type: "error",
      })
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="space-y-6" onSubmit={submit}>
      <div className="grid gap-5 sm:grid-cols-2">
        <Field>
          <FieldLabel>Invoice reference</FieldLabel>
          <Input
            size="lg"
            name="reference"
            required
            placeholder="INV-2026-001"
          />
        </Field>
        <Field>
          <FieldLabel>Buyer wallet</FieldLabel>
          <Input
            size="lg"
            name="buyer"
            required
            placeholder="0x…"
            spellCheck={false}
          />
        </Field>
        <Field>
          <FieldLabel>Face value</FieldLabel>
          <Input
            size="lg"
            name="faceValue"
            required
            min="0.000001"
            step="0.000001"
            type="number"
            placeholder="1.00"
          />
          <FieldDescription className="flex items-center gap-1.5">
            Settled in <PartnerMark partner="cleanverse" /> aUSDC.
          </FieldDescription>
        </Field>
        <Field>
          <FieldLabel>Due date and time</FieldLabel>
          <input name="dueDate" type="hidden" value={dueDateValue} />
          <div className="grid w-full grid-cols-1 gap-2 sm:grid-cols-[minmax(0,1fr)_8.5rem]">
            <Popover open={dateOpen} onOpenChange={setDateOpen}>
              <PopoverTrigger
                render={
                  <Button
                    className="h-9.5 w-full justify-start font-normal sm:h-8.5"
                    size="lg"
                    variant="outline"
                  />
                }
              >
                <CalendarDays />
                {dueDay
                  ? dueDay.toLocaleDateString(undefined, {
                      day: "2-digit",
                      month: "short",
                      year: "numeric",
                    })
                  : "Select date"}
              </PopoverTrigger>
              <PopoverPopup align="start">
                <Calendar
                  disabled={{ before: new Date() }}
                  mode="single"
                  onSelect={(value) => {
                    setDueDay(value)
                    setDateOpen(false)
                  }}
                  selected={dueDay}
                />
              </PopoverPopup>
            </Popover>
            <Input
              aria-label="Due time"
              size="lg"
              type="time"
              required
              value={dueTime}
              onChange={(event) => setDueTime(event.target.value)}
            />
          </div>
          <FieldDescription>
            Shown in each viewer’s local timezone.
          </FieldDescription>
        </Field>
      </div>

      <Field>
        <FieldLabel>Invoice document</FieldLabel>
        <input
          ref={fileInput}
          className="sr-only"
          type="file"
          accept="application/pdf,image/jpeg,image/png,image/webp"
          onChange={(event) => chooseFile(event.target.files?.[0])}
        />
        <button
          type="button"
          onClick={() => fileInput.current?.click()}
          onDragEnter={(event) => {
            event.preventDefault()
            setDragging(true)
          }}
          onDragOver={(event) => event.preventDefault()}
          onDragLeave={() => setDragging(false)}
          onDrop={(event) => {
            event.preventDefault()
            setDragging(false)
            chooseFile(event.dataTransfer.files?.[0])
          }}
          className={`flex min-h-32 w-full items-center justify-center rounded-xl border border-dashed px-5 text-center transition-colors ${dragging ? "border-foreground bg-muted" : "border-input hover:bg-muted/50"}`}
        >
          {file ? (
            <span className="flex items-center gap-3 text-left">
              <span className="grid size-9 place-items-center rounded-lg bg-muted">
                <FileText className="size-4" />
              </span>
              <span>
                <span className="block max-w-72 truncate text-sm font-medium">
                  {file.name}
                </span>
                <span className="text-xs text-muted-foreground">
                  {(file.size / 1024).toFixed(1)} KB · Private Pinata storage
                </span>
              </span>
            </span>
          ) : (
            <span>
              <Upload className="mx-auto mb-2 size-5 text-muted-foreground" />
              <span className="block text-sm font-medium">
                Drop invoice here or browse
              </span>
              <span className="mt-1 block text-xs text-muted-foreground">
                PDF, JPEG, PNG or WebP · up to 10 MB
              </span>
            </span>
          )}
        </button>
        {file ? (
          <Button
            size="xs"
            variant="ghost"
            onClick={() => {
              setFile(undefined)
              if (fileInput.current) fileInput.current.value = ""
            }}
          >
            <X />
            Remove file
          </Button>
        ) : null}
      </Field>

      <div className="flex flex-col-reverse gap-3 border-t pt-5 sm:flex-row sm:items-center sm:justify-between">
        <ActionStatus message={message} />
        {sessionReady ? (
          <Button className="sm:min-w-44" loading={busy} type="submit">
            Create receivable
          </Button>
        ) : (
          <Button
            className="sm:min-w-44"
            disabled={sessionReady === undefined}
            loading={busy}
            type="button"
            onClick={authenticate}
          >
            Secure wallet session
          </Button>
        )}
      </div>
    </form>
  )
}

export function ReceivableActions({ receivable }: { receivable: Receivable }) {
  const router = useRouter()
  const {
    address,
    client,
    ensureWalletSession,
    issuePermits,
    send,
    signTypedDataAsync,
  } = useTransactions()
  const [busy, setBusy] = React.useState<string>()
  const [message, setMessage] = React.useState<string>()
  const [hash, setHash] = React.useState<Hex>()
  const [now, setNow] = React.useState(() => Math.floor(Date.now() / 1000))
  const [approvalReady, setApprovalReady] = React.useState<boolean>()
  const [sessionReady, setSessionReady] = React.useState<boolean>()
  const [buyerSignature, setBuyerSignature] = React.useState<Hex>()
  const [actionOpen, setActionOpen] = React.useState(false)

  const caller = address?.toLowerCase()
  const isSeller = caller === receivable.seller.toLowerCase()
  const isBuyer = caller === receivable.buyer.toLowerCase()
  const isFinancier = Boolean(
    receivable.financier && caller === receivable.financier.toLowerCase()
  )
  const alreadyBid = receivable.sealedBids.some(
    (item) => item.bidder.toLowerCase() === caller
  )
  const auctionAcceptingBids =
    receivable.status === "Auction open" &&
    !receivable.auctionRevealRequested &&
    Boolean(
      receivable.auctionClosesAtTimestamp &&
      receivable.auctionClosesAtTimestamp > now
    )

  React.useEffect(() => {
    if (receivable.status !== "Auction open") return
    const timer = window.setInterval(() => {
      setNow(Math.floor(Date.now() / 1000))
      router.refresh()
    }, 4_000)
    return () => window.clearInterval(timer)
  }, [receivable.status, router])

  React.useEffect(() => {
    if (
      !client ||
      !address ||
      !["Auction closed", "Funded"].includes(receivable.status)
    )
      return
    let active = true
    Promise.all([
      readOnchain(),
      client.readContract({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "allowance",
        args: [address, BIDNOX_BASE_SEPOLIA.receivableRegistry],
      }),
    ])
      .then(([value, allowance]) => {
        if (!active) return
        const required =
          receivable.status === "Auction closed"
            ? value.advanceAmount
            : value.faceValue
        setApprovalReady(allowance >= required)
      })
      .catch(() => {
        if (active) setApprovalReady(undefined)
      })
    return () => {
      active = false
    }
    // readOnchain is intentionally scoped to the current wallet and receivable state.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [address, client, receivable.id, receivable.status])

  React.useEffect(() => {
    if (!address) return
    fetch(`/api/auth/verify?address=${address}`, { cache: "no-store" })
      .then((response) => setSessionReady(response.ok))
      .catch(() => setSessionReady(false))
  }, [address])

  async function run(label: string, action: () => Promise<Hex>) {
    try {
      setBusy(label)
      setHash(undefined)
      setMessage(`${label}…`)
      const transaction = await action()
      setHash(transaction)
      setMessage(`${label} confirmed on Base Sepolia.`)
      toastManager.add({ title: `${label} confirmed`, type: "success" })
      router.refresh()
    } catch (error) {
      setMessage(errorMessage(error))
      toastManager.add({
        title: `${label} failed`,
        description: errorMessage(error),
        type: "error",
      })
    } finally {
      setBusy(undefined)
    }
  }

  async function readOnchain() {
    if (!client) throw new Error("Base Sepolia client is unavailable.")
    return client.readContract({
      address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
      abi: registryAbi,
      functionName: "getReceivable",
      args: [receivable.id as Hex],
    })
  }

  async function waitForAllowance(owner: `0x${string}`, amount: bigint) {
    if (!client) throw new Error("Base Sepolia client is unavailable.")
    for (let attempt = 0; attempt < 10; attempt += 1) {
      const allowance = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "allowance",
        args: [owner, BIDNOX_BASE_SEPOLIA.receivableRegistry],
      })
      if (allowance >= amount) return
      await new Promise((resolve) => window.setTimeout(resolve, 1_000))
    }
    throw new Error(
      "The aUSDC approval is confirmed but not yet visible. Please retry in a few seconds."
    )
  }

  async function signBuyerConfirmation() {
    try {
      setBusy("Buyer signature")
      setMessage("Review and sign the receivable details. This costs no gas.")
      const value = await readOnchain()
      const signature = await signTypedDataAsync({
        domain: registryDomain,
        types: buyerConfirmationTypes,
        primaryType: "BuyerConfirmation",
        message: {
          receivableId: receivable.id as Hex,
          seller: value.seller,
          buyer: value.buyer,
          faceValue: value.faceValue,
          dueDate: value.dueDate,
          fingerprint: value.fingerprint,
        },
      })
      setBuyerSignature(signature)
      setMessage("Buyer signature ready. Record it on Base Sepolia.")
    } catch (error) {
      setMessage(errorMessage(error))
    } finally {
      setBusy(undefined)
    }
  }

  const confirm = () =>
    run("Buyer confirmation", async () => {
      if (!buyerSignature) throw new Error("Sign the buyer confirmation first.")
      setMessage(
        "Cleanverse CVI verified the buyer. Issuing an action-bound confirmation permit…"
      )
      const [issued] = await issuePermits("confirm", receivable.id as Hex)
      return send({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "confirmReceivable",
        args: [
          receivable.id as Hex,
          buyerSignature,
          issued.permit,
          issued.signature,
        ],
      })
    })

  async function openAuction(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    await run("Auction opening", async () => {
      if (!client) throw new Error("Base Sepolia client is unavailable.")
      const [block, value] = await Promise.all([
        client.getBlock(),
        readOnchain(),
      ])
      const closesAt =
        block.timestamp +
        BigInt(Math.floor(Number(form.get("duration")) * 3600))
      const reserveAmount = (value.faceValue * 75n) / 100n
      return send({
        address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
        abi: auctionAbi,
        functionName: "createAuction",
        args: [receivable.id as Hex, closesAt, reserveAmount],
      })
    })
  }

  async function bid(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const amount = String(new FormData(event.currentTarget).get("bid"))
    await run("Encrypted bid", async () => {
      if (!address || !client || !receivable.auctionId)
        throw new Error("Connect a wallet to an open auction.")
      const auctionId = BigInt(receivable.auctionId)
      const subjectId = pad(toHex(auctionId), { size: 32 })
      setMessage(
        "Checking the lender’s Cleanverse A-Pass and issuing a bid-bound permit…"
      )
      const [issued] = await issuePermits("bid", subjectId, {
        auctionId: auctionId.toString(),
      })
      setMessage("Encrypting the bid for the Inco executor…")
      const [{ Lightning }, { handleTypes }] = await Promise.all([
        import("@inco/lightning-js/lite"),
        import("@inco/lightning-js"),
      ])
      const zap = await Lightning.baseSepoliaTestnet()
      if (
        getAddress(zap.executorAddress) !==
        getAddress(BIDNOX_BASE_SEPOLIA.incoExecutor)
      )
        throw new Error("Inco executor configuration mismatch.")
      const encryptedBid = await zap.encrypt(parseUnits(amount, 6), {
        accountAddress: address,
        dappAddress: BIDNOX_BASE_SEPOLIA.confidentialAuction,
        handleType: handleTypes.euint256,
      })
      const fee = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.incoExecutor,
        abi: incoExecutorAbi,
        functionName: "getFee",
      })
      return send({
        address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
        abi: auctionAbi,
        functionName: "submitBid",
        args: [auctionId, encryptedBid, issued.permit, issued.signature],
        value: fee,
      })
    })
  }

  async function revealWinner() {
    try {
      if (!client || !receivable.auctionId)
        throw new Error("Auction details are unavailable.")
      setBusy("Winner reveal")
      setHash(undefined)
      const auctionId = BigInt(receivable.auctionId)
      const auction = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
        abi: auctionAbi,
        functionName: "getAuction",
        args: [auctionId],
      })
      if (!auction.revealRequested && !auction.finalized) {
        setMessage("Closing bidding on Base Sepolia…")
        const closeHash = await send({
          address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
          abi: auctionAbi,
          functionName: "closeAuction",
          args: [auctionId],
        })
        setHash(closeHash)
        setMessage(
          "Bidding closed. Return when the Inco attestation is ready to finalize the winner."
        )
        toastManager.add({ title: "Auction closed", type: "success" })
        router.refresh()
        return
      }
      if (auction.finalized) {
        setMessage("Auction closed without an eligible winning bid.")
        router.refresh()
        return
      }
      setMessage(
        "Collecting Inco TEE attestations for the winning amount and bidder…"
      )
      const { Lightning } = await import("@inco/lightning-js/lite")
      const zap = await Lightning.baseSepoliaTestnet()
      if (
        getAddress(zap.executorAddress) !==
        getAddress(BIDNOX_BASE_SEPOLIA.incoExecutor)
      )
        throw new Error("Inco executor configuration mismatch.")
      const handles = [
        auction.highestBid,
        auction.winningBidderIndex,
      ] as HexString[]
      let revealed: Awaited<ReturnType<typeof zap.attestedReveal>> | undefined
      let lastError: unknown
      for (let attempt = 1; attempt <= 12 && !revealed; attempt += 1) {
        try {
          setMessage(
            `Waiting for Inco winner attestation · attempt ${attempt}/12…`
          )
          revealed = await zap.attestedReveal(handles, {
            backoffConfig: {
              maxRetries: 8,
              baseDelayInMs: 500,
              backoffFactor: 1.35,
            },
          })
        } catch (error) {
          lastError = error
          if (attempt < 12)
            await new Promise((resolve) => window.setTimeout(resolve, 3_000))
        }
      }
      if (!revealed)
        throw lastError instanceof Error
          ? lastError
          : new Error("Inco attestations are not ready.")
      const formatted = revealed.map((result) => ({
        value: result.plaintext.value as bigint,
        attestation: {
          handle: result.handle as Hex,
          value: pad(toHex(result.plaintext.value as bigint), { size: 32 }),
        },
        signatures: result.covalidatorSignatures.map((signature) =>
          bytesToHex(signature)
        ),
      }))
      setMessage("Submitting the attested winner on Base Sepolia…")
      const finalHash = await send({
        address: BIDNOX_BASE_SEPOLIA.confidentialAuction,
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
      })
      setHash(finalHash)
      setMessage("Winner finalized. Losing bid amounts remain sealed.")
      toastManager.add({ title: "Winner finalized", type: "success" })
      router.refresh()
    } catch (error) {
      setMessage(errorMessage(error))
      toastManager.add({
        title: "Winner reveal failed",
        description: errorMessage(error),
        type: "error",
      })
    } finally {
      setBusy(undefined)
    }
  }

  const fund = () =>
    run("Funding", async () => {
      const value = await readOnchain()
      if (!client || !address)
        throw new Error("Connect the winning financier wallet.")
      const allowance = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "allowance",
        args: [address, BIDNOX_BASE_SEPOLIA.receivableRegistry],
      })
      if (allowance < value.advanceAmount)
        throw new Error(
          "Approve aUSDC first, then fund in a separate transaction."
        )
      setMessage(
        "Cleanverse CVI verified the financier and seller. Issuing settlement permits…"
      )
      const [financier, seller] = await issuePermits(
        "fund",
        receivable.id as Hex
      )
      return send({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "fundReceivable",
        args: [
          receivable.id as Hex,
          financier.permit,
          financier.signature,
          seller.permit,
          seller.signature,
        ],
      })
    })

  const approveFunding = () =>
    run("aUSDC approval", async () => {
      const value = await readOnchain()
      const transaction = await send({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "approve",
        args: [BIDNOX_BASE_SEPOLIA.receivableRegistry, value.advanceAmount],
      })
      if (address) await waitForAllowance(address, value.advanceAmount)
      setApprovalReady(true)
      return transaction
    })

  const repay = () =>
    run("Repayment", async () => {
      const value = await readOnchain()
      if (!client || !address) throw new Error("Connect the buyer wallet.")
      const allowance = await client.readContract({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "allowance",
        args: [address, BIDNOX_BASE_SEPOLIA.receivableRegistry],
      })
      if (allowance < value.faceValue)
        throw new Error(
          "Approve aUSDC first, then repay in a separate transaction."
        )
      setMessage(
        "Cleanverse CVI verified the buyer and financier. Issuing repayment permits…"
      )
      const [buyer, financier] = await issuePermits(
        "repay",
        receivable.id as Hex
      )
      return send({
        address: BIDNOX_BASE_SEPOLIA.receivableRegistry,
        abi: registryAbi,
        functionName: "repayReceivable",
        args: [
          receivable.id as Hex,
          buyer.permit,
          buyer.signature,
          financier.permit,
          financier.signature,
        ],
      })
    })

  const approveRepayment = () =>
    run("aUSDC approval", async () => {
      const value = await readOnchain()
      const transaction = await send({
        address: BIDNOX_BASE_SEPOLIA.aUSDC,
        abi: erc20Abi,
        functionName: "approve",
        args: [BIDNOX_BASE_SEPOLIA.receivableRegistry, value.faceValue],
      })
      if (address) await waitForAllowance(address, value.faceValue)
      setApprovalReady(true)
      return transaction
    })

  const hasAction =
    (receivable.status === "Awaiting buyer" && isBuyer) ||
    (receivable.status === "Buyer confirmed" && isSeller) ||
    (auctionAcceptingBids && !alreadyBid) ||
    (receivable.status === "Auction open" && !auctionAcceptingBids) ||
    (receivable.status === "Auction closed" && isFinancier) ||
    (receivable.status === "Funded" && isBuyer)

  const actionTitle =
    receivable.status === "Awaiting buyer"
      ? "Sign receivable"
      : receivable.status === "Buyer confirmed"
        ? "Open financing auction"
        : auctionAcceptingBids
          ? "Place a private bid"
          : receivable.status === "Auction open"
            ? receivable.auctionRevealRequested
              ? "Finalize winner"
              : "Close bidding"
            : receivable.status === "Auction closed"
              ? "Fund the seller"
              : "Repay the financier"

  const actionDescription =
    receivable.status === "Awaiting buyer"
      ? "Review the terms, sign without gas, then record your confirmation."
      : receivable.status === "Buyer confirmed"
        ? "Choose how long lenders can submit sealed bids."
        : auctionAcceptingBids
          ? "Your amount is encrypted locally before it is submitted."
          : receivable.status === "Auction open"
            ? "End bidding and reveal only the eligible winner."
            : receivable.status === "Auction closed"
              ? "Approve the settlement amount, then fund the seller."
              : "Approve the settlement amount, then complete repayment."

  async function authenticateWallet() {
    try {
      setBusy("Wallet sign-in")
      setMessage("Confirm the one-time, gasless wallet sign-in…")
      await ensureWalletSession()
      setSessionReady(true)
      setMessage(
        "Wallet secured. Transaction buttons now open one wallet prompt each."
      )
    } catch (error) {
      setMessage(errorMessage(error))
    } finally {
      setBusy(undefined)
    }
  }

  if (!address)
    return (
      <section className="rounded-xl border p-4 text-sm text-muted-foreground">
        Connect the relevant participant wallet to continue.
      </section>
    )
  if (auctionAcceptingBids && alreadyBid)
    return (
      <section className="rounded-xl border p-4 text-sm text-muted-foreground">
        Your encrypted bid is sealed onchain. Bidding remains open for other
        eligible lenders.
      </section>
    )
  if (!hasAction) {
    const waiting =
      receivable.status === "Awaiting buyer"
        ? "Waiting for the recorded buyer to confirm the receivable."
        : receivable.status === "Buyer confirmed"
          ? "Waiting for the seller to open the financing auction."
          : receivable.status === "Auction closed"
            ? "Winner selected. Waiting for the winning financier to fund the seller."
            : receivable.status === "Funded"
              ? "Seller funded. Waiting for the buyer to repay in aUSDC."
              : "No transaction is required from this wallet."
    return (
      <section className="rounded-xl border p-4 text-sm text-muted-foreground">
        {waiting}
      </section>
    )
  }

  return (
    <>
      <section className="flex flex-col gap-4 rounded-xl border bg-card p-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="min-w-0">
          <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
            Next step
          </p>
          <h2 className="mt-1 text-base font-medium">{actionTitle}</h2>
          <p className="mt-1 max-w-xl text-xs text-muted-foreground">
            {actionDescription}
          </p>
        </div>
        <Button
          className="shrink-0 sm:min-w-32"
          onClick={() => setActionOpen(true)}
        >
          Continue
        </Button>
      </section>

      <Dialog open={actionOpen} onOpenChange={setActionOpen}>
        <DialogPopup>
          <DialogHeader>
            <div className="mb-1 flex items-center gap-2">
              <Badge variant="secondary">Next step</Badge>
              <PartnerRoute />
            </div>
            <DialogTitle>{actionTitle}</DialogTitle>
            <DialogDescription>{actionDescription}</DialogDescription>
          </DialogHeader>
          <DialogPanel className="space-y-5">
            {sessionReady !== true ? (
              <div className="space-y-4">
                <div className="rounded-xl bg-muted/45 p-4">
                  <div className="flex items-center gap-2 text-sm font-medium">
                    <PartnerMark partner="cleanverse" />
                    <span>Verify this wallet</span>
                  </div>
                  <p className="mt-2 text-xs leading-5 text-muted-foreground">
                    Sign once without gas. This keeps the following action to
                    one wallet transaction.
                  </p>
                </div>
                <Button
                  className="w-full"
                  disabled={sessionReady === undefined}
                  loading={busy === "Wallet sign-in"}
                  onClick={authenticateWallet}
                >
                  {sessionReady === undefined
                    ? "Checking session…"
                    : "Secure wallet session"}
                </Button>
              </div>
            ) : (
              <>
                {receivable.status === "Awaiting buyer" && isBuyer ? (
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-3 rounded-xl bg-muted/40 p-4 text-sm">
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Receivable
                        </p>
                        <p className="mt-1 font-medium">
                          {receivable.reference}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Face value
                        </p>
                        <p className="mt-1 font-medium tabular-nums">
                          ${receivable.faceValue.toFixed(2)}
                        </p>
                      </div>
                    </div>
                    {buyerSignature ? (
                      <div className="flex items-start gap-3 rounded-xl border border-emerald-500/20 bg-emerald-500/[0.05] p-4">
                        <span className="grid size-8 shrink-0 place-items-center rounded-full bg-emerald-500/10 text-emerald-600">
                          <Check className="size-4" />
                        </span>
                        <div>
                          <p className="text-sm font-medium">Signature ready</p>
                          <p className="mt-1 text-xs text-muted-foreground">
                            Now record it on Base Sepolia.
                          </p>
                        </div>
                      </div>
                    ) : null}
                    {buyerSignature ? (
                      <Button
                        className="w-full"
                        loading={busy === "Buyer confirmation"}
                        onClick={confirm}
                      >
                        Record confirmation
                      </Button>
                    ) : (
                      <Button
                        className="w-full"
                        loading={busy === "Buyer signature"}
                        onClick={signBuyerConfirmation}
                      >
                        Sign receivable
                      </Button>
                    )}
                  </div>
                ) : null}

                {receivable.status === "Buyer confirmed" && isSeller ? (
                  <form className="space-y-4" onSubmit={openAuction}>
                    <div className="flex items-start gap-3 rounded-xl bg-blue-500/[0.04] p-4 ring-1 ring-blue-500/10 ring-inset">
                      <PartnerMark
                        compact
                        partner="inco"
                        className="mt-0.5 [&_img]:size-5"
                      />
                      <div>
                        <p className="text-sm font-medium">
                          Open sealed bidding
                        </p>
                        <p className="mt-1 text-xs leading-5 text-muted-foreground">
                          Lenders submit encrypted amounts. No leading bid or
                          ranking is shown while bidding is open.
                        </p>
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-3 rounded-xl border p-4">
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Face value
                        </p>
                        <p className="mt-1 text-sm font-medium tabular-nums">
                          {receivable.faceValue.toFixed(6)} aUSDC
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">
                          Reserve · 75%
                        </p>
                        <p className="mt-1 text-sm font-medium tabular-nums">
                          {(receivable.faceValue * 0.75).toFixed(6)} aUSDC
                        </p>
                      </div>
                    </div>
                    <Field>
                      <FieldLabel>Auction duration</FieldLabel>
                      <Input
                        size="lg"
                        name="duration"
                        required
                        min="0.05"
                        step="0.05"
                        defaultValue="24"
                        type="number"
                      />
                      <FieldDescription>
                        Hours from the confirmed Base Sepolia block time.
                      </FieldDescription>
                    </Field>
                    <Button
                      className="w-full"
                      loading={busy === "Auction opening"}
                      type="submit"
                    >
                      Open auction
                    </Button>
                  </form>
                ) : null}

                {auctionAcceptingBids ? (
                  busy === "Encrypted bid" ? (
                    <EncryptionProgress
                      message={message || "Encrypting your bid"}
                    />
                  ) : (
                    <form className="space-y-4" onSubmit={bid}>
                      <div className="flex items-start gap-3 rounded-xl bg-blue-500/[0.04] p-4 ring-1 ring-blue-500/10 ring-inset">
                        <span className="grid size-9 shrink-0 place-items-center rounded-lg bg-background">
                          <LockKeyhole className="size-4 text-blue-600" />
                        </span>
                        <div>
                          <PartnerMark
                            partner="inco"
                            className="text-sm font-medium"
                          />
                          <p className="mt-1 text-xs leading-5 text-muted-foreground">
                            The amount is encrypted on this device before any
                            transaction is created.
                          </p>
                        </div>
                      </div>
                      <Field>
                        <FieldLabel>Private bid</FieldLabel>
                        <Input
                          size="lg"
                          name="bid"
                          required
                          step="0.000001"
                          min="0.000001"
                          type="number"
                          placeholder="0.850000"
                        />
                        <FieldDescription>
                          aUSDC · the plaintext amount never enters transaction
                          calldata.
                        </FieldDescription>
                      </Field>
                      <Button className="w-full" type="submit">
                        Encrypt & submit bid
                      </Button>
                    </form>
                  )
                ) : null}

                {receivable.status === "Auction open" &&
                !auctionAcceptingBids ? (
                  <div className="space-y-4">
                    <div className="rounded-xl bg-muted/40 p-4">
                      <div className="flex items-center justify-between gap-3">
                        <PartnerMark
                          partner="inco"
                          className="text-sm font-medium"
                        />
                        <Badge variant="outline">
                          {receivable.auctionRevealRequested
                            ? "Step 2 of 2"
                            : "Step 1 of 2"}
                        </Badge>
                      </div>
                      <p className="mt-3 text-sm font-medium">
                        {receivable.auctionRevealRequested
                          ? "Finalize the attested winner"
                          : "Stop accepting new bids"}
                      </p>
                      <p className="mt-1 text-xs leading-5 text-muted-foreground">
                        {receivable.auctionRevealRequested
                          ? "Submit the TEE attestation. Only the winner and winning amount become public; every losing bid stays sealed."
                          : "This transaction closes bidding and requests the encrypted winner handles for attestation. It does not reveal bid amounts."}
                      </p>
                    </div>
                    <Button
                      className="w-full"
                      loading={busy === "Winner reveal"}
                      onClick={revealWinner}
                    >
                      {receivable.auctionRevealRequested
                        ? "Finalize winner"
                        : "Close bidding"}
                    </Button>
                  </div>
                ) : null}

                {receivable.status === "Auction closed" && isFinancier ? (
                  <div className="space-y-4">
                    <div className="rounded-xl bg-muted/40 p-4">
                      <div className="flex items-center justify-between gap-3">
                        <PartnerMark
                          partner="cleanverse"
                          className="text-sm font-medium"
                        />
                        <Badge variant="outline">
                          {approvalReady ? "Step 2 of 2" : "Step 1 of 2"}
                        </Badge>
                      </div>
                      <p className="mt-3 text-sm font-medium">
                        {approvalReady === false
                          ? "Approve the funding amount"
                          : "Send funding to the seller"}
                      </p>
                      <p className="mt-1 text-xs leading-5 text-muted-foreground">
                        {approvalReady === false
                          ? `Allow the registry to transfer ${receivable.advance?.toFixed(6)} aUSDC. This approval does not move funds.`
                          : "Verify the financier and seller, then transfer the winning amount to the seller."}
                      </p>
                    </div>
                    {approvalReady === false ? (
                      <Button
                        className="w-full"
                        loading={busy === "aUSDC approval"}
                        onClick={approveFunding}
                      >
                        Approve {receivable.advance?.toFixed(6)} aUSDC
                      </Button>
                    ) : (
                      <Button
                        className="w-full"
                        loading={busy === "Funding"}
                        disabled={approvalReady === undefined}
                        onClick={fund}
                      >
                        {approvalReady === undefined
                          ? "Checking approval…"
                          : "Send funding"}
                      </Button>
                    )}
                  </div>
                ) : null}

                {receivable.status === "Funded" && isBuyer ? (
                  <div className="space-y-4">
                    <div className="rounded-xl bg-muted/40 p-4">
                      <div className="flex items-center justify-between gap-3">
                        <PartnerMark
                          partner="cleanverse"
                          className="text-sm font-medium"
                        />
                        <Badge variant="outline">
                          {approvalReady ? "Step 2 of 2" : "Step 1 of 2"}
                        </Badge>
                      </div>
                      <p className="mt-3 text-sm font-medium">
                        {approvalReady === false
                          ? "Approve the repayment amount"
                          : "Send repayment to the financier"}
                      </p>
                      <p className="mt-1 text-xs leading-5 text-muted-foreground">
                        {approvalReady === false
                          ? `Allow the registry to transfer ${receivable.faceValue.toFixed(6)} aUSDC. This approval does not move funds.`
                          : "Verify the buyer and financier, then transfer the face value to the winning financier."}
                      </p>
                    </div>
                    {approvalReady === false ? (
                      <Button
                        className="w-full"
                        loading={busy === "aUSDC approval"}
                        onClick={approveRepayment}
                      >
                        Approve {receivable.faceValue.toFixed(6)} aUSDC
                      </Button>
                    ) : (
                      <Button
                        className="w-full"
                        loading={busy === "Repayment"}
                        disabled={approvalReady === undefined}
                        onClick={repay}
                      >
                        {approvalReady === undefined
                          ? "Checking approval…"
                          : "Send repayment"}
                      </Button>
                    )}
                  </div>
                ) : null}
              </>
            )}
            <ActionStatus hash={hash} message={message} />
          </DialogPanel>
          <DialogFooter variant="bare">
            <DialogClose render={<Button variant="ghost" />}>
              {hash ? "Done" : "Close"}
            </DialogClose>
          </DialogFooter>
        </DialogPopup>
      </Dialog>
    </>
  )
}
