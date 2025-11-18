pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Sale} from "src/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";
import {TestSetup} from "test/TestSetup.sol";

import "forge-std/console.sol";

contract SaleMinTargetNotReachedTest is TestSetup {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    bytes32[] proof = new bytes32[](0);

    uint256 DAY = 60 * 60 * 24;

    function setUp() public {
        setup();
    }

    function test_AllocationWhenMinTargetReached() public {
        ctx.sale.setMinTarget(usdc(5));
        ctx.sale.setMaxTarget(usdc(10));

        uint256 aliceAmount = usdc(3);
        uint256 bobAmount1 = usdc(2);
        uint256 bobAmount2 = usdc(2);

        invest(alice, aliceAmount);
        invest(bob, bobAmount1);
        invest(bob, bobAmount2);

        endSale();

        assertEq(ctx.usdc.balanceOf(address(ctx.sale)), usdc(7));
        assertEq(ctx.sale.totalUncappedAllocations(), aliceAmount + bobAmount1 + bobAmount2);
        assertEq(ctx.sale.allocation(address(alice)), aliceAmount);
        assertEq(ctx.sale.allocation(address(bob)), bobAmount1 + bobAmount2);
    }

    function test_RefundsWhenMinTargetNotReached() public {
        ctx.sale.setMinTarget(1 ether);

        uint256 amount = (ctx.sale.minTarget() / 2) - (usdc(1));

        invest(alice, amount);

        assertEq(ctx.usdc.balanceOf(address(ctx.sale)), amount);

        invest(bob, amount);

        assertEq(ctx.sale.totalUncappedAllocations(), amount * 2);
        assert(ctx.sale.totalUncappedAllocations() < ctx.sale.minTarget());

        endSale();

        assertEq(ctx.usdc.balanceOf(address(ctx.sale)), amount * 2);

        setCap();

        assertEq(ctx.sale.allocation(alice), 0);
        assertEq(ctx.sale.refundAmount(alice), amount);

        vm.prank(alice);
        ctx.sale.refund(alice);

        assertEq(ctx.usdc.balanceOf(address(ctx.sale)), amount);

        assertEq(ctx.sale.allocation(bob), 0);
        assertEq(ctx.sale.refundAmount(bob), amount);

        vm.prank(bob);
        ctx.sale.refund(bob);

        assertEq(ctx.usdc.balanceOf(address(ctx.sale)), 0);
    }
}
