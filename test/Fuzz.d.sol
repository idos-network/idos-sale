// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import {TestSetup} from "./TestSetup.sol";
import {OffChainCalculator} from "src/RisingTide/OffChainCalculator.sol";
import {RisingTide} from "src/RisingTide/RisingTide.sol";

contract FuzzTests is TestSetup {
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

        setup(5000);
        applyDeposits(amounts);
        assertRisingTideCap(542);
    }

    function test_edgeCase() public {
        uint16[] memory amounts = new uint16[](2);
        amounts[0] = 10;
        amounts[1] = 100;

        setup(100);
        applyDeposits(amounts);
        assertRisingTideCap(90);
    }

    function test_roundingErrors() public {
        uint16[] memory amounts = new uint16[](3);
        amounts[0] = 100;
        amounts[1] = 100;
        amounts[2] = 100;

        setup(100);
        applyDeposits(amounts);
        assertRisingTideCap(33);
    }

    function testFuzz_randomInputs(uint16[] memory amounts, uint256 total) public {
        vm.assume(amounts.length > 0);
        vm.assume(amounts.length < 10_000);
        vm.assume(total > 1);
        vm.assume(total >= amounts.length); // TODO: since minContribution is 1, this ensures we never hit MaxContributorsReached

        setup(total);
        applyDeposits(amounts);
        assertRisingTideCap(0);
    }
}
