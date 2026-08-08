# Bidnox — compliant confidential receivables financing

## Problem

Small suppliers wait weeks for invoice payment, while financiers hesitate because invoice markets expose pricing, duplicate documents are hard to detect, and identity/asset compliance is often checked only at onboarding. A seller-uploaded PDF is also not enough evidence that the buyer accepts the debt.

## Solution

Bidnox turns a buyer-confirmed receivable into a confidential financing auction. The seller records a document hash and invoice fingerprint, the buyer confirms the exact terms with an EIP-712 signature, and lenders submit Inco-encrypted bids. The contract selects the best bid without exposing losing amounts. The winner funds the seller in Cleanverse Access USDC, and the buyer later repays the financier in the same asset.

## Cleanverse CVI and CVA integration

- CVI / A-Pass: seller, buyer, and financier each hold an active Base sandbox A-Pass. Bidnox calls `verify_apass` at action boundaries and received eligibility code `4` for the participants used in settlement and repayment.
- CVA / A-Token: contracts pin the exact Base Sepolia aUSDC token `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`. The financier-to-seller advance and buyer-to-financier repayment are real ERC-20 transfers, not UI simulations.
- Enforcement bridge: short-lived EIP-712 compliance permits bind wallet, action, receivable/auction subject, asset, validity window, and one-time nonce. Contracts reject wrong wallets, actions, subjects, assets, expired permits, bad signers, and replayed nonces.
- Server boundary: Cleanverse credentials and privileged faucet actions remain server-only. The faucet accepts fixed demo roles, never an arbitrary browser-selected address.

## Build and security

The Base Sepolia deployment separates deployer, owner, and compliance signer. Ownership uses two-step acceptance. The registry pins its settlement asset and auction contract, applies checks-effects-interactions and reentrancy protection, prevents duplicate fingerprints, requires buyer confirmation, caps advances at face value, and rechecks both sides at funding and repayment. Inco uses TEE-based confidential execution; bid events contain no amount, and only the winning value/index are publicly revealed.

The Foundry test profile passes 92 tests, including fuzz and invariant suites.

## Live result

One real lifecycle completed on Base Sepolia with two confidential bids. The winning advance was `1.8 aUSDC`; the seller received it, the buyer repaid `2 aUSDC`, and registry status is `Repaid`. The frontend includes the Cleanverse token icon, exact token/contract addresses, and BaseScan-linked evidence.

## Deployment

- ComplianceGate: `0x12badb8fd1828AB70Ea5FD4F5142Bc8c9e8f537d`
- ReceivableRegistry: `0xCad5d39Dc42757969323608a9207B283dbDE3b37`
- ConfidentialAuction: `0xDA6F7Fe360f7700d6E0d867bDC7f51C048E33c82`
- Inco executor: `0x4b9911b0191B0b6a6eA8F2Ed562e20Cff5AC8624`
- Cleanverse aUSDC: `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`
- Chain: Base Sepolia (`84532`)

## Scalability

The compliance permit layer is provider-agnostic, document contents stay offchain, and the onchain registry stores hashes and lifecycle state. Production work would add persistent server-side audit storage, real KYB/authority evidence, underwriting and legal assignment documents, and monitored signer rotation.
