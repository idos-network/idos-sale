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

    function test_gitbookExample() public {
        Case memory c = Case({maxTarget: 5000, cap: 542, investors: new Investor[](10), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 500});
        c.investors[1] = Investor({addr: makeAddr("inv2"), amount: 1000});
        c.investors[2] = Investor({addr: makeAddr("inv3"), amount: 750});
        c.investors[3] = Investor({addr: makeAddr("inv4"), amount: 500});
        c.investors[4] = Investor({addr: makeAddr("inv5"), amount: 1000});
        c.investors[5] = Investor({addr: makeAddr("inv6"), amount: 750});
        c.investors[6] = Investor({addr: makeAddr("inv7"), amount: 200});
        c.investors[7] = Investor({addr: makeAddr("inv8"), amount: 1000});
        c.investors[8] = Investor({addr: makeAddr("inv9"), amount: 800});
        c.investors[9] = Investor({addr: makeAddr("inv10"), amount: 1000});

        assertFullCase(c);
    }

    function test_edgeCase() public {
        Case memory c = Case({maxTarget: 100, cap: 90, investors: new Investor[](2), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 10});
        c.investors[1] = Investor({addr: makeAddr("inv2"), amount: 100});
        assertFullCase(c);
    }

    function test_roundingErrors() public {
        Case memory c = Case({maxTarget: 100, cap: 33, investors: new Investor[](3), computedCap: 0});
        c.investors[0] = Investor({addr: makeAddr("inv1"), amount: 100});
        c.investors[1] = Investor({addr: makeAddr("inv2"), amount: 100});
        c.investors[2] = Investor({addr: makeAddr("inv3"), amount: 100});
        assertFullCase(c);
    }

    function testFuzz_randomInputs(uint16[] memory amounts, uint256 total) public {
        vm.assume(amounts.length > 0);
        vm.assume(amounts.length < 10_000);
        vm.assume(total > 1);
        vm.assume(total >= amounts.length); // TODO: since minContribution is 1, this ensures we never hit MaxContributorsReached

        Case memory c = Case({maxTarget: total, cap: -1, investors: new Investor[](amounts.length), computedCap: 0});
        for (uint160 i = 0; i < amounts.length; i++) {
            c.investors[i] = Investor({addr: makeAddr(vm.toString(i)), amount: amounts[i]});
        }
    }
}
