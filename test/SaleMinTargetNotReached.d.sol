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
        c.sale.setMinTarget(usdc(5));
        c.sale.setMaxTarget(usdc(10));

        uint256 aliceAmount = usdc(3);
        uint256 bobAmount1 = usdc(2);
        uint256 bobAmount2 = usdc(2);

        invest(alice, aliceAmount);
        invest(bob, bobAmount1);
        invest(bob, bobAmount2);

        endSale();

        assertEq(c.usdc.balanceOf(address(c.sale)), usdc(7));
        assertEq(c.sale.totalUncappedAllocations(), c.sale.paymentTokenToToken(aliceAmount + bobAmount1 + bobAmount2));
        assertEq(c.sale.allocation(address(alice)), aliceAmount);
        assertEq(c.sale.allocation(address(bob)), bobAmount1 + bobAmount2);
    }

    function test_RefundsWhenMinTargetNotReached() public {
        c.sale.setMinTarget(1 ether);

        uint256 amount = (c.sale.minTarget() / 2) - (usdc(1));

        invest(alice, amount);

        assertEq(c.usdc.balanceOf(address(c.sale)), amount);

        invest(bob, amount);

        assertEq(c.sale.totalUncappedAllocations(), amount * 2);
        assert(c.sale.totalUncappedAllocations() < c.sale.paymentTokenToToken(c.sale.minTarget()));

        endSale();

        assertEq(c.usdc.balanceOf(address(c.sale)), amount * 2);

        setCap();

        assertEq(c.sale.allocation(alice), 0);
        assertEq(c.sale.refundAmount(alice), amount);

        vm.prank(alice);
        c.sale.refund(alice);

        assertEq(c.usdc.balanceOf(address(c.sale)), amount);

        assertEq(c.sale.allocation(bob), 0);
        assertEq(c.sale.refundAmount(bob), amount);

        vm.prank(bob);
        c.sale.refund(bob);

        assertEq(c.usdc.balanceOf(address(c.sale)), 0);
    }
}
