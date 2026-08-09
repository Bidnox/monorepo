# Bidnox

**Confidential invoice financing with Cleanverse compliance and settlement**

| | |
| --- | --- |
| Track | RWA |
| Network | Base Sepolia, chain ID `84532` |
| Live app | [app.bidnox.xyz](https://app.bidnox.xyz) |
| Repository | [github.com/Bidnox/monorepo](https://github.com/Bidnox/monorepo) |
| Demo video | [Watch the Bidnox demo](https://youtu.be/Lt_ngj1-b0w) |

## The problem

Small suppliers often wait weeks for invoices to be paid. Financing can help, but existing processes expose lender pricing and make it difficult to prove that an invoice is genuine, accepted by the buyer, and connected to verified participants.

A PDF uploaded by a seller is not enough. The buyer should confirm the debt, lenders should be able to compete without revealing their offers, and every payment should use an approved asset.

## What Bidnox does

Bidnox turns a buyer-confirmed invoice into a sealed financing auction.

1. The seller creates a receivable and records the invoice fingerprint on Base Sepolia.
2. Cleanverse checks the seller and buyer before issuance.
3. The buyer signs the exact invoice terms.
4. Verified lenders submit bids encrypted with Inco.
5. The contract selects the best eligible offer without publishing losing bids.
6. The winning lender funds the seller in Cleanverse aUSDC.
7. The buyer later repays the lender in aUSDC.

## How Cleanverse is used

**CVI and A-Pass**

Seller, buyer, and lender eligibility is checked at the actions that matter. Bidnox verifies each participant through the Cleanverse sandbox and issues a short-lived permit for that wallet and action.

**CVA and aUSDC**

The contracts accept the Cleanverse Base Sepolia aUSDC token at `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`. The lender advance and buyer repayment are real ERC-20 transfers. They are not simulated UI events.

**Onchain enforcement**

Each permit is bound to a wallet, action, receivable, settlement asset, expiry time, and one-time nonce. The contracts reject expired permits, reused permits, incorrect participants, and unsupported assets. Cleanverse credentials and the compliance signing key remain on the server.

## Privacy and security

Inco encrypts each bid before it is submitted. Bid events do not contain the bid amount. When the auction finishes, only the winning lender and winning amount become public. Losing bids remain sealed.

The contracts also:

- require buyer confirmation before financing;
- prevent duplicate invoice fingerprints;
- cap the advance at the invoice face value;
- pin the settlement token and auction contract;
- protect token transfers against reentrancy;
- separate the deployer, owner, and compliance signer.

The Foundry test profile passes 92 tests, including fuzz and invariant tests.

## Live result

We completed one full lifecycle on Base Sepolia with two confidential bids. The winning lender sent `1.8 aUSDC` to the seller. The buyer later repaid `2 aUSDC`, and the receivable reached the `Repaid` state.

The app links the invoice evidence, contract addresses, token address, and transaction history from the receivable page.

## Deployment

| Contract | Address |
| --- | --- |
| ComplianceGate | `0x12badb8fd1828AB70Ea5FD4F5142Bc8c9e8f537d` |
| ReceivableRegistry | `0xCad5d39Dc42757969323608a9207B283dbDE3b37` |
| ConfidentialAuction | `0xDA6F7Fe360f7700d6E0d867bDC7f51C048E33c82` |
| Inco executor | `0x4b9911b0191B0b6a6eA8F2Ed562e20Cff5AC8624` |
| Cleanverse aUSDC | `0xaC0893567D43C3E7e6e35a72803df05416C1f20D` |

## What comes next

For production, Bidnox would add persistent audit records, KYB and signing-authority checks, underwriting workflows, legal assignment documents, and monitored signer rotation.
