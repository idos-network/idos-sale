// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {SaleHarnessNoMerkle} from "test/harness/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";
import {OffChainCalculator} from "src/RisingTide/OffChainCalculator.sol";
import {RisingTide} from "src/RisingTide/RisingTide.sol";

contract TestSetup is Test {
    struct Ctx {
        SaleHarnessNoMerkle sale;
        MockERC20 usdc;
    }

    struct Case {
        uint256 maxTarget;
        int256 cap; // negative means we don't know
        uint256[] investors;
        uint256 computedCap; // filled in by the test runner
        uint256 capMaxDelta; // cap deviation from maxTarget
    }

    TestSetup.Ctx public ctx;

    // deploys a token sale
    // TODO hardcoding sale target to [1$, 10_000_000$]
    // hardcoding tokens for sale to 1 ether, but shouldn't be a problem as all we care about are relative allocations
    function setup() internal {
        setup(1 ether);
    }

    function setup(uint256 maxTarget) internal {
        uint256 start = vm.getBlockTimestamp();
        uint256 end = start + 24 hours;

        ctx.usdc = new MockERC20("USDC", "USDC", 6);
        ctx.sale = new SaleHarnessNoMerkle(
            address(ctx.usdc), // paymentToken
            1 ether, // rate TODO: set to 1 for now to get it out of the way
            start, // start timestamp
            end, // end timestamp
            1 ether, // tokens for sale TODO: set to 1 for now to get it out of the way
            1, // min target
            maxTarget
        );

        // TODO: min contribution set to minimum non-zero possible, just to get it out of the way for now
        ctx.sale.setMinContribution(1);
    }

    function usdc(uint256 amount) internal pure returns (uint256) {
        return amount * 1e6;
    }

    function eth(uint256 amount) internal pure returns (uint256) {
        return amount * 1e18;
    }

    function endSale() internal {
        vm.warp(ctx.sale.end() + 1000);
    }

    function assertFullCase(Case memory c) internal {
        setup(c.maxTarget);
        applyDeposits(c.investors);
        c.computedCap = assertRisingTideCap(c.cap, c.capMaxDelta);
        assertRefunds(c);
    }

    function invest(address addr, uint256 amount) private {
        vm.startPrank(addr);
        ctx.usdc.mint(addr, amount);
        ctx.usdc.approve(address(ctx.sale), amount);
        ctx.sale.buy(amount, new bytes32[](0));
        vm.stopPrank();
    }

    // optionally checks the cap against a given value
    // run on-chain validation to ensure cap is validated
    function assertRisingTideCap(int256 expectedCap, uint256 maxDelta) private returns (uint256) {
        // perform off-chain cap calculation
        OffChainCalculator calculator = new OffChainCalculator();
        uint256 cap = calculator.computeCap(ctx.sale);

        // if provided, assert the cap is what we expect
        if (expectedCap >= 0) {
            assertApproxEqAbs(cap, uint256(expectedCap), maxDelta);
        }

        // validate cap using on-chain logic
        endSale();
        ctx.sale.setIndividualCap(cap);
        while (ctx.sale.risingTideState() == RisingTide.RisingTideState.Validating) {
            ctx.sale.risingTide_validate();
        }
        assert(ctx.sale.risingTide_isValidCap());
        return cap;
    }

    function applyDeposits(uint16[] memory amounts) private {
        for (uint160 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }
            address addr = address(i + 1);
            invest(addr, amounts[i]);
        }
    }

    function applyDeposits(uint256[] memory investors) private {
        for (uint160 i = 0; i < investors.length; i++) {
            if (investors[i] == 0) {
                continue;
            }
            invest(address(i + 1), investors[i]);
        }
    }

    function assertRefunds(Case memory c) private view {
        for (uint160 i = 0; i < c.investors.length; i++) {
            if (c.investors[i] == 0) {
                continue;
            }
            uint256 uncapped = c.investors[i];
            uint256 capped = uncapped > c.computedCap ? c.computedCap : uncapped;
            assertEq(ctx.sale.refundAmount(address(i + 1)), uncapped - capped);
        }
    }
}
