.PHONY: build test test-gate test-registry test-auction test-invariant fmt clean deploy deploy-dry

# Build and deploy use the default profile, which pins Inco Lightning to its Base Sepolia
# address. Tests use the `test` profile, which remaps that single import onto Lib.sol so the
# local Inco harness can stand the protocol up in-memory. The two write to separate artifact
# directories so a test build can never overwrite a deployable artifact.

build:
	forge build

test:
	FOUNDRY_PROFILE=test forge test

test-v:
	FOUNDRY_PROFILE=test forge test -vvv

test-gate:
	FOUNDRY_PROFILE=test forge test --match-contract ComplianceGateTest -vv

test-registry:
	FOUNDRY_PROFILE=test forge test --match-contract ReceivableRegistryTest -vv

test-auction:
	FOUNDRY_PROFILE=test forge test --match-contract ConfidentialAuctionTest -vv

test-invariant:
	FOUNDRY_PROFILE=test forge test --match-path "test/invariant/*" -vv

gas:
	FOUNDRY_PROFILE=test forge test --gas-report

fmt:
	forge fmt

clean:
	forge clean && rm -rf out-test cache-test

# Requires PRIVATE_KEY, COMPLIANCE_SIGNER, SETTLEMENT_SIGNER, SETTLEMENT_ASSET.
# Optional: BIDNOX_OWNER.
deploy:
	forge script script/Deploy.s.sol:Deploy --rpc-url base_sepolia --broadcast --verify -vvv

deploy-dry:
	forge script script/Deploy.s.sol:Deploy --rpc-url base_sepolia -vvv
