// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import {TestSetup} from "../TestSetup.sol";
import {OffChainCalculator} from "src/RisingTide/OffChainCalculator.sol";
import {RisingTide} from "src/RisingTide/RisingTide.sol";

contract OffChainCalculatorTest is TestSetup {
    function test_computeCapWithGitbookExample() public {
        uint16[] memory amounts = new uint16[](10);
        amounts[0] = 500;
        amounts[1] = 1000;
        amounts[2] = 750;
        amounts[3] = 500;
        amounts[4] = 1000;
        amounts[5] = 750;
        amounts[6] = 200;
        amounts[7] = 1000;
        amounts[8] = 800;
        amounts[9] = 1000;

        _assertRisingTide(amounts, 5000, 542);
    }

    function test_edgeCase() public {
        uint16[] memory amounts = new uint16[](2);
        amounts[0] = 10;
        amounts[1] = 100;

        _assertRisingTide(amounts, 100, 90);
    }

    function test_roundingErrors() public {
        uint16[] memory amounts = new uint16[](3);
        amounts[0] = 100;
        amounts[1] = 100;
        amounts[2] = 100;

        _assertRisingTide(amounts, 100, 33);
    }

    function test_noInvestors() public {
        uint16[] memory amounts = new uint16[](0);

        _assertRisingTide(amounts, 2, 0);
    }

    /// forge-config: default.fuzz.runs = 1_000
    function testFuzz_randomInputs(uint16[] memory amounts, uint256 total) public {
        vm.assume(amounts.length > 0);
        vm.assume(amounts.length < 10_000);
        vm.assume(total > 1);
        vm.assume(total >= amounts.length); // TODO: since minContribution is 1, this ensures we never hit MaxContributorsReached

        _assertRisingTide(amounts, total, 0);
    }

    // applies a list of deposits and a total amount, computes the final cap
    // optionally checks the cap against a given value
    // run on-chain validation to ensure cap is validated
    function _assertRisingTide(uint16[] memory amounts, uint256 total, uint256 expectedCap) internal {
        _setup(total);
        _applyDeposits(amounts);

        // perform off-chain cap calculation
        OffChainCalculator calculator = new OffChainCalculator();
        uint256 cap = calculator.computeCap(c.sale);

        // if provided, assert the cap is what we expect
        if (expectedCap > 0) {
            assertEq(cap, expectedCap);
        }

        // validate cap using on-chain logic
        vm.warp(c.sale.end() + 1);
        c.sale.setIndividualCap(cap);
        while (c.sale.risingTideState() == RisingTide.RisingTideState.Validating) {
            c.sale.risingTide_validate();
        }
        assert(c.sale.risingTide_isValidCap());
    }

    function _applyDeposits(uint16[] memory amounts) internal {
        for (uint160 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }
            console.log(string(abi.encode("amounts[", vm.toString(i), "] = ", vm.toString(amounts[i]), ";")));
            address addr = address(i + 1);
            _invest(addr, amounts[i]);
        }
    }
}
