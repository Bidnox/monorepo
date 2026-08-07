// SPDX-License-Identifier: BUSL-1.1
// Copyright (c) 2026 Liquidbox Corp.
// Licensed under the Business Source License 1.1. See LICENSE.md.
// Terms of use: https://www.inco.org/terms-of-services
// Security contact team@inco.network
pragma solidity ^0.8;

import {IPCCSRouter} from "../../interfaces/automata-interfaces/IPCCSRouter.sol";
import {Header} from "../../interfaces/automata-interfaces/Types.sol";
import {IQuoteVerifier} from "../../interfaces/automata-interfaces/IQuoteVerifier.sol";

// This contract is used to test the IncoLightning contract. It is a simple implementation of the QuoteVerifier interface.
// It is used to test the IncoLightning contract without relying on the real QuoteVerifier contract.
contract FakeQuoteVerifier is IQuoteVerifier {

    /// @dev immutable
    function pccsRouter() external pure returns (IPCCSRouter) {
        return IPCCSRouter(address(0));
    }

    /// @dev immutable
    function quoteVersion() external pure returns (uint16) {
        return 4;
    }

    function verifyQuote(Header calldata, bytes calldata quote) external pure returns (bool, bytes memory) {
        return (true, quote);
    }

    function verifyZkOutput(bytes calldata quote) external pure returns (bool, bytes memory) {
        return (true, quote);
    }

}
