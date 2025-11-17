// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Sale} from "src/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";
import {TestSetup} from "test/TestSetup.sol";

import {RisingTide} from "src/RisingTide/RisingTide.sol";

contract SaleLegacyTest is TestSetup {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    bytes32[] proof = new bytes32[](0);

    event Purchase(address indexed from, uint256 paymentTokenAmount, uint256 tokenAmount);

    event Claim(address indexed to, uint256 tokenAmount);
    event Refund(address indexed to, uint256 paymentTokenAmount);

    function setUp() public {
        setup();
    }

    function test_BuyUSC() public {
        assertEq(ctx.sale.paymentTokenToToken(usdc(1)), usdc(1));
    }

    function testConstructor() public view {
        assertEq(ctx.sale.paymentToken(), address(ctx.usdc));
        assertEq(ctx.sale.rate(), 1 ether);
        assertEq(ctx.sale.minPrice(), usdc(1) / 100);
        assertEq(ctx.sale.maxPrice(), usdc(1) / 100);
        assertEq(ctx.sale.start(), start);
        assertEq(ctx.sale.end(), end);
        //        assertEq(ctx.sale.hasRole(ctx.sale.DEFAULT_ADMIN_ROLE(), address(this)));
        //        assertEq(ctx.sale.hasRole(ctx.sale.CAP_VALIDATOR_ROLE(), address(this)));
        //assertEq(bytes32(ctx.sale.merkleRoot()) , bytes32(merkleRoot));
    }

    function test_PaymentTokenToToken() public view {
        assertEq(ctx.sale.paymentTokenToToken(0 ether), 0);
        assertEq(ctx.sale.paymentTokenToToken(0.2 * 1e6), usdc(2) / 10);
        assertEq(ctx.sale.paymentTokenToToken(1 * 1e6), usdc(1));
    }

    function test_TokenToPaymentToken() public view {
        assertEq(ctx.sale.tokenToPaymentToken(0 ether), 0);
        assertEq(ctx.sale.tokenToPaymentToken(1 ether), 1 ether);
        assertEq(ctx.sale.tokenToPaymentToken(5 ether), 5 ether);
    }

    function test_Buy() public {
        uint256 mintAmount = usdc(100);
        uint256 buyAmount = usdc(1);

        mintUsdc(alice, mintAmount);

        vm.startPrank(alice);

        uint256 beforeBalance = ctx.usdc.balanceOf(alice);
        assertEq(beforeBalance, mintAmount);

        vm.expectEmit();

        emit Purchase(address(alice), buyAmount, buyAmount);

        ctx.sale.buy(ctx.sale.paymentTokenToToken(buyAmount), proof);

        uint256 afterBalance = ctx.usdc.balanceOf(alice);
        assertEq(afterBalance, mintAmount - buyAmount);

        assertEq(ctx.sale.risingTide_totalAllocatedUncapped(), buyAmount);

        vm.stopPrank();
    }

    function test_BuyMultiplePurchasesSameAccount() public {
        uint256 mintAmount = usdc(100);
        uint256 buyAmount = usdc(1);

        mintUsdc(alice, mintAmount);

        vm.startPrank(alice);

        vm.expectEmit();
        emit Purchase(address(alice), buyAmount, buyAmount);

        ctx.sale.buy(buyAmount, proof);

        vm.expectEmit();
        emit Purchase(address(alice), buyAmount, buyAmount);

        ctx.sale.buy(buyAmount, proof);

        assertEq(ctx.sale.uncappedAllocation(alice), buyAmount * 2);

        vm.stopPrank();
    }

    function test_BuyRevertsWhenBelowMinimum() public {
        ctx.sale.setMinContribution(usdc(2));

        vm.startPrank(alice);
        vm.expectRevert(bytes("can't be below minimum"));
        ctx.sale.buy(usdc(1), proof);

        vm.stopPrank();
    }

    //function test_BuyRevertsWhenInvalidMerkleProof() public {
    //    vm.startPrank(alice);
    //    vm.expectRevert(Sale.InvalidLeaf.selector);
    //    sale.buy(2 ether, bobMerkleProof);
    //    vm.stopPrank();
    //}

    function test_BuyRevertsAfterReachingMaxTarget() public {
        uint256 mintAmount = 10 ether;
        uint256 buyAmount = 5 ether;

        mintUsdc(alice, mintAmount);

        ctx.sale.setMinContribution(usdc(1));
        ctx.sale.setMaxTarget(usdc(1));

        vm.startPrank(alice);
        ctx.sale.buy(buyAmount, proof);

        vm.expectRevert(Sale.MaxContributorsReached.selector);
        ctx.sale.buy(buyAmount, proof);
        vm.stopPrank();
    }

    function test_WithdrawRevertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);

        ctx.sale.withdraw();
        vm.stopPrank();
    }

    function test_WithdrawRevertsIfCustodianNotSet() public {
        ctx.sale.setCustodian(address(0));
        vm.expectRevert(bytes("CustodianNoSet()"));
        ctx.sale.withdraw();
    }

    function test_WithdrawRevertsIfNoCapSet() public {
        vm.warp(ctx.sale.end() + 1000);

        vm.expectRevert("cap not yet set");
        ctx.sale.withdraw();
    }

    function test_Withdraw() public {
        uint256 mintAmount = usdc(2);
        uint256 buyAmount = usdc(2);

        mintUsdc(alice, mintAmount);

        vm.startPrank(alice);
        ctx.sale.buy(buyAmount, proof);
        vm.stopPrank();

        vm.warp(ctx.sale.end() + 1000);

        ctx.sale.setIndividualCap(buyAmount);

        ctx.sale.withdraw();

        uint256 ownerBalance = ctx.usdc.balanceOf(address(this));
        assertEq(ownerBalance, ctx.sale.tokenToPaymentToken(buyAmount));
    }

    function test_WithdrawOnlyOnce() public {
        uint256 mintAmount = usdc(2);
        uint256 buyAmount = usdc(2);

        mintUsdc(alice, mintAmount);

        vm.startPrank(alice);
        ctx.sale.buy(buyAmount, proof);
        vm.stopPrank();

        vm.warp(ctx.sale.end() + 1000);

        ctx.sale.setIndividualCap(buyAmount);

        ctx.sale.withdraw();
        uint256 ownerBalance = ctx.usdc.balanceOf(address(this));
        assertEq(ownerBalance, ctx.sale.tokenToPaymentToken(buyAmount));

        vm.expectRevert("already withdrawn");
        ctx.sale.withdraw();
    }

    //TODO: this test wasn't making much sense in its previous form
    // I to something that seemed to match its description
    function test_WithdrawDoesNotWithdrawRefunds() public {
        uint256 ownerBalanceBefore = ctx.usdc.balanceOf(address(this));
        uint256 amount = usdc(1);

        ctx.sale.setMaxTarget(amount);

        invest(alice, amount);

        invest(bob, amount);

        vm.warp(ctx.sale.end() + 1000);

        uint256 cap = setCap();

        uint256 aliceAllocation = ctx.sale.allocation(alice);
        uint256 aliceRefund = ctx.sale.refundAmount(alice);

        assertEq(aliceAllocation, cap);
        assertEq(aliceRefund, amount - cap);

        uint256 bobAllocation = ctx.sale.allocation(bob);
        uint256 bobRefund = ctx.sale.refundAmount(bob);

        assertEq(bobAllocation, cap);
        assertEq(bobRefund, amount - cap);

        ctx.sale.withdraw();

        vm.stopPrank();

        uint256 ownerBalanceAfter = ctx.usdc.balanceOf(address(this));
        //TODO: error : value withdraw not correct
        //allocated function is not correct
        assertEq(ownerBalanceAfter - ownerBalanceBefore, (amount * 2) - aliceRefund - bobRefund);
    }

    function test_SetIndividualCap() public {
        uint256 amount = usdc(1);

        invest(alice, amount);

        vm.warp(ctx.sale.end() + 1000);

        ctx.sale.setIndividualCap(amount);
        assertEq(ctx.sale.individualCap(), amount);
        assertEq(ctx.sale.risingTide_isValidCap(), true);
    }

    function test_SetIndividualCapFailsValidateForWrongValue() public {
        invest(alice, 2 ether);

        vm.warp(ctx.sale.end() + 1000);

        ctx.sale.setIndividualCap(50 ether);
        assertEq(ctx.sale.individualCap(), 50 ether);
        assertEq(ctx.sale.risingTide_isValidCap(), false);
    }

    function test_RefundAmountIsZeroBeforeSale() public view {
        assertEq(ctx.sale.refundAmount(alice), 0);
    }

    function test_RefundAmountIsZeroIfAlreadyRefunded() public {
        ctx.sale.setMaxTarget(usdc(2));

        invest(alice, usdc(2));
        invest(bob, usdc(2));

        vm.warp(ctx.sale.end() + 1000);

        setCap();

        assertEq(ctx.sale.refundAmount(alice), usdc(1));

        vm.prank(alice);
        ctx.sale.refund(alice);

        assertEq(ctx.sale.refundAmount(alice), 0);
    }

    function test_RefundAmountIsZeroIfIndividualCapIsHigherThanInvestedTotal() public {
        ctx.sale.setMaxTarget(usdc(10));

        invest(alice, usdc(1));
        invest(bob, usdc(9));

        vm.warp(ctx.sale.end() + 1000);

        assertEq(ctx.sale.refundAmount(alice), 0);
    }

    function test_RefundReturnsCorrectAmmount() public {
        ctx.sale.setMaxTarget(usdc(4));

        invest(alice, usdc(4));
        invest(bob, usdc(4));

        endSale();

        ctx.sale.setIndividualCap(usdc(2));

        uint256 aliceRefund = ctx.sale.refundAmount(alice);
        uint256 bobRefund = ctx.sale.refundAmount(bob);

        uint256 aliceBalance = ctx.usdc.balanceOf(alice);
        uint256 bobBalance = ctx.usdc.balanceOf(bob);

        assertEq(aliceRefund, usdc(2));

        vm.expectEmit();
        emit Refund(alice, aliceRefund);

        vm.prank(alice);
        ctx.sale.refund(alice);

        assertEq(aliceBalance + aliceRefund, ctx.usdc.balanceOf(alice));

        vm.prank(bob);
        ctx.sale.refund(bob);

        assertEq(bobBalance + bobRefund, ctx.usdc.balanceOf(bob));
    }

    function test_RefundRevertsWhenCapIsNotSet() public {
        invest(alice, usdc(4));

        vm.expectRevert(bytes("cap not yet set"));
        ctx.sale.refund(alice);
    }

    function test_RefundRevertsIfDoubleRefund() public {
        ctx.sale.setMaxTarget(usdc(4));

        invest(alice, usdc(4));
        invest(bob, usdc(4));

        endSale();

        setCap();

        vm.startPrank(alice);
        ctx.sale.refund(alice);

        vm.expectRevert(bytes("already refunded"));
        ctx.sale.refund(alice);
    }

    function test_AllocationIsZeroIfNotMinTargetReached() public {
        ctx.sale.setMinTarget(100 ether);

        invest(alice, usdc(1));

        endSale();

        setCap();

        assertEq(ctx.sale.allocation(alice), 0);
        assertEq(ctx.sale.refundAmount(alice), usdc(1));
    }

    function test_AllocationWhenMaxTargetNotReached() public {
        ctx.sale.setMinTarget(usdc(5));
        ctx.sale.setMaxTarget(usdc(10));

        invest(alice, usdc(6));

        endSale();

        assertEq(ctx.sale.allocation(alice), ctx.sale.paymentTokenToToken(usdc(6)));
    }

    function test_CurrentPrice() public {
        assertEq(ctx.sale.currentTokenPrice(), 0.01 * 1e6);

        ctx.sale.setMinTarget(5 * 1e6);
        ctx.sale.setMaxTarget(10 * 1e6);

        invest(alice, 7.5 * 1e6);

        assertEq(ctx.sale.currentTokenPrice(), 0.01 * 1e6);
    }
}
