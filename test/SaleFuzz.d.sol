// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {TestSetup} from "./TestSetup.sol";

contract SaleFuzz is TestSetup {
    function testFuzz_saleFlowEqualAmounts(uint16 investorCount, uint16 amount) public {
        vm.assume(investorCount > 0);
        vm.assume(amount > 0);
        vm.assume(investorCount < 1000);

        // perform all deposits
        for (uint256 i = 0; i < investorCount; i++) {
            address addr = address(uint160(i + 1));
            _invest(addr, amount);
        }

        // final deposited amount should be the sum
        assertEq(c.usdc.balanceOf(address(c.sale)), uint256(amount) * uint256(investorCount));
    }
}
