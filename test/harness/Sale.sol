// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Sale} from "src/Sale.sol";

contract SaleHarnessNoMerkle is Sale {
    constructor(
        address _paymentToken,
        uint256 _rate,
        uint256 _start,
        uint256 _end,
        uint256 _minTarget,
        uint256 _maxTarget
    ) Sale(_paymentToken, _rate, _start, _end, _minTarget, _maxTarget) {}

    function verifyLeaf(
        bytes32[] calldata,
        /* _merkleProof */
        bytes32 /* _leaf */
    )
        internal
        pure
        override(Sale)
        returns (bool)
    {
        return true;
    }
}
