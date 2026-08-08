# Bidnox winning plan

Research date: 2026-08-07. Scope: product strategy before implementation for the 48-hour Cleanverse Build: Trusted Assets Hackathon.

## Decision

### One sentence

**Bidnox is a clean-capital marketplace for buyer-confirmed receivables where verified financiers privately compete to provide working capital, while Cleanverse continuously controls participant eligibility and settlement.**

### One paragraph

An SME supplier records a receivable and its corporate buyer signs the exact receivable digest, turning an untrusted upload into a buyer-confirmed payment obligation inside Bidnox. Cleanverse A-Pass gates the participating wallets and Cleanverse A-Token/aUSDC is the financing and repayment rail. Eligible financiers submit only one confidential field—the cash advance they will provide—through Inco Lightning. At close, Bidnox reveals the highest advance and winner, rechecks the winner and seller against the actual aUSDC asset, and transfers clean settlement value. At maturity the buyer repays the financier in aUSDC. A visible evidence timeline distinguishes Cleanverse decisions, Bidnox signatures/events, Inco ciphertext/reveal, and offchain legal facts.

### Positioning choice

Use **“clean capital marketplace for buyer-confirmed receivables”** as the headline and **“compliance-native confidential invoice factoring”** as the technical subtitle.

Why this wins the wording test:

- “Clean capital” maps directly to A-Token origination and eligibility.
- “Buyer-confirmed receivables” is accurate; “verified invoice” would overclaim.
- “Marketplace” explains competitive financing.
- “Confidential” belongs in the subtitle because Inco is the mechanism, not the sponsor story.
- “Invoice factoring” is accurate for the proposed seller-created flow. Under the RBI's TReDS terminology, it becomes reverse factoring only if the buyer/anchor creates the financing unit and invites its supplier.

Avoid “invoice NFT marketplace,” “private credit dark pool,” and “decentralized factoring.” They either obscure the problem or imply technical/legal properties the demo cannot establish.

Do not call the current product “reverse factoring.” If the team later changes initiation so the buyer creates the approved payable and invites the seller to finance it, revisit that label; no other lifecycle step alone makes it reverse factoring.

## Full lifecycle

1. **Discover configuration.** Backend calls `query_chain_config`; use Base Sepolia because the live Cleanverse sandbox and current Inco Lightning examples both support it. Resolve A-Pass, origin USDC, aUSDC, Access Core, decimals, RPC, and explorer from the response.
2. **Bind participants.** Seller, buyer, and financier connect wallets. Bidnox queries A-Pass and expiration. Bidnox roles are application roles; do not derive “seller/buyer/lender” from undocumented tier/group semantics.
3. **Register deposit mapping.** Where needed, `query_user` then `register_data` binds a participant’s deposit address. For the current Base Sepolia demo wallets, `generate_apass` created the mapping and returned a distinct `depositUSDCWallet` for each participant.
4. **Create receivable.** The seller enters normalized commercial fields. Full documents and PII remain encrypted/offchain. The contract stores a deterministic fingerprint and a document commitment, not the invoice PDF.
5. **Buyer confirmation.** The buyer reviews amount, currency, issue/due dates, supplier, buyer, and invoice reference; it signs an EIP-712 typed receivable digest. The registry changes `Draft → BuyerConfirmed`.
6. **Duplicate guard.** Reject the same canonical fingerprint inside Bidnox. State plainly that this does not detect financing on other platforms or offchain.
7. **Capital preparation.** Display allowed deposit sources from `query_deposit_institutions`. The credentialed sandbox path is now confirmed: an origin-USDC faucet transfer to the financier's assigned deposit wallet was followed by a corresponding aUSDC balance. Capture `query_institution_txs` once the Cleanverse index catches up; during testing it lagged the already-confirmed on-chain receipt and balance.
8. **Confidential auction.** Before accepting a bid, check A-Pass and preferably `verify_apass(chain, aUSDC, lender)`. The lender encrypts only `advanceAmount`. Face amount, due date, close time, and buyer-confirmed fingerprint are public/fixed. Inco maintains encrypted best amount/winner.
9. **Close.** Reveal/attest only the winner and winning advance. Losing amounts remain encrypted and are never granted reveal permission. Use deterministic tie-breaking.
10. **Pre-settlement recheck.** Re-run asset-specific eligibility for winner and seller. Optionally run `/validator/verify` against a registered Bidnox market contract. If a credential is frozen/expired or the A-Token is not transferable, settlement stops.
11. **Financing settlement.** Transfer winning aUSDC from financier to seller. The hardened registry coordinates an exact `transferFrom(financier, seller, amount)` without ever taking custody; the state transition reverts unless the seller receives the full amount. Keep escrow out of P0, and do not call this production-proven until the registry-spender path passes an end-to-end Cleanverse sandbox transfer.
12. **Evidence.** Record the aUSDC transfer hash and show its Cleanverse transaction report if `/download_travel_rule` works. The Bidnox timeline separately shows buyer signature, duplicate check, bid/reveal, and state transitions.
13. **Repayment.** At maturity, recheck buyer and winner for aUSDC and transfer face value from buyer to financier. State changes `Funded → Repaid`.
14. **Default path.** If payment is absent after due date, mark `Overdue`, not “liquidated.” Default/collection is an offchain legal process. The demo does not pretend Cleanverse guarantees repayment.
15. **Optional withdrawal.** After repayment, the financier may call Access Core `withdraw(aToken, amount, recipient)`. This is a coda, not the core demo.

## Product critique: try to kill the idea

### Why blockchain?

An ordinary licensed factoring platform can already run buyer acceptance and lender bidding, and India’s TReDS does. Blockchain is justified only if Bidnox uses it for a shared, tamper-evident receivable state across independent firms, confidential-but-verifiable auction logic, programmable transfer restrictions, and settlement in an eligible asset. If the prototype is a React dashboard calling KYC once, blockchain adds little.

### Why Cleanverse?

Cleanverse must determine whether wallets may enter and whether the settlement asset may move. It also supplies live asset configuration, approved deposit-source configuration, a path to transaction-specific mint evidence, status revocation, and reports. Remove Cleanverse and Bidnox loses its participant perimeter, clean settlement asset, provenance path, and continuous compliance. That is load-bearing.

### Why confidentiality?

Only the lender’s advance offer has a strong privacy case. A public live bid can expose a lender’s risk appetite and pricing strategy, invite copying/last-look behavior, and reveal the seller’s financing cost before the auction is final. A sealed auction makes lenders price independently. The tradeoff is reduced public price transparency; therefore Bidnox reveals the winning advance/terms to the parties and keeps a verifiable close result. Identities, compliance decisions, invoice state, face value, seller reserve, and Cleanverse asset are not hidden.

We explicitly do **not** claim that Inco hides the invoice total. The deployed registry stores face value in plaintext, and the auction stores its reserve in plaintext. That is acceptable for this demo because eligible lenders need the invoice amount to underwrite an advance, while Inco protects the competing offers and running winner until close. Encrypting only face value or reserve would add complexity without end-to-end confidentiality: ordinary ERC-20 aUSDC funding and repayment transfers expose their amounts on-chain. A future private-notional version would need access-controlled invoice data plus confidential settlement, not a cosmetic encrypted field.

### Why not an existing invoice platform?

Existing platforms already solve the core business workflow and, in regulated markets, have legal/settlement integration that Bidnox lacks. Bidnox’s differentiated hypothesis is cross-institution programmable eligibility and clean digital-asset settlement plus sealed onchain competition. This is a pilot thesis, not proof that Bidnox can replace TReDS/factors.

### Who is the customer?

- **Primary buyer:** a licensed factor, bank/NBFC, or an anchor buyer’s supply-chain-finance program that wants multiple eligible liquidity providers and programmable settlement.
- **Seller/user:** an SME or exporter with a confirmed receivable and urgent working-capital need.
- **Financier/user:** regulated/eligible capital providers, not anonymous retail yield seekers.
- **Buyer/debtor:** the anchor enterprise that confirms the obligation and ultimately repays.

### Why lenders and sellers participate

- Financiers gain short-duration exposure priced through private competition and can verify participant/asset eligibility. They still must underwrite buyer credit and legal enforceability.
- Sellers accept a discount because immediate working capital may be worth more than the difference, and multiple bids should improve price relative to a single take-it-or-leave-it factor.

### Who takes default risk?

Recommend a **without-recourse-to-seller** demo after buyer confirmation: the winning financier takes buyer payment/default risk, subject to the offchain assignment contract. This resembles the RBI’s published TReDS flow, where the selected financier pays the seller and the buyer pays the financier at maturity; TReDS transactions are without recourse to the MSME. Default handling remains outside the platform’s role. [RBI TReDS FAQ](https://www.rbi.org.in/scripts/FAQView.aspx/FAQView.aspx/FAQView.aspx?Id=132).

Do not silently switch between recourse and non-recourse. Put “Demo assumption: without recourse; legal agreement offchain” beside the receivable.

### What buyer approval proves—and does not

The buyer’s EIP-712 signature proves that the controller of the registered buyer wallet approved the exact digest at a time. It materially reduces seller-only fabrication and binds the buyer to the terms **inside Bidnox**. It does not prove:

- the wallet signer had corporate authority;
- goods/services were delivered or undisputed;
- the invoice was not amended/cancelled elsewhere;
- the buyer is solvent;
- the receivable is legally assignable;
- the same invoice was not financed outside Bidnox.

For a production pilot, buyer onboarding, signing authority, ERP/e-invoice data, delivery evidence, dispute status, and assignment notice are offchain integrations.

### Duplicate financing prevention

The fingerprint should cover normalized seller/buyer identifiers, invoice reference, issue date, currency, face amount, and preferably the buyer-signed canonical payload. It prevents the identical canonical receivable from being registered twice **within Bidnox**. It does not create a global registry. In India, actual TReDS/factors also have regulatory filing and lender-information responsibilities; a prototype hash is not a substitute. [RBI assignment-registration rules](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12223).

### Legal claim

The financier’s claim must come from an offchain receivables assignment/financing agreement and applicable law. The onchain record is evidence and execution state; it is not the claim. UNCITRAL notes that enforceability against the debtor and priority versus competing claimants can vary by jurisdiction. [UNCITRAL Assignment of Receivables Convention overview](https://uncitral.un.org/en/texts/securityinterests/conventions/receivables).

In India, operating a TReDS platform requires RBI authorization. Bidnox must be presented as a sandbox prototype/infrastructure layer, not a live unlicensed TReDS operator.

### What stays offchain

- invoice PDF, purchase order, delivery records, tax identifiers, PII;
- KYB and authority-to-sign evidence unless Cleanverse supplies it;
- underwriting, buyer limits, disputes, insurance, collections;
- receivables assignment agreement and notices;
- fiat/NACH/bank settlement in a real deployment;
- confidential bid plaintext except authorized reveal.

## What Cleanverse can actually prove in the demo

| Desired statement | Honest demo label | Evidence |
|---|---|---|
| Verified seller/buyer/lender | “Connected wallet has active, unexpired A-Pass” | `query_apass` response at the action time |
| Eligible for settlement asset | “Wallet may transfer this aUSDC” | `verify_apass` result code `4` |
| Verified invoice | **Not supported** | Use “buyer-confirmed Bidnox receivable” with buyer signature |
| Clean capital | “Settlement is in configured aUSDC”; stronger: “aUSDC was minted following an approved-source deposit” | live config + transfer; stronger version needs whitelist + institutional tx mint evidence |
| CCP passed | **Do not say unless Cleanverse maps a real endpoint/result to CCP** | otherwise label exact Validator/A-Token check |
| Travel Rule compliant | “Cleanverse returned this Travel Rule/transaction report for tx hash X” | `download_travel_rule`; do not infer more than report type |
| Auditable lifecycle | “Bidnox evidence timeline” plus any named Cleanverse report | onchain events, API response hashes, report link |
| Creditworthy buyer | **Not supported** | require offchain underwriting |
| Financier owns legal claim | **Not supported by token/registry alone** | offchain assignment agreement |

## Differentiators under test

1. **Buyer-confirmed receivable:** meaningful fraud reduction versus seller-only upload, but incomplete verification.
2. **Bidnox duplicate fingerprint:** valuable local invariant and strong demo rejection; never call it ecosystem-wide prevention.
3. **Continuous compliance:** stronger than onboarding-only KYC because eligibility is checked at create/confirm/bid/settle/repay; the settlement recheck is the most important.
4. **Clean capital:** potentially the strongest Cleanverse differentiator when transaction-specific origin→mint evidence exists. A whitelist alone is only policy evidence.
5. **Confidential auction:** commercially justified because bids encode pricing/risk appetite; privacy ends where settlement terms need to be known.
6. **Failure states:** high value because a judge sees that Cleanverse changes execution in seconds.
7. **Compliance timeline:** essential UX translation layer, provided each item names its source.
8. **Audit report:** use the Cleanverse label only for an actual downloaded report. Everything else is “Bidnox evidence timeline.”

All interactive writes wait for a mined receipt and accept the action only when `receipt.status === "success"`. Demo mode changes defaults and the invoice fixture hash only; it never simulates a transaction.

## Feature value/risk matrix

| Feature | Main score impact | Complexity | Failure risk | Demo value | Understood in <10s? |
|---|---|---:|---:|---:|---|
| Live config, no hardcoded addresses | Build 25; CVI/CVA 30 | Low | Low | Medium | Not alone |
| Repeated A-Pass/asset eligibility | CVI/CVA 30; Concept 20 | Medium | Medium | Very high | Yes: “frozen wallet blocked” |
| Buyer EIP-712 confirmation | Concept 20; Build 25 | Medium | Low | High | Yes |
| Local duplicate fingerprint | Concept 20; Build 25 | Low | Low | High | Yes |
| Inco encrypted advance bids | UX 15; Build 25; differentiation | High | Medium-high | Very high | Yes |
| aUSDC financing transfer | CVI/CVA 30; Build 25 | Medium | Medium | Very high | Yes |
| aUSDC repayment | Concept 20; CVI/CVA 30 | Medium | Medium | High | Yes |
| Approved-source list only | CVI/CVA 30 | Low | Low | Medium | Yes, but easy to overclaim |
| Actual deposit→mint provenance | CVI/CVA 30; Scalability 10 | High | High | Very high | Yes |
| Validator-registered Bidnox policy | CVI/CVA 30; Build 25 | High | High (role/ABI) | Very high | Yes |
| Cleanverse tx/Travel Rule report | CVI/CVA 30; UX 15 | Medium | High (credentials/tx type) | High | Yes |
| Custom invoice A-Token | CVI/CVA 30 | Very high | Very high | High if real | Yes, but legal meaning unclear |
| Access Core withdrawal | Scalability 10 | Medium | Medium | Low | No; distracts from financing |
| Multi-chain deployment | Scalability 10 | Very high | Very high | Low in 90s | No |

## Feature ranking

### P0 — absolutely ship

Build P0 in this order so the highest-weight sponsor integration is proven before privacy work:

1. Runtime Cleanverse configuration.
2. Seller, buyer, and financier A-Pass/asset-eligibility checks.
3. Receivable registry, buyer signature, and duplicate fingerprint.
4. Actual aUSDC financier-to-seller transfer.
5. Actual aUSDC buyer-to-financier repayment.
6. Inco confidential auction and winner reveal.
7. Unverified/frozen participant rejection at an execution boundary.
8. Source-labeled evidence timeline.

If time collapses, a real Cleanverse lifecycle with a simple auction is preferable to a polished confidential auction backed by mocked settlement.

| Feature | Why it exists / criterion | Cleanverse primitive | Inco primitive | Complexity / demo / risk |
|---|---|---|---|---|
| Runtime Cleanverse adapter | Prevent stale configuration and prove real integration; Build, CVI/CVA | `query_chain_config` | None | Low / medium / low |
| Participant status at every action | Makes compliance revocable and execution-level; CVI/CVA, Concept | `query_apass`, expiration, preferably `verify_apass` | None | Medium / very high / medium |
| Receivable registry + canonical fingerprint | Gives the RWA a state and prevents in-app duplicate financing; Concept, Build | None; intentionally Bidnox-owned | None | Medium / high / low |
| Buyer typed-data confirmation | Converts seller upload to buyer-confirmed obligation; Concept | A-Pass check on buyer wallet | None | Medium / high / low |
| Fixed-term sealed reverse auction | Produces competitive financing without strategy leakage; UX, Build | Lender eligibility before submit | encrypted `euint256`, encrypted comparison/select, controlled reveal | High / very high / medium-high |
| Winner + winning advance reveal only | Memorable result while preserving losing bids; UX | Recheck winner | attested reveal/decryption permissions | Medium / very high / medium |
| Actual aUSDC financing transfer | Cleanverse must move real value; CVI/CVA, Build | live aUSDC, `verify_apass` | None | Medium / very high / medium |
| Buyer→financier repayment path | Completes lifecycle; Concept, CVI/CVA | repeated eligibility + aUSDC | None | Medium / high / medium |
| One visible rejection | Makes sponsor control obvious; UX, CVI/CVA | unregistered/frozen/expired/asset-ineligible result | None | Low-medium / very high / fixture risk |
| Source-labeled evidence timeline | Lets judges understand the stack; UX, Presentation-equivalent | response/result and tx references | bid handles/reveal attestation | Medium / very high / low |
| Tests for state and failure invariants | Protects Build Quality | mocked API boundaries + integration test where possible | auction invariants | Medium-high / indirect / medium |

P0 settlement should remain lender→seller and buyer→lender with no escrow custody. Bidnox may coordinate those transfers through exact `transferFrom` calls only after the registry-spender path succeeds against live sandbox aUSDC; otherwise use explicit wallet transfers and reconcile their real transaction receipts without accepting backend-signed claims as payment proof.

### P1 — strong differentiators

| Feature | Why / criterion | Cleanverse | Inco | Complexity / demo / risk |
|---|---|---|---|---|
| Transaction-specific capital provenance | Turns “clean capital” into evidence; CVI/CVA, scalability | deposit address, institution whitelist, `query_institution_txs` | None | High / very high / high |
| Register Bidnox as Validator pool | Makes an invoice-finance policy a Cleanverse-controlled entry condition; CVI/CVA | `/validator/register`, rules, `/verify` | None | High / very high / credential + ABI risk |
| Freeze between bid and settlement | Best continuous-compliance moment; CVI/CVA, UX | `/update_status`, recheck/verify | winner remains encrypted until close | Medium / exceptional / fixture risk |
| Cleanverse transaction/Travel Rule report | Gives a real audit artifact; CVI/CVA, UX | `/download_travel_rule` | None | Medium / high / qualifying-tx risk |
| Automatic next-eligible winner | Gives failure a useful outcome without revealing losers | eligibility recheck | encrypted selection across still-eligible bids | High / very high / high |

If transaction-specific provenance cannot be demonstrated, change the pitch from “institution-originated capital” to “Cleanverse A-Token capital from an approved deposit perimeter.” Never imply a list proves the specific funds’ origin.

### P2 — only if time remains and prerequisites are confirmed

| Feature | Why / criterion | Cleanverse | Inco | Complexity / demo / risk |
|---|---|---|---|---|
| One custom receivable A-Token experiment | Test issuance-from-origin story | `/atoken/launch`, rule, pause | None | Very high / high / very high; only with team-approved pattern |
| Official lender group/tier policy | Stronger investor eligibility | group/tier rule | None | Medium / medium / taxonomy risk |
| Access Core withdrawal | Shows complete gateway exit | `withdraw` | None | Medium / low / medium |
| Overdue state + evidence export | Honest default handling | status rechecks only | None | Low / medium / low |
| Fiat-ramp widget | End-to-end fiat story | fiat ramp APIs | None | High / low in core demo / high |

### Do not build

- Per-invoice NFT/CVA factory without explicit Cleanverse confirmation.
- Public IPFS invoice documents or PII.
- AI invoice OCR, generic fraud score, or invented underwriting/credit score.
- Cross-chain auctions/CCIP bridge.
- Secondary market, fractional pools, tranches, yield token, DAO, governance token, or points.
- Confidential identities, confidential compliance outcomes, private A-Token balances, or private repayment.
- A locally mocked “CCP passed,” “Travel Rule compliant,” “KYB verified,” or “Cleanverse audit report.”
- Custom sanctions/jurisdiction engine inferred from issuing-country tags.
- Default liquidation/insurance/collections engine.
- Generalized escrow until A-Token contract-custody behavior is confirmed.
- Mobile app, agent/MCP interface, or Access Core withdrawal before the happy path works.

## Cleanverse integration map

| Primitive | Exact Bidnox location | Execution effect |
|---|---|---|
| `query_chain_config` | app startup/backend refresh | Determines network, token, decimals, explorer, A-Pass, Access Core; build fails closed if unavailable/stale |
| `get_magiclink` | participant onboarding | Gives unverified wallet a real path to qualification |
| `query_apass` | seller create, buyer confirm, lender bid, winner settle, buyer repay | Blocks inactive/frozen/expired wallets and records status snapshot |
| `query_user` / `register_data` | deposit setup | Ensures wallet→deposit mapping exists; do not interpret undocumented status enum |
| `query_deposit_address` | lender/buyer funding panel | Provides their Cleanverse gateway address |
| `query_deposit_institutions` | capital source panel | Shows allowed origin sources for the exact pair |
| `verify_apass` | bid admission, pre-settlement, pre-repayment | Answers whether wallet can transfer the actual aUSDC |
| aUSDC contract from live config | financing and repayment | Actual compliant settlement asset |
| `query_institution_txs` | winner capital evidence | Links origin transfer and aUSDC mint if credentialed path works |
| Validator register/rules/verify | market policy | Evaluates lender against a Bidnox-market rule if Issue Member access exists |
| A-Token rules/pause | settlement asset policy | Read/show actual rules; do not mutate core aUSDC without permission |
| `download_travel_rule` | post-settlement receipt | Attaches real Cleanverse-generated report to tx hash |
| Access Core `withdraw` | optional post-repayment exit | Converts wrapped A-Token to origin token for recipient |
| Custom A-Token launch | contingent RWA experiment | Not in winning core until invoice suitability and role are confirmed |

## Inco integration map

Use Inco Lightning for exactly one thing: sealed lender offers.

| Data/operation | Privacy decision |
|---|---|
| `advanceAmount` | Encrypt client-side as `euint256`; consume onchain with correct fee and bidder permission. |
| Best amount | Maintain as encrypted comparison result. |
| Best bidder | Maintain as encrypted address selected by the encrypted comparison, or an equivalent audited pattern. |
| Auction close | Reveal/attest winner and winning advance only after deadline. |
| Losing bids | Never call reveal or grant seller/public decryption rights. |
| Bidder identity | Public/known to Cleanverse; no need to hide. |
| Face amount, due date, buyer confirmation | Public/committed; lenders need common terms. |
| Compliance and A-Token | Not encrypted by Bidnox. Cleanverse remains authoritative. |

Security points to test: ciphertext fee handling; only the submitting wallet may originate its input; handle permissions; no encrypted-boolean branching in Solidity; deterministic tie behavior; auction deadline; one active bid per lender or explicit replacement; reveal permissions; losing handle non-disclosure.

Official Inco references: [encrypted inputs](https://docs.inco.org/guide/input), [library reference](https://docs.inco.org/quickstart/lib-reference), and [attested reveal](https://docs.inco.org/js-sdk/attestations/attested-reveal).

## “Wow” moment ranking

### Practical ranking for this hackathon

1. **C — eligible at bid time, frozen before settlement, transfer blocked.** Strongest proof that Cleanverse is continuous and load-bearing. Requires a safe status fixture.
2. **D — winning capital traced from approved institution deposit to aUSDC mint to seller settlement.** Strongest “clean money” story; slightly harder to understand and execute reliably.
3. **A — explorer shows three opaque handles; close reveals only winner and ₹9.2 lakh.** Most visual, but it showcases Inco more than Cleanverse.
4. **B — unverified lender rejected, then onboarded.** Very clear and reliable, but common among prior winners.
5. **E — buyer-confirmed invoice issued as custom CVA.** Would jump to #1 only if Cleanverse confirms the intended invoice asset and lifecycle. Today it risks being a mislabeled fungible token.

Recommended demo combines B + A + successful settlement. Use C or D as the single headline “wow” only after the fixture works repeatedly.

## Alternatives and win-fit scores

These are strategic scores, not probabilities. Official-category subtotal is weighted to the current rubric; internal dimensions are /10 judgments about hackathon fit.

| Variant | Concept /20 | CVI/CVA /30 | Build /25 | UX /15 | Scale /10 | Win-fit /100 | Diff. | 48h | Privacy | Institution | Sponsor | Demo |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **A. Clean-capital invoice factoring (recommended)** | 18 | 27 | 21 | 14 | 8 | **88** | 9 | 8 | 9 | 9 | 10 | 10 |
| B. General compliant private-credit RFQ | 15 | 27 | 21 | 13 | 9 | 85 | 7 | 8 | 9 | 10 | 10 | 8 |
| C. Per-invoice custom A-Token/CVA marketplace | 18 | 29 | 16 | 13 | 8 | 84 | 9 | 4 | 7 | 9 | 10 | 9 |
| D. Verified supplier-payment escrow | 14 | 25 | 22 | 13 | 8 | 82 | 6 | 9 | 4 | 8 | 9 | 8 |

Why not switch:

- General private credit loses the concrete buyer-confirmed cash flow and looks closer to Ghost Finance.
- Per-invoice A-Token maximizes theoretical sponsor depth but has the highest failure risk and no documented invoice metadata/legal closure.
- Supplier escrow is easier, but prior Cleanverse payments winners already cover verified payment flows; it is less differentiated and less aligned with the RWA track.

The right change is therefore a **refinement**, not a pivot: move from generic invoice financing to buyer-confirmed invoice factoring with provable settlement-capital eligibility.

## Critical hackathon scorecard for the recommended design

This is the design’s ceiling if the P0 demo works; unimplemented features receive no credit in an actual submission.

| Current criterion | Expected | Why it earns points | Where points are lost |
|---|---:|---|---|
| Concept & Problem Definition | **18/20** | Real working-capital problem; defined seller/buyer/financier; economically coherent reverse auction; honest default model. | Invoice truth, authority, underwriting, and legal assignment remain offchain. |
| Depth of CVI/CVA Integration | **27/30** | Repeated A-Pass checks, asset-specific eligibility, actual aUSDC funding/repayment, provenance/report path, possible Validator policy. | Invoice is not itself a confirmed CVA; CCP/Playground mapping and role access remain uncertain. |
| Build Quality | **21/25** | Small state machine, real transfers, encrypted auction, typed signatures, runtime config, failure tests. | Combining Inco and A-Token on one reliable network is nontrivial; direct settlement is not atomic escrow. |
| UX & Demo | **14/15** | Familiar ₹10 lakh story, one rejected lender, opaque bids, reveal, green preflight, payment, evidence timeline. | Compliance density can overwhelm; keep labels short and source-specific. |
| Scalability Potential | **8/10** | Clear institutional pilot, configurable rules, cross-border/chain potential, real factoring analogue. | Licensing, KYB, legal perfection, collections, and integrations are unresolved. |
| **Total** | **88/100** | Strong win-fit, not a forecast. | Falls below 80 quickly if settlement/provenance are mocked or Cleanverse is only a badge. |

### Submission kill conditions

- If bids are plaintext onchain, remove the Inco claim or fix it.
- If aUSDC never moves, do not call it compliant settlement.
- If a frozen/unverified wallet is only blocked in frontend code, do not call it protocol enforcement.
- If the source-of-funds screen only displays an institution list, call it “approved source policy,” not provenance.
- If the invoice is an ordinary Bidnox record, never call it a Cleanverse CVA.
- If legal assignment is absent, never claim the NFT/record gives the lender ownership.

## Competitive differentiation

### Not a Yieldx clone

Yieldx centered on oracle verification, invoice NFT minting, risk scoring, and open USDC funding. Bidnox centers on buyer-signed confirmation, Cleanverse participant/asset eligibility, institution-originated A-Token evidence, and private competitive advance pricing. It deliberately avoids claiming an oracle-verified invoice or generating a risk score.

### Not a Ghost Finance clone

Ghost is generalized collateralized P2P lending with private rates, credit tiers, monitoring, and liquidation. Bidnox finances a fixed buyer receivable, chooses the highest cash advance, has no crypto collateral/liquidation, and makes Cleanverse compliance/provenance the execution perimeter.

### Not an SSL clone

SSL is a dark pool for secondary RWA orders with shield-address settlement and market-price validation. Bidnox is a primary financing reverse auction for one receivable. Participant identity and settlement evidence stay visible; only pre-close bids are confidential.

### Not a generic factoring app

The differentiator is not the three-party workflow—it already exists in TReDS and factoring markets. It is the combination of revocable asset-specific eligibility, approved-source A-Token settlement, verifiable deposit/mint evidence, and confidential price competition on a shared public chain.

### Not a generic KYC marketplace

A-Pass is checked repeatedly and against the settlement asset. A frozen/expired winner cannot settle; an ineligible recipient cannot receive the configured asset. KYC is an execution condition, not a badge.

## Architecture

### Frontend

A single judge-facing web app presents the receivable, participant status, sealed-auction progress, settlement controls, and a source-labeled evidence timeline. Wallets sign the buyer's EIP-712 confirmation and submit encrypted bid inputs. The UI never treats its own badge or cached response as authorization; every value-moving action waits for a fresh backend/contract result.

### Backend

A small server-side Cleanverse adapter calls the public Skills API and credentialed Cooperate API, performs required AES/CBC request handling, normalizes result codes without inventing meanings, and keeps credentials out of the browser. It also builds the canonical receivable digest, stores encrypted commercial documents, records evidence timestamps/hashes, and indexes chain events. Failure at a compliance boundary is fail-closed; historical evidence remains distinguishable from current eligibility.

### Contracts

Keep two narrow Base Sepolia contracts:

1. **Receivable registry/state machine:** stores a canonical fingerprint, document commitment, buyer confirmation digest/signature reference, parties, public terms, auction deadline, winning result, financing/repayment transaction references, and lifecycle state. It enforces one fingerprint, valid state transitions, deadlines, and authorized calls. It is evidence—not a legal assignment or Cleanverse CVA.
2. **Confidential auction:** accepts Inco encrypted advance amounts from admitted lender wallets, maintains the encrypted best offer/winner, applies deterministic ties, and reveals only the winner and winning amount after close. Until Cleanverse confirms a direct Solidity verification interface, admission uses a short-lived server-signed authorization bound to wallet, chain, auction, action, nonce, and deadline; the server issues it only after a fresh Cleanverse check, and the contract verifies it. This is an application enforcement bridge—not a claim that the auction contract queried CVI directly.

P0 financing and repayment use direct aUSDC wallet-to-wallet transfers after fresh eligibility checks on both sender and recipient. The current registry is a non-custodial spender and requires an end-to-end aUSDC test before deployment. Add escrow only if Cleanverse confirms arbitrary contract custody behavior and it survives a separate end-to-end test.

### Cleanverse

Cleanverse is the execution perimeter: runtime chain/token configuration; onboarding; wallet credential and expiry checks; asset-specific transfer eligibility; aUSDC settlement; and, when credentials/fixtures permit, deposit-to-mint provenance, Validator policy, status freeze, and transaction/Travel Rule report. Cleanverse facts are fetched server-side and shown with their exact source and time.

### Inco

Inco Lightning protects only the advance offer and interim best result. It is not used for identity, compliance, documents, balances, settlement, or repayment. Reveal permissions expose the winner and winning advance at close while losing offers remain inaccessible.

### Storage and indexing

- **Onchain public state:** receivable commitment/fingerprint, public financial terms, lifecycle transitions, encrypted bid handles, final winner/advance, and transfer references.
- **Private application storage:** invoice/PO/delivery files, PII, legal agreement, authority evidence, and encrypted evidence payloads. Store only commitments onchain.
- **Indexer:** consumes registry, auction, aUSDC, and Inco events into a read model for the timeline; chain data remains authoritative.
- **Ephemeral/cache:** Cleanverse reads may be cached for display, never reused as the final authorization for bid, settlement, or repayment.

### Data flow

`seller record → buyer typed signature → Bidnox fingerprint/state → lender Cleanverse admission → Inco encrypted bids → reveal → fresh Cleanverse preflight → direct aUSDC financing → indexed evidence → fresh repayment preflight → aUSDC repayment`

## Exact 90-second judge-facing demo

### 0–8s — Problem

“ACME Exports has a buyer-confirmed ₹10 lakh receivable due in 60 days. It needs working capital today.” Show one card, not a dashboard.

### 8–18s — Trust boundary

Show three compact rows: seller A-Pass active; buyer A-Pass active; settlement asset aUSDC from live Cleanverse config. Say: “Cleanverse decides who can participate and which money can settle.”

### 18–28s — Create real auction asset

Buyer clicks **Confirm receivable** and signs the EIP-712 digest. Show fingerprint and `BuyerConfirmed`. Immediately attempt the same canonical receivable and show “Duplicate in Bidnox—blocked.” Say the limitation aloud: “inside Bidnox.”

### 28–37s — Compliance rejection

An unverified lender clicks **Bid**. The action is rejected with the exact Cleanverse result: no A-Pass / asset not eligible. No invented “sanctions” label.

### 37–52s — Confidential competition

Three eligible lenders enter ₹8.8L, ₹9.0L, and ₹9.2L. Switch briefly to explorer/contract state: only Inco handles are visible. “Each lender prices independently; competitors cannot copy the offer.”

### 52–61s — Reveal

Close the auction. Reveal **Lender C, ₹9.2 lakh**. Show “2 losing offers remain private.” This is the visual Inco moment.

### 61–73s — Cleanverse preflight

Show five source-labeled checks in one panel:

- winner eligible for aUSDC — Cleanverse `verify_apass`;
- seller eligible for aUSDC — Cleanverse `verify_apass`;
- aUSDC address/decimals — live config;
- receivable buyer-confirmed — Bidnox signature;
- capital origin — only show “proven” if deposit→mint transaction evidence exists.

### 73–82s — Settle

Transfer ₹9.2 lakh-equivalent aUSDC winner→seller and land on the explorer transaction. State becomes `Funded`.

### 82–88s — Repay

Use a time-jump/demo control clearly labeled “maturity.” Recheck buyer and lender, then transfer ₹10 lakh-equivalent aUSDC buyer→winner. State becomes `Repaid`.

### 88–90s — Close

Show the evidence timeline and say: **“Buyer-confirmed receivable. Private price discovery. Clean capital. Compliance at every movement.”**

## 120-second alternate with the strongest Cleanverse moment

After reveal, freeze the winning lender using a pre-authorized sandbox fixture. Re-run `verify_apass`; settlement turns red and no aUSDC moves. Then either unfreeze/reset the fixture and complete settlement, or automatically award the next eligible bid if that P1 feature is fully tested. Never end with only a broken flow.

## Demo/implementation design rules

- Keep one chain: Base Sepolia. The current hackathon allows any integrated chain, and live config confirms it.
- Use rupees in story/UI but settle a 6-decimal test aUSDC amount; label the conversion as demo-denominated unless a real FX oracle exists.
- Seed three deterministic lender wallets and identity states before recording.
- Cache read results only for UX; re-fetch at every value-moving action.
- Fail closed on Cleanverse timeout at bid/settlement. Display “verification unavailable,” not “failed compliance.”
- Keep API credentials and AES operations server-side.
- Store response hashes/IDs and timestamps in the evidence layer; avoid putting KYC data onchain.
- Every badge needs a provenance label: Cleanverse, Bidnox, Inco, or external/offchain.

## Final answer to the architecture hypothesis

The proposed seller + buyer + lender architecture is sound with these corrections:

- Cleanverse can prove wallet credential state and A-Token transfer eligibility, not company role or invoice truth.
- The invoice should be a Bidnox buyer-confirmed receivable record for P0.
- A custom A-Token issuance path exists for Issue Members, but a single-invoice CVA lifecycle is not documented.
- Approved institution configuration is real; actual source-of-funds provenance requires a matching deposit/mint transaction record.
- Travel Rule/transaction report download is documented; an independently named CCP preflight API is not.
- Direct A-Token settlement is safer than custom escrow until contract custody is confirmed.
- Inco is justified only for sealed advance bids.

The winning product is therefore smaller than the initial vision, but the Cleanverse integration is deeper where it matters: **entry, asset eligibility, capital origination, settlement, revocation, repayment, and evidence**.

## Final go / no-go

**Go—with a narrowed scope.** Build Bidnox as the buyer-confirmed, compliance-native invoice-factoring marketplace defined here. Do not build a generic invoice marketplace and do not represent an invoice as a Cleanverse CVA unless the team confirms and enables the intended issuance model.

The go decision is conditional on proving three P0 integrations in an early spike: (1) the live aUSDC transfer path on Base Sepolia, (2) fresh Cleanverse eligibility checks that visibly change execution, and (3) a real Inco sealed-bid close/reveal. If any one fails early, preserve the product but simplify the mechanism: drop custom provenance/report extras first, use a pre-qualified rejection fixture for compliance, and remove the privacy claim rather than simulating encryption. If actual aUSDC movement cannot be demonstrated at all, this version becomes a no-go for the Cleanverse RWA track because the sponsor integration would be mostly presentational.

## Key sources

- [Current Cleanverse hackathon and rubric](https://cleanverse.com/hackathon)
- [Cleanverse API v5.6 invite](https://docs.cleanverse.com/?code=vhp3FyNV)
- [Cleanverse/ClevrPay public repository](https://github.com/cleanverseorg/clevrpay)
- [RBI TReDS FAQ](https://www.rbi.org.in/scripts/FAQView.aspx/FAQView.aspx/FAQView.aspx?Id=132)
- [RBI Registration of Assignment of Receivables Regulations](https://www.rbi.org.in/Scripts/NotificationUser.aspx?Id=12223)
- [UNCITRAL receivables assignment overview](https://uncitral.un.org/en/texts/securityinterests/conventions/receivables)
- [Inco Lightning concepts and API](https://docs.inco.org/guide/intro)
