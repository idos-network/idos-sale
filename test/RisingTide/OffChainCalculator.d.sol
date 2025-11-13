// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TestSetup} from "../TestSetup.sol";
import {OffChainCalculator} from "src/RisingTide/OffChainCalculator.sol";

contract OffChainCalculatorTest is TestSetup {
    function test_computeCapWithGitbookExample() public {
        uint256[] memory amounts = new uint256[](10);
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

        _assertCapFor(amounts, 5000, 542);
    }

    function test_edgeCase() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10;
        amounts[1] = 100;

        _assertCapFor(amounts, 100, 90);
    }

    function _assertCapFor(uint256[] memory amounts, uint256 total, uint256 cap) internal {
        _setup(total);

        for (uint160 i = 0; i < amounts.length; i++) {
            address addr = address(i + 1);
            _invest(addr, amounts[i]);
        }

        OffChainCalculator calculator = new OffChainCalculator();
        assertEq(calculator.computeCap(c.sale), cap);
    }
}
