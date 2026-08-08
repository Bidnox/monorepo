## Bidnox contracts

Base Sepolia contracts for buyer-confirmed receivables, Inco Lightning sealed-bid auctions, and direct
Cleanverse aUSDC settlement.

Security-relevant behavior:

- the settlement asset is immutable and the deployment script pins Base Sepolia to Cleanverse aUSDC
  `0xaC0893567D43C3E7e6e35a72803df05416C1f20D`;
- funding and repayment use exact ERC-20 `transferFrom` calls, so state cannot advance from a backend signature alone;
- every create, confirm, bid, fund, and repay operation consumes a short-lived, action-bound compliance permit;
- the compliance gate can be paused by its owner;
- auctions require a non-zero seller reserve, recover cleanly when empty or below reserve, and release an unfunded
  winner after the one-day funding window;
- invoice document bytes are evidence, but changing `documentHash` does not change the duplicate fingerprint.

The funding and repayment transaction hash is the transaction that calls `fundReceivable` or `repayReceivable`;
index it from the chain rather than accepting a caller-supplied hash.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```sh
forge build
```

### Test

```sh
FOUNDRY_PROFILE=test forge test
```

### Format

```sh
forge fmt
```

### Gas Snapshots

```sh
forge snapshot
```

### Anvil

```sh
anvil
```

### Deploy

Required environment values are `PRIVATE_KEY`, `BASE_SEPOLIA_RPC_URL`, `COMPLIANCE_SIGNER`, and `BIDNOX_OWNER`.
Use three distinct accounts for the deployer, compliance signer, and owner. The script blocks key reuse unless the
testnet-only `ALLOW_KEY_REUSE=true` escape hatch is explicitly set. `SETTLEMENT_ASSET` is optional and, on Base
Sepolia, must resolve to the pinned Cleanverse aUSDC address.

```sh
forge script script/Deploy.s.sol:Deploy --rpc-url base_sepolia --broadcast
```

### Cast

```sh
cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
