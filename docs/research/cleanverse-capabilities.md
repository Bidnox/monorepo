# Cleanverse capability map for Bidnox

Research date: 2026-08-07 (Asia/Kolkata). This document separates what the current documentation actually exposes from hackathon marketing and from assumptions. It is not legal advice.

## Executive finding

Cleanverse has two documented developer surfaces:

1. The public **Skills API** is a small, working payments-oriented API for A-Pass onboarding/status, wallet/deposit mapping, the live chain/token registry, and approved deposit institutions.
2. The invite-only **Cooperate API v5.6** is a much larger, credentialed API. It documents A-Pass issuance/freezing, custom A-Token issuance and rules, a compliance-validator registry for application contracts, asset-specific eligibility checks, institutional deposit evidence, A-Token reports, and Travel Rule report downloads. Access depends on an issued `api-id`, AES key, integration role, and sometimes an approval workflow.

For Bidnox, the strongest confirmed combination is **A-Pass participant eligibility + A-Token settlement + institution-originated deposit evidence + repeated eligibility checks**. Cleanverse does not, by itself, prove an invoice is real, establish creditworthiness, or create the legal assignment of a receivable.

## Source hierarchy

- Live `query_chain_config` response is authoritative for current sandbox chains, addresses, and tokens.
- The invite-only [Cleanverse API v5.6 documentation](https://docs.cleanverse.com/?code=vhp3FyNV) is authoritative for the credentialed Cooperate API.
- The public [ClevrPay repository](https://github.com/cleanverseorg/clevrpay) is authoritative for the smaller Skills API and its published boundaries.
- The current [Trusted Assets hackathon page](https://cleanverse.com/hackathon) is authoritative for track language and judging claims, but a capability advertised there is not treated as a callable API until an endpoint or contract is documented.

The hackathon page calls its docs “v3,” while the invited document currently renders “API v5.6.” The repository also warns that static chain tables can drift. Implementations must therefore discover configuration at runtime.

## Terminology: what can safely be said

| Hackathon/product term | Documented implementation term | Safe usage |
|---|---|---|
| CVI, Cleanverse Verified Identity | A-Pass / APASS | Say “CVI-backed eligibility through the documented A-Pass flow” in the pitch. Use `apass`, `query_apass`, and `verify_apass` in code. Do not state that A-Pass and every possible CVI are definitionally identical; the docs do not explicitly make that equivalence. |
| CVA, Cleanverse Verified Assets | A-Token / wrapped A-Token | Say “CVA settlement using the documented A-Token rail.” In code and contracts use A-Token addresses returned by live config. Do not claim every CVA is an A-Token, or that a custom A-Token automatically carries a legally valid RWA claim. |
| CCP Protocol | Validator Compliance, A-Token rules, `verify_apass`, Travel Rule/report endpoints may implement parts of the advertised behavior | Do not label any one of these “the CCP endpoint” without confirmation. The private docs do not expose a module named CCP. |
| Gateway Network | deposit addresses, institution whitelists, institutional transaction lookup, Access Core, and fiat-ramp APIs | These are concrete gateway-related pieces. Do not claim a particular licensed fiat corridor is usable until a live quote/widget works. |
| Playground | no developer endpoint or export format found | Marketing-only for now. |

Recommended language by surface:

- **Contracts/code:** `APass`, `AToken`, `AccessCore`, `Validator`, and the exact API route names.
- **UI:** “Cleanverse identity: active/frozen/expired,” “eligible for this A-Token,” “A-Token settlement,” and “approved deposit source.”
- **Pitch:** “Bidnox integrates CVI and CVA through Cleanverse’s documented A-Pass and A-Token rails.”
- **Avoid:** “Cleanverse verified this business,” “Cleanverse verified this invoice,” “Cleanverse guarantees clean funds,” or “CCP passed” unless the exact corresponding response is present.

## Confirmed available

### Public Skills API

Sandbox base: `https://uatapi.cleanverse.com/api/skills`. The repository documents response codes `0000` success, `0001` parameter error, and `0002` general failure. It says chain/address/symbol inputs should be lowercase unless an endpoint says otherwise.

| Primitive | Exact route | Confirmed behavior | Bidnox use | Boundary |
|---|---|---|---|---|
| Magic-link onboarding | `POST /get_magiclink` | Returns `data.register_url`. | Send an unverified participant through Cleanverse onboarding. | It does not return a credential immediately; Bidnox must re-query after the human completes onboarding. |
| A-Pass lookup | `POST /query_apass` | Returns `cvRecordId`, `expirationTime`, `tier`, `subTier`, `group`, `subGroup`, `state`, and `currentKycHash`. Public docs define state `1` active and `2` frozen. | Gate seller/buyer/lender actions and visibly recheck status before money moves. | No semantics are documented for specific tier/group values. Expiration must be evaluated from the timestamp. No other state values are documented. |
| Wallet/deposit mapping | `POST /query_user` | Returns `user_address`, `deposit_address`, `deposit_address_status`, account `status`, and `blacklist_reason`. | Confirm that a wallet is registered and show a returned blacklist reason if one exists. | The public docs do not define the `status` or `deposit_address_status` enums. The example has status `0` and an empty reason. Do not translate arbitrary values to “blocked” without documentation or a known test fixture. |
| Register wallet mapping | `POST /register_data` | Registers chain/symbol/address and returns the mapped deposit address. | Prepare lender and buyer wallets for deposits. | This is a backend mapping, not proof of identity or provenance. |
| Deposit-address lookup | `POST /query_deposit_address` | Returns deposit addresses for supported origin tokens and A-Pass address data. | Give a verified lender the correct gateway address. | Receiving an address does not prove a later deposit came from an approved institution. |
| Approved deposit institutions | `POST /query_deposit_institutions` | Returns origin/A-Token pairs and an institution whitelist with service/legal entity/category. | Show which sources are permitted for a particular origin token and A-Token pair. | The list is eligibility/configuration, not transaction-specific provenance. A specific deposit transaction is needed to prove actual source. |
| Live network configuration | GET or POST `/query_chain_config` | Returns chains, IDs, RPC/explorer, A-Pass, operator addresses, tokens, decimals, Access Core, and deposit gateway. | Resolve every address and token dynamically. | Do not hardcode static tables or infer production support from sandbox support. |

### `query_apass` field meanings

| Field | Documented meaning | What Bidnox may infer |
|---|---|---|
| `cvRecordId` | Cleanverse/CV registration record identifier. | Stable reference for audit correlation; not a public identity or business registration number. |
| `expirationTime` | Unix timestamp in seconds. | Credential is time-valid only if current time is before it. |
| `tier` | A-Pass tier, string in query response; policy endpoints treat it numerically from 0–99. | Only compare against a rule explicitly supplied by Cleanverse/the issuer. Do not call a tier “institutional,” “business,” or “accredited” without a configured taxonomy. |
| `subTier` | A-Pass sub-tier. | Same restriction as tier. |
| `group` | Group name/value. | May be used by configured A-Token or Validator rules. Its business meaning is not documented. |
| `subGroup` | Sub-group name/value. | Same restriction as group. |
| `state` / private-doc `status` | `1` active, `2` frozen. | Frozen is a valid continuous-compliance failure state. No revoked/suspended numeric states were found. |
| `currentKycHash` | Hash of current KYC data. | Evidence that a hash exists and a way to detect change; not the KYC data, a credit score, or proof of invoice validity. |
| `countries` (v5.6 Cooperate API) | ISO-3166-1 alpha-2 tags derived from identity-document issuing countries. | Apply only an explicit allow/deny rule. Issuing country is not necessarily residence, incorporation, tax domicile, or transaction jurisdiction. |

The v5.6 `generate_apass` schema lists personal identity documents (`ID_CARD`, `PASSPORT`, `DRIVER_LICENSE`, etc.) and bank accounts. The hackathon page advertises KYC/KYB support, but the API document reviewed does not define a company/KYB record schema. Therefore, Bidnox must describe a wallet/controller as A-Pass verified, not a company as KYB-verified, until the team confirms otherwise.

### Credentialed Cooperate API v5.6

Base path: `{environment_url}/api/cooperate`, with sandbox `https://uatapi.cleanverse.com/api/cooperate`. All calls require `api-id`; write calls often require an AES/CBC-encrypted body using a separately issued `api-key`. Endpoint access is role-scoped:

- **Issue Member:** A-Pass management, A-Token management, Validator Compliance, fiat ramp, common queries.
- **Gateway Member:** A-Pass management and common queries.
- **Service Partner:** common queries only.

Live sandbox testing on 2026-08-08 confirmed that the Bidnox credentials can use A-Pass Management and Common Query endpoints, including `generate_apass`, `verify_apass`, and `faucet`. That proves the account has at least the relevant Gateway/Issue permissions, but it does not distinguish the exact assigned role or establish access to A-Token Management and Validator mutations.

#### Identity and continuous compliance

- `POST /generate_apass`: creates an A-Pass entry from wallet, identity, and optional bank-account data.
- `POST /update_status`: activates/unfreezes (`1`) or freezes (`2`) an A-Pass, with optional `blacklistReason`.
- `POST /query_apass_list`: institution-scoped registration list and status/tier/group/countries/transaction data.
- `POST /query_apass`: flat A-Pass record lookup.
- `POST /verify_apass`: evaluates a wallet specifically against an A-Token/wrapped A-Token. Result codes are: `1` A-Token not found, `2` no A-Pass, `3` A-Pass exists but cannot transfer because expired/frozen, `4` success and transfer allowed.

For Bidnox, `verify_apass` is better than inventing a local interpretation of tier/group. It answers the actual execution question: can this wallet use this settlement asset?

#### Custom A-Token issuance and policy

- `POST /atoken/launch`: submits a new fungible A-Token issuance application with name, symbol, decimals, admin, one compliance rule, icon, and optional callback.
- `POST /atoken/register_atoken`: submits an existing A-Token contract for registration.
- Wrapped equivalents bind an origin token to a wrapped A-Token and Access Core flow.
- Application status must reach `ISSUED`; submission alone is not issuance. After issuance, the admin grants `MINTER_ROLE` to its minter.
- `/atoken/add_rule`, `/atoken/rules`, and `/atoken/remove_rule` manage rules based on `allowed_group`, `allowed_sub_group`, numeric tier thresholds, and optional country allow/deny lists.
- `/atoken/set_paused` and its read endpoint pause/query an entire A-Token.
- Institutional deposit-whitelist endpoints control which origin-token senders may trigger wrapped A-Token conversion.

This confirms developers with **Issue Member** access can apply to issue custom fungible compliant assets. It does not confirm that a single invoice should be represented this way. No invoice/RWA metadata schema, non-fungible token interface, legal-document attachment, per-receivable burn/close API, or assignment-of-claim primitive was found.

#### Validator Compliance for an application contract

The v5.6 docs expose an “APass Compliance Validator” module:

- `POST /validator/register`: register an Ownable application/pool contract and initial A-Pass rule.
- `/validator/set_rule`, `/add_rule`, `/remove_rule`, `/rules`: manage/query eligibility rules.
- `POST /validator/verify`: returns `data.valid: true|false` for a user against a registered contract.
- `/validator/set_paused` and `/is_paused`: pause/query the pool’s compliance checks.

This is directly relevant to Bidnox: the auction/market contract can potentially be registered as a compliance pool, and lenders can be checked against its configured policy. It is not self-proving enforcement inside Bidnox: the reviewed docs show API-mediated reads/writes, but do not include the Validator Solidity ABI or a sample demonstrating a Bidnox contract calling it synchronously. Confirm the intended enforcement pattern before describing it as on-chain entry gating.

#### Capital provenance and reports

- `POST /query_deposit_atoken_list`: authoritative origin/A-Token pairs, AccessCore, and A-Pass addresses.
- `POST /query_institution_txs`: returns institutional deposit/withdraw records. A deposit commonly contains an origin-token transfer plus an A-Token mint.
- `POST /download_travel_rule`: for a withdraw transaction hash returns a Travel Rule report; for an A-Token/wrapped A-Token transfer hash returns a transaction report. Response contains a time-limited `downloadUrl` and `fileName`.
- `POST /faucet`: requests sandbox tokens to a deposit address where applicable.

The strongest honest “clean capital” proof is not the institution list alone. It is this chain of evidence:

`approved institution config` → `lender deposit address` → `origin-token transfer from institution` → `A-Token mint to lender` → `A-Token settlement transfer`.

#### Access Core

The public repository provides only this ABI:

```solidity
withdraw(address aToken, uint256 amount, address recipient)
```

and a `Withdraw` event containing A-Token, origin token, amount, recipient, and data. Documented purpose: burn/convert a wrapped A-Token back to its supported origin token and send that origin token to a recipient. The docs do not expose deposit or arbitrary escrow functions on Access Core. For Bidnox, withdrawal is a useful final lifecycle coda only after core financing and repayment work; it is not part of the auction.

### Live sandbox snapshot

The live Skills API was queried on 2026-08-07. It returned seven networks:

| Key | Live test network / chain ID | Explorer | Core settlement support observed |
|---|---:|---|---|
| `base` | Base Sepolia / 84532 | `sepolia.basescan.org` | USDC/aUSDC |
| `ethereum` | Ethereum Sepolia / 11155111 | `sepolia.etherscan.io` | USDC, USDT, aUSDC, aUSDT |
| `polygon` | Polygon Amoy / 80002 | `amoy.polygonscan.com` | USDC, USDT, aUSDC, aUSDT |
| `bsc` | BNB testnet / 97 | `testnet.bscscan.com` | USDC, USDT, aUSDC, aUSDT |
| `solana` | Solana devnet / -1 | `solscan.io/?cluster=devnet` | USDC, USDT, aUSDC, aUSDT |
| `hashkey` | HashKey testnet / 133 | `testnet-explorer.hsk.xyz` | USDC, USDT, aUSDC, aUSDT |
| `monad` | Monad testnet / 10143 | `testnet.monadvision.com` | USDC/aUSDC |

The current hackathon page displays Arbitrum among integrated chains and the public skill’s static table also mentions it, but the live configuration returned no Arbitrum entry. Live config wins: do not build on Arbitrum unless it appears when queried again.

For the recommended Base Sepolia implementation, live config returned:

- A-Pass: `0xbA82D189540CaC9DC6FF46B6837CaC1BFdEC58B9`
- origin USDC: `0x543b96420d072BF587B63C41C0B0922762E986Ce`, 6 decimals
- aUSDC: `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`, 6 decimals
- Access Core: `0x8F118338a1fa41E7Fa86Be19A4e8B99Ed58A6EcC`
- deposit gateway: `0x8e084646080a35347B2D053Dd72F550f12245c8B`

These are a dated research snapshot, not constants to copy into product code.

The live Base/USDC institution query returned real-name entries including Anchorage Digital, BitGo, Circle, Coinbase, and others, plus obvious sandbox/test entries. The UI must identify the response as a **sandbox whitelist** and must not imply a named institution endorsed Bidnox or actually funded a test transaction.

## Hackathon advertised

The [current hackathon page](https://cleanverse.com/hackathon) advertises the following, but not every item is mapped to a developer endpoint in the reviewed materials:

- CVI: wallet-bound, bank-verified identity proofs, local-only PII, revocable credentials.
- CVA: verified stablecoins/assets with clean origination, programmable rules, and traceability.
- CCP: pre-transaction checks, Travel Rule data, and extractable audit reports.
- Playground: rule-engine design, transaction-flow validation, and audit report generation.
- API/SDK for CVI, CVA, Gateway, Travel Rule, and reporting.
- Gateway Network for licensed on/off ramps.
- Clean Payment Rails including escrow and merchant acceptance guarantees.
- KYC/KYB, AML, Travel Rule support and audit reports.
- RWA issuance with accredited-investor whitelisting and transfer restrictions.
- Starter kit and sample contracts.

Parts of these claims have concrete v5.6 equivalents (A-Token rules, Validator verification, status freezing, reports, fiat ramp). “CCP” and “Playground” are still kept in this category because those product names and their complete workflows are not exposed as such in the API document.

## Unknown

1. Whether the hackathon credentials are specifically Issue Member or Gateway Member. A-Pass Management and Common Queries work; A-Token Management and Validator write access have not been tested.
2. Whether A-Pass is the complete implementation of CVI, and A-Token the complete implementation of CVA, or only product-specific subsets.
3. The official semantic taxonomy for `tier`, `subTier`, `group`, and `subGroup`; specifically, whether any values mean business, financier, accredited investor, or other roles.
4. Whether the sandbox supports a true company/KYB credential rather than a natural person/controller credential.
5. Which documented endpoints Cleanverse considers CCP, and whether there is a distinct preflight API that returns reason codes, sanctions decisions, originator/beneficiary data requirements, and a policy decision.
6. Whether Travel Rule information is created automatically on A-Token transfer/withdraw, how originator and beneficiary data are supplied, and whether the report download is sufficient for the hackathon’s advertised “pre-transaction” story.
7. A developer-accessible Playground URL/API, rule export format, and how a Playground policy binds to Validator or A-Token rules.
8. The starter-kit/sample-contract repository advertised by the hackathon. The public GitHub organization exposed only `clevrpay` during this review.
9. The Validator contract address/ABI and recommended Solidity enforcement pattern.
10. Whether arbitrary app contracts may safely custody aUSDC and pass A-Token receiver rules; this determines whether escrow/atomic settlement is viable.
11. Whether Bidnox can get an issuance application auto-approved within 48 hours and whether a per-invoice A-Token is an intended pattern.
12. How custom A-Tokens encode RWA legal metadata, issuer attestations, unique receivable IDs, lifecycle closure, redemption, or burn.
13. Which fiat-ramp markets and payment methods are actually enabled in the team’s sandbox credentials.
14. Whether a freeze/blacklist fixture may be safely manipulated during the demo.

## Not supported or not exposed in reviewed docs

- No documented A-Pass states other than active (`1`) and frozen (`2`). Expiry is a timestamp, not a documented third state.
- No documented meaning for public `query_user.status`; status `0` must not be called active/blocked without confirmation.
- No public Skills API route for CCP, Validator, A-Token issuance, Travel Rule creation/download, audit export, Playground, or fiat ramp.
- No documented invoice-verification, invoice-oracle, purchase-order matching, goods-delivery proof, or buyer-authority verification.
- No documented credit scoring, underwriting, default prediction, collections, insurance, or guarantee.
- No documented legal assignment of the receivable. A token/registry entry does not itself prove the financier owns an enforceable claim.
- No documented non-fungible invoice-CVA API or asset-specific metadata schema.
- No documented endpoint to close/burn a custom invoice asset after repayment. Access Core withdrawal burns/converts wrapped settlement A-Tokens; that is a different lifecycle.
- No documented cross-platform duplicate-invoice registry. A Bidnox fingerprint only prevents duplicates within Bidnox.
- No documented Cleanverse audit report for arbitrary Bidnox actions such as upload, buyer approval, bid, or default. Those belong in a clearly labeled Bidnox evidence timeline.
- The public Access Core ABI exposes only `withdraw`; it is not a general escrow API.

## Can the invoice itself be a CVA?

**Narrow technical answer:** the v5.6 API confirms an Issue Member can apply to launch a custom fungible A-Token and attach transfer rules. It does not confirm a single invoice can be issued as a Cleanverse-native, legally meaningful CVA with unique invoice metadata and a close/burn lifecycle.

**Recommendation:** for the 48-hour build, use a Bidnox `InvoiceRegistry`/receivable record and use Cleanverse for participant eligibility, application policy (if Validator access exists), capital origination, and settlement. Describe the record as **buyer-confirmed**, not Cleanverse-verified. Put per-invoice A-Token issuance in a contingent experiment only if the Cleanverse team confirms the intended pattern and provides Issue Member access plus a fast approval path.

## Relevance ranking for Bidnox

1. `verify_apass` against live aUSDC immediately before bid eligibility and settlement.
2. Actual aUSDC transfer for financing and repayment.
3. `query_chain_config` as the sole address/token source.
4. A-Pass rechecks at lifecycle transitions, with a visible frozen/expired rejection.
5. `query_deposit_institutions` plus `query_institution_txs` to prove the winner’s aUSDC mint came from an approved source.
6. Validator registration/rules/verify for the Bidnox market contract, if Issue Member access is granted.
7. `download_travel_rule`/transaction report for the actual settlement hash.
8. Access Core withdrawal only as a post-repayment epilogue.
9. Custom A-Token issuance only after all of the above works and the team confirms invoice suitability.

## Primary sources

- [Cleanverse Trusted Assets hackathon](https://cleanverse.com/hackathon)
- [Cleanverse API v5.6 invite](https://docs.cleanverse.com/?code=vhp3FyNV)
- [Cleanverse/ClevrPay repository](https://github.com/cleanverseorg/clevrpay)
- [ClevrPay API reference](https://github.com/cleanverseorg/clevrpay/blob/main/skills/clevrpay/references/api-doc.md)
- [ClevrPay boundaries](https://github.com/cleanverseorg/clevrpay/blob/main/skills/clevrpay/references/retrieval-and-boundaries.md)
- [Access Core ABI](https://github.com/cleanverseorg/clevrpay/blob/main/skills/clevrpay/references/access_core.md)
