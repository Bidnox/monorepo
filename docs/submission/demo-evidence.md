# Live demo evidence

Network: Base Sepolia (`84532`)

Receivable: `0x6cdfb8cb3b095ac224956ee13bd36c1060ab945abd1ff3d5afb9a6d94001058e`

## Lifecycle

- Created: https://sepolia.basescan.org/tx/0x4e746df0923b624d7738bbf76050f366450a7b591b2f02353d0ac6e84bac0e17
- Buyer confirmed: https://sepolia.basescan.org/tx/0xf6474f57b8edae18c5c3e436175a270fd7ecea25188d55a9f3106b153393cf81
- Secondary lender sealed bid: https://sepolia.basescan.org/tx/0xd9471988794ba7d853a467ab360cf5408c074153e663588136a5fbbead5b9ea4
- Winning financier sealed bid: https://sepolia.basescan.org/tx/0x3786107f592aef1373088b29870380ef9fd2f636de9b2850aaaaa81d1e714a76
- Reveal requested: https://sepolia.basescan.org/tx/0xa89d03a188643249720e8ae7ceef8764e8d0e341a07f3a12aeb91ad7716809e4
- Winner finalized at `1.8 aUSDC`: https://sepolia.basescan.org/tx/0x1c0b73008cd68bbd65c767ee5d8381bf0e134fde06aed011574beed3f1dd6d0b
- Financier aUSDC approval: https://sepolia.basescan.org/tx/0xbb42e6a0b5f3954905595f14a265d158daa231e3338b3c33d988cfc043c1102c
- Seller funded `1.8 aUSDC`: https://sepolia.basescan.org/tx/0x163d2e4ed32e6de43a85f0bc6a3876f96269b88087dfac3dcf706cdbc5a8728d
- Buyer aUSDC approval: https://sepolia.basescan.org/tx/0xe727e65ee1a381c6d19fbda46d3bb5daef572ee96bc5ad37af85fedb5cb6c55b
- Buyer repaid `2 aUSDC`: https://sepolia.basescan.org/tx/0x096c5beebcfe1617b2dbd8fb5aa38f4e473d1224328e932ba86d5144071a66a9

## What to show in the recording

1. Open the `BASE-SEPOLIA-LIVE` receivable in the frontend.
2. Show the Cleanverse aUSDC icon and exact address.
3. Show the two `BidSubmitted` transactions: neither event exposes an amount.
4. Show winner finalization at `1.8 aUSDC`; explain that the losing `1.6 aUSDC` bid was never publicly revealed.
5. Open the funding and repayment transactions and show aUSDC transfers.
6. Show final registry status `Repaid` and the source-labeled evidence timeline.

Cleanverse returned `verify_apass` data code `4` for the demo wallets at the relevant action boundaries. These are sandbox credentials and must not be described as production bank verification.
