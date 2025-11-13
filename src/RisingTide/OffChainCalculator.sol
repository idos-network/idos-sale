// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RisingTide} from "./RisingTide.sol";
import {Arrays} from "@openzeppelin/utils/Arrays.sol";

contract OffChainCalculator {
    using Arrays for uint256[];

    function computeCap(RisingTide r) external view returns (uint256) {
        uint256 available = r.risingTide_totalCap();
        uint256 investorCount = r.investorCount();
        uint256 investorsLeft = r.investorCount();
        uint256 accum = 0;

        if (investorCount == 0) return 0;

        uint256[] memory amounts = new uint256[](investorCount);
        for (uint256 i = 0; i < investorCount; i++) {
            amounts[i] = r.investorAmountAt(i);
        }
        amounts.sort();

        for (uint256 idx = 0; idx < amounts.length; idx++) {
            uint256 amount = amounts[idx];
            uint256 hypothetical = amount * investorsLeft;

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

    function sort(uint256[] memory data) internal pure returns (uint256[] memory) {
        if (data.length <= 1) return data;
        quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    function quickSort(uint256[] memory arr, int256 left, int256 right) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) {
            quickSort(arr, left, j);
        }
        if (i < right) {
            quickSort(arr, i, right);
        }
    }
}
