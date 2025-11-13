// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Sale} from "src/sale.sol";
import {Arrays} from "@openzeppelin/utils/Arrays.sol";

/// @title Rising Tide Cap Calculation
/// @notice Computes the rising tide cap based on data from an external Sale contract.
contract RisingTideCalculation {
    using Arrays for uint256[];

    /// @notice Computes the rising tide cap for a given Sale contract.
    /// @param _sale The address of the Sale contract.
    /// @return cap The maximum per-investor allocation cap.
    function computeRisingTideCap(address _sale) external view returns (uint256 cap) {
        Sale sale = Sale(_sale);
        uint256 investorCount = sale.investorCount();
        require(investorCount > 0, "No investors");

        uint256[] memory allocations = new uint256[](investorCount);
        for (uint256 i = 0; i < investorCount; i++) {
            uint256 uncappedAllocation = sale.investorAmountAt(i);
            allocations[i] = uncappedAllocation;
        }

        allocations.sort();

        uint256 available = sale.maxTarget();
        uint256 accum = 0;
        uint256 investorsLeft = allocations.length;

        for (uint256 idx = 0; idx < allocations.length; idx++) {
            uint256 amount = allocations[idx];
            uint256 hypothetical = amount * investorsLeft;

            if (hypothetical > (available - accum)) {
                // Cap exceeded — compute precise cutoff
                return (available - accum) / investorsLeft;
            }

            accum += amount;
            investorsLeft--;
        }

        // If never exceeded, highest allocation is the cap
        return allocations[allocations.length - 1];
    }
}
