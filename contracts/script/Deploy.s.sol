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

    address internal constant BASE_SEPOLIA_CLEANVERSE_AUSDC = 0xaC0893567D43C3E7e6e35a72803df05416C1f20D;

    error WrongChain(uint256 actual, uint256 expected);
    error IncoNotDeployed(address expected);
    error SettlementAssetHasNoCode(address asset);
    error WrongSettlementAsset(address actual, address expected);
    error KeyReuse(address reusedAccount);

    function run() external returns (ComplianceGate gate, ReceivableRegistry registry, ConfidentialAuction auction) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        address complianceSigner = vm.envAddress("COMPLIANCE_SIGNER");
        address settlementAsset = vm.envOr("SETTLEMENT_ASSET", BASE_SEPOLIA_CLEANVERSE_AUSDC);
        address owner = vm.envAddress("BIDNOX_OWNER");

        _preflight(deployer, owner, complianceSigner, settlementAsset);

        vm.startBroadcast(deployerKey);

        gate = new ComplianceGate(deployer, complianceSigner, settlementAsset);
        registry = new ReceivableRegistry(deployer, gate);
        auction = new ConfidentialAuction(gate, registry);

        gate.setConsumer(address(registry), true);
        gate.setConsumer(address(auction), true);

        registry.setAuctionContract(address(auction));

        if (owner != deployer) {
            gate.transferOwnership(owner);
            registry.transferOwnership(owner);
        }

        vm.stopBroadcast();

        _report(gate, registry, auction, deployer, owner, complianceSigner, settlementAsset);
        _writeManifest(gate, registry, auction, owner, complianceSigner, settlementAsset);
    }

    function _preflight(address deployer, address owner, address complianceSigner, address settlementAsset)
        internal
        view
    {
        if (block.chainid != BASE_SEPOLIA && !vm.envOr("ALLOW_ANY_CHAIN", false)) {
            revert WrongChain(block.chainid, BASE_SEPOLIA);
        }

        if (block.chainid == BASE_SEPOLIA) {
            if (address(inco).code.length == 0) revert IncoNotDeployed(address(inco));

            if (settlementAsset != BASE_SEPOLIA_CLEANVERSE_AUSDC) {
                revert WrongSettlementAsset(settlementAsset, BASE_SEPOLIA_CLEANVERSE_AUSDC);
            }
            if (settlementAsset.code.length == 0) revert SettlementAssetHasNoCode(settlementAsset);
        }

        if (
            (deployer == owner || deployer == complianceSigner || owner == complianceSigner)
                && !vm.envOr("ALLOW_KEY_REUSE", false)
        ) {
            if (deployer == owner || deployer == complianceSigner) revert KeyReuse(deployer);
            revert KeyReuse(owner);
        }
    }

    function _report(
        ComplianceGate gate,
        ReceivableRegistry registry,
        ConfidentialAuction auction,
        address deployer,
        address owner,
        address complianceSigner,
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
        address settlementAsset
    ) internal {
        string memory contractsKey = "contracts";
        vm.serializeAddress(contractsKey, "complianceGate", address(gate));
        vm.serializeAddress(contractsKey, "receivableRegistry", address(registry));
        string memory contractsJson = vm.serializeAddress(contractsKey, "confidentialAuction", address(auction));

        string memory rootKey = "root";
        vm.serializeString(rootKey, "network", "base-sepolia");
        vm.serializeUint(rootKey, "chainId", block.chainid);
        vm.serializeAddress(rootKey, "owner", owner);
        vm.serializeAddress(rootKey, "incoLightning", address(inco));
        vm.serializeAddress(rootKey, "settlementAsset", settlementAsset);
        vm.serializeAddress(rootKey, "complianceSigner", complianceSigner);
        string memory json = vm.serializeString(rootKey, "contracts", contractsJson);

        vm.writeJson(json, "./deployments/base-sepolia.json");
        console.log("Manifest written to deployments/base-sepolia.json");
    }
}
