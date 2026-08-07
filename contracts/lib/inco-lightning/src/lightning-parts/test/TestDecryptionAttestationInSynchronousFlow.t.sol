// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IncoTest} from "../../test/IncoTest.sol";
import {ERC7984DemoToken} from "@inco/incoERC7984/src/ERC7984DemoToken.sol";
import {DecryptionAttestation} from "../DecryptionAttester.types.sol";
import {GWEI} from "../../shared/TypeUtils.sol";
import {inco, e, euint256} from "@inco/lightning/src/Lib.sol"; // import via remapping or compiler fails
import {AllowanceProof} from "../AccessControl/AdvancedAccessControl.sol";
import {euint256 as remappedEuint256} from "@inco/lightning/src/Lib.sol";
import {
    DecryptionAttestation as remappedDecryptionAttestation
} from "@inco/lightning/src/lightning-parts/DecryptionAttester.types.sol";

/// @notice This test demonstrates how a decryption attestation can be used in a synchronous flow, where the result of the operation is known at the time of requesting the attestation.
/// In this example, we simulate a token burn operation where the user proves that they have enough balance to burn before actually performing the burn.
contract TokenBurnCurrentBalance is ERC7984DemoToken {

    using e for uint256;
    using e for euint256;

    /// @notice Deploys the token with specified name, symbol, and initial supply
    /// @param name_ The token name
    /// @param symbol_ The token symbol
    /// @param initialSupply The initial supply to mint to the deployer (in base units)
    constructor(string memory name_, string memory symbol_, uint256 initialSupply)
        ERC7984DemoToken(name_, symbol_, initialSupply)
    {
        if (initialSupply > 0) {
            _mint(msg.sender, initialSupply.asEuint256());
        }
    }

    /// @dev In this burn function, the user provides a decryption attestation that proves they have enough balance to burn the specified amount.
    /// The burn operation is performed synchronously, and the success of the burn is verified using the attestation.
    function burnFullCurrentBalance(remappedDecryptionAttestation memory attestation, bytes[] memory signatures)
        public
    {
        euint256 currentBalance = confidentialBalanceOf(msg.sender);
        require(inco.incoVerifier().isValidDecryptionAttestation(attestation, signatures), "Invalid Signature");
        require(euint256.unwrap(currentBalance) == attestation.handle, "Handle mismatch");
        publicBurn(msg.sender, uint256(attestation.value));
    }

}

contract TestDecryptionAttestationInSynchronousFlow is IncoTest {

    AllowanceProof emptyProof; // no proof needed when requester has the handle in persisted allowed pairs

    function testSynchronousBurning() public {
        TokenBurnCurrentBalance token = new TokenBurnCurrentBalance("DemoToken", "DMT", 100 ether);
        vm.deal(address(token), 100 ether);
        token.confidentialTransfer(alice, fakePrepareEuint256Ciphertext(10 * GWEI, address(this), address(token)));
        processAllOperations(); // saves Alice's balance

        bytes32 aliceCurrentBalanceHandle = euint256.unwrap(token.confidentialBalanceOf(alice));
        // simulates Alice requesting for a decryption attestation of Ge op on her balance and the amount
        // she intends to burn, therefore proving to the token contract that the operation will succeed
        (DecryptionAttestation memory attestation, bytes[] memory signatures) =
            getDecryptionAttestation(alice, HandleWithProof({handle: aliceCurrentBalanceHandle, proof: emptyProof}));

        // Convert attestation to remapped type for cross-project compatibility
        remappedDecryptionAttestation memory remappedAttestation =
            remappedDecryptionAttestation({handle: attestation.handle, value: attestation.value});

        vm.prank(alice);
        // the decryption attestation is passed to the token burn method
        token.burnFullCurrentBalance(remappedAttestation, signatures);

        processAllOperations();

        remappedEuint256 remappedFinalAliceBalance = token.confidentialBalanceOf(alice);
        bytes32 finalAliceBalance = remappedEuint256.unwrap(remappedFinalAliceBalance); // compilation trick

        assertEq(uint256(get(finalAliceBalance)), 0, "Alice should have burned all her tokens");
    }

}
