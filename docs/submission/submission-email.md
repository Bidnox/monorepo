To: isaac@cleanverse.com
Subject: Cleanverse Build submission: Bidnox

Hi Cleanverse team,

We are submitting Bidnox for the RWA track of Cleanverse Build: Trusted Assets.

Bidnox helps suppliers finance buyer-confirmed invoices through a sealed auction. Verified lenders compete without seeing one another's offers, the best eligible offer wins, and financing and repayment settle in Cleanverse aUSDC.

Submission links

- Public GitHub: https://github.com/Bidnox/monorepo
- Live product: https://app.bidnox.xyz
- Demo video: https://youtu.be/Lt_ngj1-b0w
- One-page summary: https://github.com/Bidnox/monorepo/blob/main/docs/submission/one-page-summary.md
- Slide deck: https://github.com/Bidnox/monorepo/blob/main/bidnox-slides.pdf
- Onchain demo evidence: https://github.com/Bidnox/monorepo/blob/main/docs/submission/demo-evidence.md

Cleanverse integration

- CVI: Bidnox checks the Cleanverse sandbox A-Pass of each required participant during receivable issuance, buyer confirmation, bidding, funding, and repayment.
- CVA: The winning lender funds the seller in Cleanverse aUSDC, and the buyer repays the lender with the same asset.
- Enforcement: Short-lived permits bind each eligibility check to the wallet, action, receivable, settlement asset, expiry time, and one-time nonce. The contracts reject expired or reused permits.

Inco keeps each lender's offer encrypted during the auction. Only the winning lender and winning amount become public after finalization. Losing bid amounts remain sealed.

We completed one full lifecycle on Base Sepolia with two confidential bids. The winning lender sent 1.8 aUSDC to the seller, the buyer repaid 2 aUSDC, and the receivable reached the Repaid state. The demo evidence page links every transaction.

Deployment

- Chain: Base Sepolia, chain ID 84532
- ComplianceGate: 0x12badb8fd1828AB70Ea5FD4F5142Bc8c9e8f537d
- ReceivableRegistry: 0xCad5d39Dc42757969323608a9207B283dbDE3b37
- ConfidentialAuction: 0xDA6F7Fe360f7700d6E0d867bDC7f51C048E33c82
- Cleanverse aUSDC: 0xaC0893567D43C3E7e6e35a72803df05416C1f20D

Team

- Vivek Sahu: https://github.com/vwakesahu
- Vishal Sah: https://github.com/weshallsah

Thank you for reviewing Bidnox.

Regards,
The Bidnox team
