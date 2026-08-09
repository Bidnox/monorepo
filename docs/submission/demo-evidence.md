# Live demo evidence

This is the completed Bidnox lifecycle used for the demo. Every transaction below succeeded on Base Sepolia.

| | |
| --- | --- |
| Network | Base Sepolia, chain ID `84532` |
| Receivable | [`RCV-6CDFB8CB`](https://app.bidnox.xyz/receivables/0x6cdfb8cb3b095ac224956ee13bd36c1060ab945abd1ff3d5afb9a6d94001058e) |
| Receivable ID | `0x6cdfb8cb3b095ac224956ee13bd36c1060ab945abd1ff3d5afb9a6d94001058e` |
| Face value | `2 aUSDC` |
| Winning advance | `1.8 aUSDC` |
| Current status | `Repaid` |

## Lifecycle transactions

1. [Seller created the receivable](https://sepolia.basescan.org/tx/0x4e746df0923b624d7738bbf76050f366450a7b591b2f02353d0ac6e84bac0e17)
2. [Buyer confirmed the receivable](https://sepolia.basescan.org/tx/0xf6474f57b8edae18c5c3e436175a270fd7ecea25188d55a9f3106b153393cf81)
3. [Seller opened the auction](https://sepolia.basescan.org/tx/0x3250ab956fdd0092e2b596364ec24935cffcdcf96286fbfa02c208a8bae668f0)
4. [First lender submitted a sealed bid](https://sepolia.basescan.org/tx/0xd9471988794ba7d853a467ab360cf5408c074153e663588136a5fbbead5b9ea4)
5. [Second lender submitted a sealed bid](https://sepolia.basescan.org/tx/0x3786107f592aef1373088b29870380ef9fd2f636de9b2850aaaaa81d1e714a76)
6. [Auction reveal was requested](https://sepolia.basescan.org/tx/0xa89d03a188643249720e8ae7ceef8764e8d0e341a07f3a12aeb91ad7716809e4)
7. [Winner was finalized at 1.8 aUSDC](https://sepolia.basescan.org/tx/0x1c0b73008cd68bbd65c767ee5d8381bf0e134fde06aed011574beed3f1dd6d0b)
8. [Winning lender approved 1.8 aUSDC](https://sepolia.basescan.org/tx/0xbb42e6a0b5f3954905595f14a265d158daa231e3338b3c33d988cfc043c1102c)
9. [Winning lender funded the seller with 1.8 aUSDC](https://sepolia.basescan.org/tx/0x163d2e4ed32e6de43a85f0bc6a3876f96269b88087dfac3dcf706cdbc5a8728d)
10. [Buyer approved 2 aUSDC](https://sepolia.basescan.org/tx/0xe727e65ee1a381c6d19fbda46d3bb5daef572ee96bc5ad37af85fedb5cb6c55b)
11. [Buyer repaid the winning lender with 2 aUSDC](https://sepolia.basescan.org/tx/0x096c5beebcfe1617b2dbd8fb5aa38f4e473d1224328e932ba86d5144071a66a9)

## What the chain proves

- The receivable was created with a face value of `2 aUSDC` and the Cleanverse aUSDC settlement address.
- Both `BidSubmitted` events contain only the auction ID and bidder address. No bid amount appears in either event.
- Finalization revealed the winning lender and the winning amount of `1.8 aUSDC`.
- The losing bid amount does not appear in the bid or finalization events.
- Funding transferred `1.8 aUSDC` from the winning lender to the seller.
- Repayment transferred `2 aUSDC` from the buyer to the winning lender.
- The registry currently reports status `6`, which is `Repaid`.

## Cleanverse evidence

The demo flow calls `verify_apass` before creation, confirmation, each bid, funding, and repayment. It continues only when Cleanverse returns verification result code `4` for the participant and the exact aUSDC contract.

A fresh sandbox check on 9 August 2026 returned code `4` for the seller, buyer, winning lender, and second lender. Cleanverse documents code `4` as a valid A-Pass with transfer allowed for the requested A-Token.

These are sandbox A-Passes created for the hackathon. They should not be described as production KYC, KYB, bank verification, credit approval, or proof that the invoice itself is genuine.

## What to show in the recording

1. Open [`RCV-6CDFB8CB`](https://app.bidnox.xyz/receivables/0x6cdfb8cb3b095ac224956ee13bd36c1060ab945abd1ff3d5afb9a6d94001058e).
2. Show the Cleanverse sandbox A-Pass results and the exact aUSDC address.
3. Open both sealed bid transactions and show that each event contains only the auction ID and bidder.
4. Open the finalization transaction and show the public winner and `1.8 aUSDC` winning amount.
5. Explain that the losing bid amount remains absent from public events. Do not disclose its plaintext value in the recording.
6. Open the funding and repayment transactions and show the aUSDC `Transfer` events.
7. Finish on the `Repaid` status and the evidence timeline.
