// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RisingTide} from "./RisingTide.sol";
import {Arrays} from "@openzeppelin/utils/Arrays.sol";
import "forge-std/console.sol";

contract OffChainCalculator {
    using Arrays for uint256[];

    function computeCap(RisingTide r) external view returns (uint256) {
        return computeCapWithSortedFlag(r, false);
    }

    // in some extremely large test cases, we need to manually ensure investments are already sorted,
    // since quicksort here will cause a stack overflow
    function computeCapWithSortedFlag(RisingTide r, bool alreadySorted) public view returns (uint256) {
        uint256 available = r.risingTide_totalCap();
        uint256 investorCount = r.investorCount();
        uint256 investorsLeft = r.investorCount();
        uint256 accum = 0;

        if (investorCount == 0) return 0;

        uint256[] memory amounts = new uint256[](investorCount);
        for (uint256 i = 0; i < investorCount; i++) {
            amounts[i] = r.investorAmountAt(i);
        }

        if (!alreadySorted) {
            amounts.sort();
        }

        for (uint256 idx = 0; idx < amounts.length; idx++) {
            uint256 amount = amounts[idx];
            uint256 hypothetical = amount * investorsLeft;

            console.log(hypothetical, investorsLeft, available - accum);
            if (hypothetical > (available - accum)) {
                // Cap exceeded — compute precise cutoff
                return (available - accum) / investorsLeft;
            }

            accum += amount;
            investorsLeft--;
        }

        // If never exceeded, highest allocation is the cap
        return amounts[amounts.length - 1];
    }
}
