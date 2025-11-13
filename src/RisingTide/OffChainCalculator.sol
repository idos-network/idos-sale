// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {RisingTide} from "./RisingTide.sol";
import "forge-std/console.sol";

contract OffChainCalculator {
    function computeCap(RisingTide r) external view returns (uint256) {
        uint256 available = r.risingTide_totalCap();
        uint256 cap = 0;
        uint256 capNextIdx = 0;
        uint256 investorCount = r.investorCount();
        uint256 investorsLeft = r.investorCount();
        uint256 accum = 0;

        console.log("investorCount", investorCount);
        console.log("available", available);
        console.log("cap", cap);
        uint256[] memory amounts = new uint256[](investorCount);
        for (uint256 i = 0; i < investorCount; i++) {
            amounts[i] = r.investorAmountAt(i);
        }
        sort(amounts);
        for (uint256 i = 0; i < investorCount; i++) {}

        while (true) {
            if (capNextIdx == investorCount) {
                console.log("capNextIdx == investorCount");
                return cap;
            }

            cap = amounts[capNextIdx];
            uint256 hypothetical = cap * investorsLeft;

            if (hypothetical > available - accum) {
                break;
            }
            accum = accum + cap;
            capNextIdx++;
            investorsLeft--;
        }

        return (available - accum) / investorsLeft;
    }

    function sort(uint256[] memory data) internal pure returns (uint256[] memory) {
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
