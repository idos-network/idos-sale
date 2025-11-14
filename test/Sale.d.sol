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

        assertRisingTideCap(100);
        assertRefund(address(0x1), 0);
    }

    function test_twoEqualInvestors() public {
        setup(100);
        invest(address(0x1), 100);
        invest(address(0x2), 100);

        assertRisingTideCap(50);
        assertRefund(address(0x1), 0);
        assertRefund(address(0x2), 0);
    }

    function test_noInvestors() public {
        setup(2);
        endSale();
        assertRisingTideCap(0);
    }
}
