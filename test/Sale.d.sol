// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestSetup} from "./TestSetup.sol";

contract SaleTest is TestSetup {
    function test_buy() public {
        setup();
    }

    function test_singleInvestor() public {
        Case memory c = Case({
            maxTarget: 100, cap: 100, investors: new uint256[](1), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        c.investors[0] = 100;
        assertFullCase(c);
    }

    function test_twoEqualInvestorsExactMaxTarget() public {
        Case memory c = Case({
            maxTarget: 200, cap: 100, investors: new uint256[](2), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        c.investors[0] = 100;
        c.investors[1] = 100;
        assertFullCase(c);
    }

    function test_twoEqualInvestorsOverMaxTarget() public {
        Case memory c = Case({
            maxTarget: 200, cap: 100, investors: new uint256[](2), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        c.investors[0] = 101;
        c.investors[1] = 100;
        assertFullCase(c);
    }

    function test_noInvestors() public {
        Case memory c = Case({
            maxTarget: 2, cap: 0, investors: new uint256[](0), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        assertFullCase(c);
    }

    function test_gitbookExample() public {
        Case memory c = Case({
            maxTarget: 5000,
            cap: 542,
            investors: new uint256[](10),
            computedCap: 0,
            capMaxDelta: 0,
            alreadySorted: false
        });
        c.investors[0] = 500;
        c.investors[1] = 1000;
        c.investors[2] = 750;
        c.investors[3] = 500;
        c.investors[4] = 1000;
        c.investors[5] = 750;
        c.investors[6] = 200;
        c.investors[7] = 1000;
        c.investors[8] = 800;
        c.investors[9] = 1000;

        assertFullCase(c);
    }

    function test_edgeCase() public {
        Case memory c = Case({
            maxTarget: 100, cap: 90, investors: new uint256[](2), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        c.investors[0] = 10;
        c.investors[1] = 100;
        assertFullCase(c);
    }

    function test_roundingErrors() public {
        Case memory c = Case({
            maxTarget: 100, cap: 33, investors: new uint256[](3), computedCap: 0, capMaxDelta: 0, alreadySorted: false
        });
        c.investors[0] = 100;
        c.investors[1] = 100;
        c.investors[2] = 100;
        assertFullCase(c);
    }

    function testFuzz_randomInputs(uint16[] memory _amounts, uint256 total) public {
        vm.assume(_amounts.length > 0);
        vm.assume(_amounts.length < 10_000);
        vm.assume(total > 1);
        vm.assume(total >= _amounts.length); // TODO: since minContribution is 1, this ensures we never hit MaxContributorsReached

        uint256[] memory amounts = new uint256[](_amounts.length);
        for (uint160 i = 0; i < amounts.length; i++) {
            amounts[i] = _amounts[i];
        }

        Case memory c =
            Case({maxTarget: total, cap: -1, investors: amounts, computedCap: 0, capMaxDelta: 0, alreadySorted: false});
        assertFullCase(c);
    }

    function test_totalTokensForSale() public {
        setup();
        assertEq(ctx.sale.totalTokensForSale(), 1 ether);
    }
}
