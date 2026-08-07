// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {MockOpHandler} from "@inco/lightning/src/test/FakeIncoInfra/MockOpHandler.sol";
import {FakeDecryptionAttester} from "@inco/lightning/src/test/FakeIncoInfra/FakeDecryptionAttester.sol";
import {FakeQuoteVerifier} from "@inco/lightning/src/test/FakeIncoInfra/FakeQuoteVerifier.sol";
import {MockRemoteAttestation} from "@inco/lightning/src/test/FakeIncoInfra/MockRemoteAttestation.sol";
import {DeployUtils} from "@inco/lightning/src/DeployUtils.sol";
import {IIncoLightning} from "@inco/lightning/src/interfaces/IIncoLightning.sol";
import {inco, deployedBy} from "@inco/lightning/src/Lib.sol";
import {BootstrapResult} from "@inco/lightning/src/lightning-parts/TEELifecycle.types.sol";
import {AllowanceProof, AllowanceVoucher} from "@inco/lightning/src/lightning-parts/AccessControl/AdvancedAccessControl.sol";

abstract contract IncoLocalTest is MockOpHandler, DeployUtils, FakeDecryptionAttester, MockRemoteAttestation {
    address internal incoOwner;
    address internal immutable incoDeployer;

    bytes internal testNetworkPubkey = hex"ca882388911c7c762aafc20debd63e845b3bed28c9d5262cdea7771fb31bd660a1ae7b395a9a7df3d12c7b118e8eda5057572c1ba05cd9b635edf33dabca4cac7291e0848f19c20e5beb850c3818f3543d49b3a5c729cb86a28fda539775d04feda112fe0c81d138aaf623aea7d507a4e826e890105db6065a44aba76a10d771c00d1b33f4ac51869806aae18eada68f19047024542d64a7aa1c91a5e1aa49d93613b5224b415bcc7aa166e4b55033438d20c641f9664fdb1689b53208181463e3d1325d46b30f07c5945b7e3fa1418bf833d975258461b294664eaf60795964924a280729c10a37fc6e967440bdd55d4ca53596286383481291152365303d44517cef369c00933b0b30368a230353e729c031075e8388673678a56b3ba84a165b28096ee9bd684483e1844258b451c365c41fa534152a3b64120041450128e960c7d6437d717ee266bdde7aaeec225ed93b958d188e97407349f1382976ca47d761ecc59a6f394487eb015c083abb490584677240eb47f838c838568a496119378b8bb81484610a50792b5d9c9939db188e7d0249d3cb918c436f111a2898849b286b0743a22c57464c709c5eaceac1ba493adca3328c0b14b5e38d3aea74e328b622b17e7181c35ad11c2103bdb7f2b209d93dcbc4ab61a06bc37139e6d2b7a06c5b7e9267bef3a8918a706f793271a5acc2574532da79e5a10cf074b998147a3c43586a411a513bba0d11cc19a36c83b19277f28022c88b120abfdba7076a8263e05336e3245aef7033eb3c762b5bbfa5791ac960398b649d5cbb652ddc6b2398143a0861ab3b410b696328879c099098adf819fbf7ac170030e86675e7f45c22ac9e1cf52c3102487bb0b91ab592afdc69c6e3a9b71876b86260b6c736b8291098f1130d3b763525cbad540ce2d042eacb6ed43b7bcba898f712c412f26066e09945f44ec7026c8ef959831abc10719d2017a12a41728b41c02371a5f5756ebc79406be708ea41bbd21563c874a0b791a3b4e4224a609967004f065c5ab4f3b4c61cb35df70573269da53179c3701fc5205f61974426f9b794c1b5826494b70842b6920c17752029369264dc8590b898b85c9d89a258e1f46c1b0490efd17c485cb51687cea272041e90b8e629521d3c5e3fa7518161bad7a159295b63cc6c0077897b53d47db8bc0ecb820f550705b65715a1a1094d04854f56acd26aa0baa10cb8447fad6211f53105796a42882328e6852e8de821c283b51eaab9bc95c4dc53615626049d63b1f9a457193805276b1905b0ab39353b5cf91fdd6023d4d816aef9cce4a3cfb3d12190172df221ae61d427563a098cc60e3dc9997ef54959180be5dc64a911157db6be3a01be2ee343caab33b8729abf0c50c674758c511291941fceac646232920907c2e88b9ec10211161729c797643a553a6ae5c4b7483c04e3263bd291e311c609071348b7c3310aa97d6b8318e0a4afe8399fa22f951049a9bb8860f7c69a333d3cc1aaf0129ab560713bf29eb3a01f9a276c78e54e3a3648b2447c80242b271b11406866389426d8b59796540d6b5702092ab21ee217c075cfc0c17ef826ce9ea29b9e61617457a5b1aaa23a58615dc53c59183beb36ea19498c21820b70ab47adeb678f1c52bf8768b3597b608ea1a8a15cd62e8a29bec4a1ac248ef9f02de0144bca06025f95a42bd6c8eaaaaaa2366328561d";

    address private constant ANVIL_ZEROTH_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 private constant ANVIL_ZEROTH_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        incoDeployer = deployedBy;
        vm.label(incoDeployer, "incoDeployer");
        vm.label(address(inco), "inco");
    }

    function setUp() public virtual {
        deployCreateX();

        incoOwner = makeAddr("incoOwner");

        vm.startPrank(incoDeployer);
        vm.setEnv("SHOULD_SETUP_TEE_SIGNER", "true");
        (IIncoLightning proxy,) = deployIncoLightningUsingConfig({
            deployer: incoDeployer,
            owner: incoOwner,
            pepper: "mainnet",
            quoteVerifier: new FakeQuoteVerifier()
        });
        vm.stopPrank();

        require(address(proxy) == address(inco), "inco address does not match Lib.sol constant");

        vm.startPrank(incoOwner);
        (
            BootstrapResult memory bootstrapResult,
            bytes memory quote,
            bytes memory signature,
            bytes32 mrAggregated
        ) = successfulBootstrapResult(
            inco.incoVerifier(), testNetworkPubkey, ANVIL_ZEROTH_ADDRESS, ANVIL_ZEROTH_PRIVATE_KEY
        );
        inco.incoVerifier().approveNewTeeVersion(mrAggregated);
        inco.incoVerifier().verifyBootstrapResult(bootstrapResult, quote, signature);
        inco.incoVerifier().setThreshold(1);
        vm.stopPrank();

        vm.recordLogs();
    }

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
