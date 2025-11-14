// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestSetup} from "./TestSetup.sol";

contract SaleTest is TestSetup {
    function test_buy() public {
        setup();
    }

    function test_singleInvestor() public {
        Case memory c = Case({maxTarget: 100, cap: 100, investors: new Investor[](1), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 100});
        assertFullCase(c);
    }

    function test_twoEqualInvestorsExactMaxTarget() public {
        Case memory c = Case({maxTarget: 200, cap: 100, investors: new Investor[](2), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 100});
        c.investors[1] = Investor({addr: makeAddr("inv2"), amount: 100});
        assertFullCase(c);
    }

    function test_twoEqualInvestorsOverMaxTarget() public {
        Case memory c = Case({maxTarget: 200, cap: 100, investors: new Investor[](2), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 101});
        c.investors[1] = Investor({addr: makeAddr("inv2"), amount: 100});
        assertFullCase(c);
    }

    function test_noInvestors() public {
        Case memory c = Case({maxTarget: 2, cap: 0, investors: new Investor[](0), computedCap: 0});
        assertFullCase(c);
    }
}
