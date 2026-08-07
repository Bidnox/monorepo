// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {MockOpHandler} from "./FakeIncoInfra/MockOpHandler.sol";
import {IIncoLightning} from "../interfaces/IIncoLightning.sol";
import {inco} from "../Lib.sol";
import {DeployUtils} from "../DeployUtils.sol";
import {deployedBy} from "../Lib.sol";
import {FakeDecryptionAttester} from "./FakeIncoInfra/FakeDecryptionAttester.sol";
import {console} from "forge-std/console.sol";
import {FakeQuoteVerifier} from "./FakeIncoInfra/FakeQuoteVerifier.sol";
import {IOwnable} from "../../src/shared/IOwnable.sol";
import {MockRemoteAttestation} from "./FakeIncoInfra/MockRemoteAttestation.sol";
import {BootstrapResult} from "../lightning-parts/TEELifecycle.types.sol";
import {AllowanceProof, AllowanceVoucher} from "../lightning-parts/AccessControl/AdvancedAccessControl.sol";
import {Safe} from "safe-smart-account/Safe.sol";
import {SafeProxyFactory} from "safe-smart-account/proxies/SafeProxyFactory.sol";

contract IncoTest is MockOpHandler, DeployUtils, FakeDecryptionAttester, MockRemoteAttestation {

    address owner;
    // forge-lint: disable-next-line(screaming-snake-case-immutable)
    address immutable testDeployer;

    // Constants for testing
    // X-Wing public key (1216 bytes) - matches Go covalidator test key (seed of all zeros)
    // Generated using HPKE layer: hpke.KEM_XWING.Scheme().DeriveKeyPair(seed) for interop with hpke-rs
    // This is the same key used in @contracts/pega/lib/keys.ts anointedXwingKey
    bytes testNetworkPubkey =
        hex"ca882388911c7c762aafc20debd63e845b3bed28c9d5262cdea7771fb31bd660a1ae7b395a9a7df3d12c7b118e8eda5057572c1ba05cd9b635edf33dabca4cac7291e0848f19c20e5beb850c3818f3543d49b3a5c729cb86a28fda539775d04feda112fe0c81d138aaf623aea7d507a4e826e890105db6065a44aba76a10d771c00d1b33f4ac51869806aae18eada68f19047024542d64a7aa1c91a5e1aa49d93613b5224b415bcc7aa166e4b55033438d20c641f9664fdb1689b53208181463e3d1325d46b30f07c5945b7e3fa1418bf833d975258461b294664eaf60795964924a280729c10a37fc6e967440bdd55d4ca53596286383481291152365303d44517cef369c00933b0b30368a230353e729c031075e8388673678a56b3ba84a165b28096ee9bd684483e1844258b451c365c41fa534152a3b64120041450128e960c7d6437d717ee266bdde7aaeec225ed93b958d188e97407349f1382976ca47d761ecc59a6f394487eb015c083abb490584677240eb47f838c838568a496119378b8bb81484610a50792b5d9c9939db188e7d0249d3cb918c436f111a2898849b286b0743a22c57464c709c5eaceac1ba493adca3328c0b14b5e38d3aea74e328b622b17e7181c35ad11c2103bdb7f2b209d93dcbc4ab61a06bc37139e6d2b7a06c5b7e9267bef3a8918a706f793271a5acc2574532da79e5a10cf074b998147a3c43586a411a513bba0d11cc19a36c83b19277f28022c88b120abfdba7076a8263e05336e3245aef7033eb3c762b5bbfa5791ac960398b649d5cbb652ddc6b2398143a0861ab3b410b696328879c099098adf819fbf7ac170030e86675e7f45c22ac9e1cf52c3102487bb0b91ab592afdc69c6e3a9b71876b86260b6c736b8291098f1130d3b763525cbad540ce2d042eacb6ed43b7bcba898f712c412f26066e09945f44ec7026c8ef959831abc10719d2017a12a41728b41c02371a5f5756ebc79406be708ea41bbd21563c874a0b791a3b4e4224a609967004f065c5ab4f3b4c61cb35df70573269da53179c3701fc5205f61974426f9b794c1b5826494b70842b6920c17752029369264dc8590b898b85c9d89a258e1f46c1b0490efd17c485cb51687cea272041e90b8e629521d3c5e3fa7518161bad7a159295b63cc6c0077897b53d47db8bc0ecb820f550705b65715a1a1094d04854f56acd26aa0baa10cb8447fad6211f53105796a42882328e6852e8de821c283b51eaab9bc95c4dc53615626049d63b1f9a457193805276b1905b0ab39353b5cf91fdd6023d4d816aef9cce4a3cfb3d12190172df221ae61d427563a098cc60e3dc9997ef54959180be5dc64a911157db6be3a01be2ee343caab33b8729abf0c50c674758c511291941fceac646232920907c2e88b9ec10211161729c797643a553a6ae5c4b7483c04e3263bd291e311c609071348b7c3310aa97d6b8318e0a4afe8399fa22f951049a9bb8860f7c69a333d3cc1aaf0129ab560713bf29eb3a01f9a276c78e54e3a3648b2447c80242b271b11406866389426d8b59796540d6b5702092ab21ee217c075cfc0c17ef826ce9ea29b9e61617457a5b1aaa23a58615dc53c59183beb36ea19498c21820b70ab47adeb678f1c52bf8768b3597b608ea1a8a15cd62e8a29bec4a1ac248ef9f02de0144bca06025f95a42bd6c8eaaaaaa2366328561d";
    address private constant ANVIL_ZEROTH_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant ANVIL_ZEROTH_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        // extracted from the deploy script running as bare simulation with:
        // forge script src/script/Deploy.s.sol:Deploy
        testDeployer = deployedBy;
        vm.label(testDeployer, "testDeployer");
        vm.label(address(this), "testRunner");
        vm.label(address(inco), "inco");
    }

    function setUp() public virtual {
        deployCreateX();

        // Create a Safe multisig (alice, bob, carol) with threshold 2 to act as owner
        Safe master = new Safe();
        SafeProxyFactory factory = new SafeProxyFactory();
        address[] memory safeOwners = new address[](3);
        safeOwners[0] = alice;
        safeOwners[1] = bob;
        safeOwners[2] = carol;
        bytes memory setupData = abi.encodeWithSelector(
            Safe.setup.selector, safeOwners, 2, address(0), bytes(""), address(0), address(0), 0, payable(address(0))
        );
        owner = address(Safe(payable(factory.createProxyWithNonce(address(master), setupData, 0))));

        vm.startPrank(testDeployer);
        vm.setEnv("SHOULD_SETUP_TEE_SIGNER", "true"); // results in a network pubkey and decrypt signer being populated in the TEE Lifecycle
        (IIncoLightning proxy,) = deployIncoLightningUsingConfig({
            deployer: testDeployer,
            owner: owner,
            // The highest precedent deployment pepper
            pepper: "mainnet",
            quoteVerifier: new FakeQuoteVerifier()
        });
        vm.stopPrank();
        console.log("Deployed %s (proxy) to: %s", proxy.getName(), address(proxy));
        console.log("Generated inco address: %s", address(inco));
        require(
            address(proxy) == address(inco),
            "generated inco address in Lib.sol does not match address of inco deployed by IncoTest"
        );
        vm.startPrank(owner);
        (BootstrapResult memory bootstrapResult, bytes memory quote, bytes memory signature, bytes32 mrAggregated) = successfulBootstrapResult(
            inco.incoVerifier(), testNetworkPubkey, ANVIL_ZEROTH_ADDRESS, ANVIL_ZEROTH_PRIVATE_KEY
        );
        inco.incoVerifier().approveNewTeeVersion(mrAggregated);
        inco.incoVerifier().verifyBootstrapResult(bootstrapResult, quote, signature);
        inco.incoVerifier().setThreshold(1);
        vm.stopPrank();
        vm.recordLogs();
    }

    /// @dev Creates an empty AllowanceProof (no proof required when sharer is address(0))
    function _emptyAllowanceProof() internal pure returns (AllowanceProof memory) {
        return AllowanceProof({
            sharer: address(0),
            voucher: AllowanceVoucher({
                sessionNonce: bytes32(0),
                verifyingContract: address(0),
                callFunction: bytes4(0),
                sharerArgData: "",
                warning: ""
            }),
            voucherSignature: "",
            requesterArgData: ""
        });
    }

}
