// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestSetup} from "./TestSetup.sol";

contract SaleTest is TestSetup {
    function test_buy() public {
        setup();
    }

    function test_singleInvestor() public {
        setup(100);
        invest(address(0x1), 100);

        assertRevert("No investors");
        assertRisingTideCap(100);
    }
}
