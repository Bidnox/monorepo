# Cleanverse live sandbox notes

Last updated: 2026-08-08 (Asia/Kolkata)

These are working notes from the live Base Sepolia setup, written after running the calls rather than copied from the API guide. They are meant to help us reproduce the demo and describe it honestly. No private keys, API credentials, identity documents, or browser cookies belong in this file.

## What worked

The hackathon credentials can call both A-Pass Management and Common Query endpoints. We successfully used the encrypted `POST /generate_apass` endpoint and the plain JSON `POST /query_apass`, `POST /verify_apass`, `POST /query_deposit_address`, and `POST /faucet` endpoints.

For sandbox A-Pass creation, the smallest payload that worked contained only:

- a unique alphanumeric `customerId` of at least 12 characters;
- a future Unix-seconds `expirationTime`; and
- the Base wallet address and `chain: "base"`.

We deliberately omitted `kycSource`, `kycId`, `identityDataList`, and `bankAccountList`. The resulting credentials are useful sandbox fixtures, but they are not evidence of a real KYC or KYB process. In the demo and UI, call them **Cleanverse sandbox A-Passes**, not “bank-verified identities.” Their `countries` arrays are empty because no identity documents were supplied.

`generate_apass` requires AES-CBC encryption with the Base64-decoded API key and a zero IV. The API key is used locally and is not sent as a header. The faucet is different: it accepts plain JSON and only needs the `api-id` header.

## Demo participants

All three wallets currently return `data.code: 4` from `POST /verify_apass` against the configured Base Sepolia aUSDC contract.

| Role | Wallet | A-Pass record | Starting aUSDC | Intended demo use |
|---|---|---:|---:|---|
| Financier | `0xc6377415Ee98A7b71161Ee963603eE52fF7750FC` | `1528` | `6` | Submit the confidential bid and finance the seller. |
| Buyer | `0x376b7271dD22D14D82Ef594324ea14e7670ed5b2` | `1785` | `5` | Confirm the receivable and repay the financier. |
| Seller | `0xf653B0f43b0f920E590Bf3745997B332d916Aacb` | `1786` | `0` | Create the receivable and receive financing. |

The seller intentionally starts with no aUSDC. A successful financing transaction should move aUSDC from the financier directly to the seller. The buyer was pre-funded so the repayment leg can be demonstrated without interrupting the recording.

All three A-Passes were created with tier `50`, active status `1`, no group/subgroup, no country tags, and expiration timestamp `1798761599`. We do not assign business meaning to tier `50`; it is simply the sandbox value returned by Cleanverse.

The buyer and seller were also given a small amount of Base Sepolia ETH for gas. Their private keys are testnet-only and must never be reused on mainnet.

## Live addresses

- A-Pass contract: `0xbA82D189540CaC9DC6FF46B6837CaC1BFdEC58B9`
- origin USDC: `0x543b96420d072BF587B63C41C0B0922762E986Ce`
- Access USDC / aUSDC: `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`
- Access Core: `0x8F118338a1fa41E7Fa86Be19A4e8B99Ed58A6EcC`
- deposit gateway: `0x8e084646080a35347B2D053Dd72F550f12245c8B`

These values came from the live sandbox configuration and should be rechecked before deployment rather than treated as permanent production constants.

Assigned USDC deposit wallets:

- Financier: `0xdb9273F089cF0177786e83C0B587ca64aEbE85a1`
- Buyer: `0x967c35Cc618Ad989Ad501f7B76Ac01667D0010FE`
- Seller: `0xf691a23d2D25CBA71f93891B0891309e0C58bc0c`

## Faucet behavior we observed

We tested both documented sandbox funding paths.

First, we requested `1 USDC` to the financier's assigned `depositUSDCWallet`. The origin USDC arrived at that address immediately. The corresponding aUSDC did not appear in the first few seconds, but it was minted shortly afterward. This is the better demo of the origin-token-to-A-Token gateway flow.

Second, we requested `100 aUSDC` directly to the financier wallet. The endpoint accepted the request but returned and transferred only `5 aUSDC`, indicating a sandbox drip cap. Together with the gateway-converted `1 aUSDC`, the financier ended with `6 aUSDC`. A direct request of `5 aUSDC` to the buyer also succeeded.

Use the gateway route when demonstrating capital provenance. Use the direct aUSDC faucet only to prepare test balances. Do not present a direct faucet mint as proof that funds originated from an approved institution.

The Cleanverse transaction index lagged the chain during this run: `query_txs` briefly returned zero results after the on-chain balances had already changed. For immediate confirmation, use the Base Sepolia receipt and ERC-20 `balanceOf`; use the Cleanverse index later for the evidence view once it catches up.

## Transaction evidence

### A-Pass creation

- Financier: `0xf1fbcb4f89e4d6122b353286b472f38eb7560a6caa6d789b716aecf850466185`
- Buyer: `0xd17c4cd5e7b2a65d4580a3c710b2ce368bc44ba8c6c26548b078b50ab3e2e711`
- Seller: `0x715756e20758e23a4d26751ea8d5302891b727e4b8ad3695f946d94380a1f781`

### Sandbox funding

- Financier origin-USDC gateway deposit: `0x73a2c389c39da997b70e032b7ac4ae8029a5bbc9ec14e4aa5ad20bea2533c33c`
- Financier direct aUSDC faucet: `0x7d5887b0a1b278ceecbc180cd8b7dc14695f636e6c00f1489e8cea610af2bd5b`
- Buyer direct aUSDC faucet: `0x44622ffc87e8d3969ddc7e0eb07b87595aee8a525753eaa1e9eca792675a0826`

### Gas funding

- Buyer: `0x041035856aa95cf0b5af84fcc31878264c165a5cba7249166879b3f405fff3e9`
- Seller: `0x60ec7622f0ca971c5b75111dc5a6703019026c1fb935f94332af9f7a1bdc506d`

## What the demo may claim

Safe claims:

- each participating wallet has an active, unexpired Cleanverse sandbox A-Pass;
- `verify_apass` returned code `4` for each wallet against the exact aUSDC settlement asset;
- financing and repayment use the live Base Sepolia Access USDC contract;
- one sandbox funding path demonstrated origin USDC reaching the assigned gateway address and a corresponding aUSDC balance appearing afterward.

Claims to avoid:

- that these fixtures prove real KYC, KYB, bank verification, or signer authority;
- that Cleanverse verified the invoice or the buyer's creditworthiness;
- that direct faucet aUSDC proves licensed-institution provenance;
- that a whitelist entry proves a named institution funded this transaction.

## Completed Bidnox lifecycle

The corrected deployment uses the same current Inco executor on both sides: Solidity imports `Lib.sol`, and the SDK uses `Lightning.baseSepoliaTestnet()`. An earlier `Lib.testnet.sol` deployment was discarded after its ciphertext context disagreed with the current SDK.

The live receivable `0x6cdf…058e` completed the whole path with two sealed bids. Only the winning value and index were revealed; the losing bid amount was never emitted or stored as plaintext. The financier won at `1.8 aUSDC`, funded the seller, and the buyer repaid `2 aUSDC`. The registry finished in `Repaid` status.

- corrected gate: `0x12badb8fd1828AB70Ea5FD4F5142Bc8c9e8f537d`
- corrected registry: `0xCad5d39Dc42757969323608a9207B283dbDE3b37`
- corrected auction: `0xDA6F7Fe360f7700d6E0d867bDC7f51C048E33c82`
- financier bid: `0x3786107f592aef1373088b29870380ef9fd2f636de9b2850aaaaa81d1e714a76`
- winner finalization: `0x1c0b73008cd68bbd65c767ee5d8381bf0e134fde06aed011574beed3f1dd6d0b`
- seller funding: `0x163d2e4ed32e6de43a85f0bc6a3876f96269b88087dfac3dcf706cdbc5a8728d`
- buyer repayment: `0x096c5beebcfe1617b2dbd8fb5aa38f4e473d1224328e932ba86d5144071a66a9`

The paid RPC occasionally returned a just-mined stale read and a stale nonce. The demo script now polls for expected state transitions and backs off while Inco's reveal ACL propagates.

## 3Jane fit

3Jane is not required for the hackathon's core CVI/CVA story. Its programmable credit and restaking direction could eventually help Bidnox build lender capital markets or credit underwriting, but adding it now would introduce another trust and integration surface without improving the required Cleanverse lifecycle. Keep it as a post-hackathon financing-liquidity research lead, not a dependency in this submission.

## Interactive app notes

The hosted app now builds transactions from the connected browser wallet instead of pretending that writes happened after a timer. The seller can create a receivable and open its auction, the recorded buyer can sign the EIP-712 confirmation, any eligible lender can encrypt and submit a sealed Inco bid, the winning financier can approve and transfer aUSDC, and the recorded buyer can approve and repay aUSDC. Contract addresses remain in one network configuration file because those are deployment settings, not sample business records.

Compliance permits stay short-lived and server-signed. Before issuing one, the server requires a fresh signature from the connected caller, re-derives the action's wallet and subject from contract state, and runs the current Cleanverse check. Funding and repayment need permits for both sides, so the server derives the seller or financier from the receivable rather than accepting those addresses from the browser. The public status endpoint follows the same rule: it accepts a receivable ID, derives its participants on-chain, and returns only the aggregate eligibility result.

The current demo deployment records the buyer test wallet as the compliance signer. That is workable for this sandbox deployment, but it couples a participant key to backend policy signing. Before any production or value-bearing deployment, rotate the gate to a dedicated signer kept in a managed signing service, retain the existing two-minute permit lifetime, and add persistent challenge nonces plus rate limiting at the API edge.

`NEXT_PUBLIC_DEMO_MODE=true` is a presentation aid, not a simulated-chain mode. It fills the known sandbox buyer, a unique invoice reference, a small aUSDC amount, a due date, short auction timing, reserve, and bid defaults. It substitutes a deterministic demo document hash so the presenter does not need to choose a file. Wallet signatures, Cleanverse verification, Inco encryption, aUSDC approvals, contract writes, and mined receipt checks remain real. Every write path rejects a reverted receipt.

With demo mode disabled, the seller selects a PDF or image. A fresh wallet signature authorizes the upload, the server confirms the uploader's Cleanverse eligibility, and the server sends the file to Pinata's private IPFS network using a server-only JWT. The contract stores only `keccak256("ipfs://<cid>")`; neither Pinata credentials nor raw invoice contents are placed on-chain or returned in the public receivable list.

### Inco privacy boundary

The current Inco use is necessary for sealed lender competition: each offer and the running highest bid/index stay encrypted during bidding, and losing values are never revealed. Inco does not hide the invoice face value or auction reserve. That is intentional for this version. Lenders need notional context to price an advance, and normal aUSDC transfers publicly reveal the winning funding and repayment amounts anyway. Hiding the invoice total alone would therefore overstate privacy. True private notional would require confidential settlement and participant-only document/amount access as a separate protocol design.

## Original next reproducible demo step (completed)

Deploy the hardened Bidnox contracts with the configured aUSDC contract, then run one small-value lifecycle using the three wallets above. Keep the amount comfortably below `5 aUSDC` so the buyer can repay and the financier can fund without another faucet call. Capture the create, buyer-confirm, encrypted bid, auction close, financing transfer, and repayment transaction hashes as they happen.
