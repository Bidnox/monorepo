// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {inco} from "@inco/lightning/src/Lib.testnet.sol";

import {ComplianceGate} from "../src/ComplianceGate.sol";
import {ReceivableRegistry} from "../src/ReceivableRegistry.sol";
import {ConfidentialAuction} from "../src/ConfidentialAuction.sol";

contract Deploy is Script {
    uint256 internal constant BASE_SEPOLIA = 84532;

    address internal constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    error WrongChain(uint256 actual, uint256 expected);
    error IncoNotDeployed(address expected);
    error SettlementAssetHasNoCode(address asset);

    function run()
        external
        returns (ComplianceGate gate, ReceivableRegistry registry, ConfidentialAuction auction)
    {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address complianceSigner = vm.envAddress("COMPLIANCE_SIGNER");
        address settlementSigner = vm.envAddress("SETTLEMENT_SIGNER");
        address settlementAsset = vm.envOr("SETTLEMENT_ASSET", BASE_SEPOLIA_USDC);
        address owner = vm.envOr("BIDNOX_OWNER", deployer);

        _preflight(deployer, complianceSigner, settlementSigner, settlementAsset);

        vm.startBroadcast(deployerKey);

        gate = new ComplianceGate(deployer, complianceSigner, settlementAsset);
        registry = new ReceivableRegistry(deployer, gate, settlementSigner);
        auction = new ConfidentialAuction(gate, registry);

        gate.setConsumer(address(registry), true);
        gate.setConsumer(address(auction), true);

        registry.setAuctionContract(address(auction));

        if (owner != deployer) {
            gate.transferOwnership(owner);
            registry.transferOwnership(owner);
        }

        vm.stopBroadcast();

        _report(gate, registry, auction, deployer, owner, complianceSigner, settlementSigner, settlementAsset);
        _writeManifest(gate, registry, auction, owner, complianceSigner, settlementSigner, settlementAsset);
    }

    function _preflight(
        address deployer,
        address complianceSigner,
        address settlementSigner,
        address settlementAsset
    ) internal view {
        if (block.chainid != BASE_SEPOLIA && !vm.envOr("ALLOW_ANY_CHAIN", false)) {
            revert WrongChain(block.chainid, BASE_SEPOLIA);
        }

        if (block.chainid == BASE_SEPOLIA) {
            if (address(inco).code.length == 0) revert IncoNotDeployed(address(inco));

            if (settlementAsset.code.length == 0) revert SettlementAssetHasNoCode(settlementAsset);
        }

        _warnOnKeyReuse(deployer, complianceSigner, settlementSigner);
    }

    function _warnOnKeyReuse(address deployer, address complianceSigner, address settlementSigner)
        internal
        pure
    {
        bool reused;

        if (complianceSigner == settlementSigner) {
            console.log("WARNING: COMPLIANCE_SIGNER == SETTLEMENT_SIGNER (%s).", complianceSigner);
            console.log("  One leaked key forges both eligibility permits and settlement evidence,");
            console.log("  which is enough to drive an invoice to Repaid with no money involved.");
            reused = true;
        }

        if (complianceSigner == deployer) {
            console.log("WARNING: COMPLIANCE_SIGNER == deployer (%s).", deployer);
            console.log("  The deploy key tends to end up in shell history and CI logs.");
            reused = true;
        }

        if (settlementSigner == deployer) {
            console.log("WARNING: SETTLEMENT_SIGNER == deployer (%s).", deployer);
            console.log("  The deploy key tends to end up in shell history and CI logs.");
            reused = true;
        }

        if (reused) {
            console.log("  Fine for testnet. Before anything real, generate separate keys");
            console.log("  (cast wallet new) and rotate with setComplianceSigner /");
            console.log("  setSettlementSigner -- no redeploy needed.");
            console.log("");
        }
    }

    function _report(
        ComplianceGate gate,
        ReceivableRegistry registry,
        ConfidentialAuction auction,
        address deployer,
        address owner,
        address complianceSigner,
        address settlementSigner,
        address settlementAsset
    ) internal view {
        console.log("");
        console.log("=== Bidnox deployment ===");
        console.log("chainId            ", block.chainid);
        console.log("deployer           ", deployer);
        console.log("owner              ", owner);
        console.log("");
        console.log("ComplianceGate     ", address(gate));
        console.log("ReceivableRegistry ", address(registry));
        console.log("ConfidentialAuction", address(auction));
        console.log("");
        console.log("incoLightning      ", address(inco));
        console.log("settlementAsset    ", settlementAsset);
        console.log("complianceSigner   ", complianceSigner);
        console.log("settlementSigner   ", settlementSigner);
        console.log("maxPermitTtl       ", gate.maxPermitTtl());
        console.log("");

        if (owner != deployer) {
            console.log("ACTION REQUIRED: ownership transfer is two-step.");
            console.log("  %s must call acceptOwnership() on both:", owner);
            console.log("    ComplianceGate     %s", address(gate));
            console.log("    ReceivableRegistry %s", address(registry));
            console.log("  Until then the deployer still owns them.");
            console.log("");
        }
    }

    function _writeManifest(
        ComplianceGate gate,
        ReceivableRegistry registry,
        ConfidentialAuction auction,
        address owner,
        address complianceSigner,
        address settlementSigner,
        address settlementAsset
    ) internal {
        string memory contractsKey = "contracts";
        vm.serializeAddress(contractsKey, "complianceGate", address(gate));
        vm.serializeAddress(contractsKey, "receivableRegistry", address(registry));
        string memory contractsJson = vm.serializeAddress(contractsKey, "confidentialAuction", address(auction));

        string memory signersKey = "signers";
        vm.serializeAddress(signersKey, "complianceSigner", complianceSigner);
        string memory signersJson = vm.serializeAddress(signersKey, "settlementSigner", settlementSigner);

        string memory rootKey = "root";
        vm.serializeString(rootKey, "network", "base-sepolia");
        vm.serializeUint(rootKey, "chainId", block.chainid);
        vm.serializeAddress(rootKey, "owner", owner);
        vm.serializeAddress(rootKey, "incoLightning", address(inco));
        vm.serializeAddress(rootKey, "settlementAsset", settlementAsset);
        vm.serializeString(rootKey, "signers", signersJson);
        string memory json = vm.serializeString(rootKey, "contracts", contractsJson);

        vm.writeJson(json, "./deployments/base-sepolia.json");
        console.log("Manifest written to deployments/base-sepolia.json");
    }
}
