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

    function test_edgeCase2() public {
        uint16[] memory amounts = new uint16[](30);
        amounts[0] = 542;
        amounts[1] = 10;
        amounts[2] = 9;
        amounts[3] = 9963;
        amounts[4] = 8;
        amounts[5] = 9;
        amounts[6] = 1640;
        amounts[7] = 8780;
        amounts[8] = 542;
        amounts[9] = 6;
        amounts[10] = 6;
        amounts[11] = 542;
        amounts[12] = 5000;
        amounts[13] = 56834;
        amounts[14] = 1;
        amounts[15] = 8;
        amounts[16] = 785;
        amounts[17] = 800;
        amounts[18] = 10;
        amounts[19] = 8762;
        amounts[20] = 6;
        amounts[21] = 1;
        amounts[22] = 28429;
        amounts[23] = 546;
        amounts[24] = 4;
        amounts[25] = 3;
        amounts[26] = 542;
        amounts[27] = 1000;
        amounts[28] = 10;
        amounts[29] = 100;

        _assertRisingTide(amounts, 200, 7);
    }

    /// forge-config: default.fuzz.runs = 1_000
    function testFuzz_randomInputs(uint16[] memory amounts, uint256 total) public {
        vm.assume(amounts.length > 0);
        vm.assume(amounts.length < 10_000);
        vm.assume(total > 1);
        vm.assume(total >= amounts.length); // TODO: since minContribution is 1, this ensures we never hit MaxContributorsReached

        _assertRisingTide(amounts, total, 0);
    }

    function _applyDeposits(uint16[] memory amounts, uint256 total) internal {
        for (uint160 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }
            console.log(string(abi.encode("amounts[", vm.toString(i), "] = ", vm.toString(amounts[i]), ";")));
            address addr = address(i + 1);
            _invest(addr, amounts[i]);
        }
    }

    // applies a list of deposits and a total amount, computes the final cap
    // optionally checks the cap against a given value
    // run on-chain validation to ensure cap is validated
    function _assertRisingTide(uint16[] memory amounts, uint256 total, uint256 expectedCap) internal {
        _setup(total);
        _applyDeposits(amounts, total);

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
        console.log(uint16(c.sale.risingTideState()));
        assert(c.sale.risingTide_isValidCap());
    }
}
