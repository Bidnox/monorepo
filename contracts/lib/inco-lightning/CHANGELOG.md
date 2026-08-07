# Changelog

## 1.1.0

- Add DecryptionAttester to IncoVerifier
- Merge EOA signers from SignatureVerifier and TEELifecycle
- IncoLightning to allow multiple signers + threshold

## 1.0.2

- Inco Fees on:
  - rand()
  - randBounded()
  - newEuint256()
  - newEbool()
  - newEaddress()

## 1.0.0

- **State breaking change** - Contract Split between Executor and Verifier

## 0.1.32

- Fix up wrong values for demonet keys and addresses

## 0.1.31

- Implement batching callbacks with `DecryptionHandler.sol` as source-of-truth for pending callbacks [#629](https://github.com/Inco-fhevm/inco-monorepo/pull/629) [#616](https://github.com/Inco-fhevm/inco-monorepo/pull/629)

## 0.1.29

- Publish contracts with verification [#535](https://github.com/Inco-fhevm/inco-monorepo/pull/535)

## 0.1.20

- Bug fix in EIP712 signature verification in Advanced ACL. [#485](https://github.com/Inco-fhevm/inco-monorepo/pull/485)

Note: version 0.1.18 and 0.1.19 are unused, and were part of testing purposes only.

## 0.1.17

- Add deployment of `SessionVerifier` as part of the IncoLite deployment.

## 0.1.16

- Added missing arithemetic, bitwise, and random operations to IncoLib

## 0.1.15

- Same deployment as 0.1.13, but deployed across both Base Sepolia and Monad Testnet.

## 0.1.14

- **This deployment is a test deployment, and should not be used.** [#378](https://github.com/Inco-fhevm/inco-monorepo/pull/378) Test the new multi-chain deployments. No changes over 0.1.13.

## 0.1.13

"Advanced" access control first iteration, provides a way for accounts (EOAs / Smart Wallets / Contracts) to share their read access to handles with arbitrary logic using onchain or offchain signatures

## 0.1.10

- Update contract deployment logic to include ECIES public key and also to set the callback signer address on deployed contracts

## 0.1.2

Type embedding in handle after trivial encrypts and operations is consistent with zama

## 0.1.1

Embed type into every handle. Check handle type on every op.
