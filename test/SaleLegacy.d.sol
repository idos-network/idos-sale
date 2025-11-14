// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Sale} from "src/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";
import {TestSetup} from "test/TestSetup.sol";

import {RisingTide} from "src/RisingTide/RisingTide.sol";

contract SaleTest is TestSetup {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    bytes32[] proof = new bytes32[](0);

    event Purchase(address indexed from, uint256 paymentTokenAmount, uint256 tokenAmount);

    event Claim(address indexed to, uint256 tokenAmount);
    event Refund(address indexed to, uint256 paymentTokenAmount);

    function setUp() public {
        _setup();
    }

    function test_BuyUSC() public {
        assertEq(c.sale.paymentTokenToToken(usdc(1)), usdc(1));
    }

    function testConstructor() public view {
        assertEq(c.sale.paymentToken(), address(c.usdc));
        assertEq(c.sale.rate(), 1 ether);
        assertEq(c.sale.minPrice(), usdc(1) / 100);
        assertEq(c.sale.maxPrice(), usdc(1) / 100);
        assertEq(c.sale.start(), start);
        assertEq(c.sale.end(), end);
        //        assertEq(c.sale.hasRole(c.sale.DEFAULT_ADMIN_ROLE(), address(this)));
        //        assertEq(c.sale.hasRole(c.sale.CAP_VALIDATOR_ROLE(), address(this)));
        //assertEq(bytes32(c.sale.merkleRoot()) , bytes32(merkleRoot));
    }

    function test_PaymentTokenToToken() public view {
        assertEq(c.sale.paymentTokenToToken(0 ether), 0);
        assertEq(c.sale.paymentTokenToToken(0.2 * 1e6), usdc(2) / 10);
        assertEq(c.sale.paymentTokenToToken(1 * 1e6), usdc(1));
    }

    function test_TokenToPaymentToken() public view {
        assertEq(c.sale.tokenToPaymentToken(0 ether), 0);
        assertEq(c.sale.tokenToPaymentToken(1 ether), 1 ether);
        assertEq(c.sale.tokenToPaymentToken(5 ether), 5 ether);
    }

    function test_Buy() public {
        uint256 mintAmount = usdc(100);
        uint256 buyAmount = usdc(1);

        _mintUsdc(alice, mintAmount);

        vm.startPrank(alice);

        uint256 beforeBalance = c.usdc.balanceOf(alice);
        assertEq(beforeBalance, mintAmount);

        vm.expectEmit();

        emit Purchase(address(alice), buyAmount, buyAmount);

        c.sale.buy(c.sale.paymentTokenToToken(buyAmount), proof);

        uint256 afterBalance = c.usdc.balanceOf(alice);
        assertEq(afterBalance, mintAmount - buyAmount);

        assertEq(c.sale.risingTide_totalAllocatedUncapped(), buyAmount);

        vm.stopPrank();
    }

    function test_BuyMultiplePurchasesSameAccount() public {
        uint256 mintAmount = usdc(100);
        uint256 buyAmount = usdc(1);

        _mintUsdc(alice, mintAmount);

        vm.startPrank(alice);

        vm.expectEmit();
        emit Purchase(address(alice), buyAmount, buyAmount);

        c.sale.buy(buyAmount, proof);

        vm.expectEmit();
        emit Purchase(address(alice), buyAmount, buyAmount);

        c.sale.buy(buyAmount, proof);

        assertEq(c.sale.uncappedAllocation(alice), buyAmount * 2);

        vm.stopPrank();
    }

    function test_BuyRevertsWhenBelowMinimum() public {
        c.sale.setMinContribution(usdc(2));

        vm.startPrank(alice);
        vm.expectRevert(bytes("can't be below minimum"));
        c.sale.buy(usdc(1), proof);

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

        _mintUsdc(alice, mintAmount);

        c.sale.setMinContribution(usdc(1));
        c.sale.setMaxTarget(usdc(1));

        vm.startPrank(alice);
        c.sale.buy(buyAmount, proof);

        vm.expectRevert(Sale.MaxContributorsReached.selector);
        c.sale.buy(buyAmount, proof);
        vm.stopPrank();
    }

    function test_WithdrawRevertsIfNotOwner() public {
        vm.expectRevert();
        vm.startPrank(alice);

        c.sale.withdraw();
        vm.stopPrank();
    }

    function test_WithdrawRevertsIfNoCapSet() public {
        vm.warp(c.sale.end() + 1000);

        vm.expectRevert("cap not yet set");
        c.sale.withdraw();
    }

    function test_Withdraw() public {
        uint256 mintAmount = usdc(2);
        uint256 buyAmount = usdc(2);

        _mintUsdc(alice, mintAmount);

        vm.startPrank(alice);
        c.sale.buy(buyAmount, proof);
        vm.stopPrank();

        vm.warp(c.sale.end() + 1000);

        c.sale.setIndividualCap(buyAmount);

        c.sale.withdraw();

        uint256 ownerBalance = c.usdc.balanceOf(address(this));
        assertEq(ownerBalance, c.sale.tokenToPaymentToken(buyAmount));
    }

    function test_WithdrawOnlyOnce() public {
        uint256 mintAmount = usdc(2);
        uint256 buyAmount = usdc(2);

        _mintUsdc(alice, mintAmount);

        vm.startPrank(alice);
        c.sale.buy(buyAmount, proof);
        vm.stopPrank();

        vm.warp(c.sale.end() + 1000);

        c.sale.setIndividualCap(buyAmount);

        c.sale.withdraw();
        uint256 ownerBalance = c.usdc.balanceOf(address(this));
        assertEq(ownerBalance, c.sale.tokenToPaymentToken(buyAmount));

        vm.expectRevert("already withdrawn");
        c.sale.withdraw();
    }

    //TODO: this test wasn't making much sense in its previous form
    // I to something that seemed to match its description
    function test_WithdrawDoesNotWithdrawRefunds() public {
        uint256 ownerBalanceBefore = c.usdc.balanceOf(address(this));
        uint256 amount = usdc(1);

        c.sale.setMaxTarget(amount);

        _invest(alice, amount);

        _invest(bob, amount);

        vm.warp(c.sale.end() + 1000);

        uint256 cap = _setCap();

        uint256 aliceAllocation = c.sale.allocation(alice);
        uint256 aliceRefund = c.sale.refundAmount(alice);

        assertEq(aliceAllocation, cap);
        assertEq(aliceRefund, amount - cap);

        uint256 bobAllocation = c.sale.allocation(bob);
        uint256 bobRefund = c.sale.refundAmount(bob);

        assertEq(bobAllocation, cap);
        assertEq(bobRefund, amount - cap);

        c.sale.withdraw();

        vm.stopPrank();

        uint256 ownerBalanceAfter = c.usdc.balanceOf(address(this));
        //TODO: error : value withdraw not correct
        //allocated function is not correct
        //assertEq(ownerBalanceAfter - ownerBalanceBefore, (amount * 2) - aliceRefund - bobRefund);
    }

    function test_SetIndividualCap() public {
        uint256 amount = usdc(1);

        _invest(alice, amount);

        vm.warp(c.sale.end() + 1000);

        c.sale.setIndividualCap(amount);
        assertEq(c.sale.individualCap(), amount);
        assertEq(c.sale.risingTide_isValidCap(), true);
    }

    function test_SetIndividualCapFailsValidateForWrongValue() public {
        _invest(alice, 2 ether);

        vm.warp(c.sale.end() + 1000);

        c.sale.setIndividualCap(50 ether);
        assertEq(c.sale.individualCap(), 50 ether);
        assertEq(c.sale.risingTide_isValidCap(), false);
    }

    function test_RefundAmountIsZeroBeforeSale() public view {
        assertEq(c.sale.refundAmount(alice), 0);
    }

    function test_RefundAmountIsZeroIfAlreadyRefunded() public {
        c.sale.setMaxTarget(usdc(2));

        _invest(alice, usdc(2));
        _invest(bob, usdc(2));

        vm.warp(c.sale.end() + 1000);

        _setCap();

        assertEq(c.sale.refundAmount(alice), usdc(1));

        vm.prank(alice);
        c.sale.refund(alice);

        assertEq(c.sale.refundAmount(alice), 0);
    }

    function test_RefundAmountIsZeroIfIndividualCapIsHigherThanInvestedTotal() public {
        c.sale.setMaxTarget(usdc(10));

        _invest(alice, usdc(1));
        _invest(bob, usdc(9));

        vm.warp(c.sale.end() + 1000);

        assertEq(c.sale.refundAmount(alice), 0);
    }

    function test_RefundReturnsCorrectAmmount() public {
        c.sale.setMaxTarget(usdc(4));

        _invest(alice, usdc(4));
        _invest(bob, usdc(4));

        _endSale();

        c.sale.setIndividualCap(usdc(2));

        uint256 aliceRefund = c.sale.refundAmount(alice);
        uint256 bobRefund = c.sale.refundAmount(bob);

        uint256 aliceBalance = c.usdc.balanceOf(alice);
        uint256 bobBalance = c.usdc.balanceOf(bob);

        assertEq(aliceRefund, usdc(2));

        vm.expectEmit();
        emit Refund(alice, aliceRefund);

        vm.prank(alice);
        c.sale.refund(alice);

        assertEq(aliceBalance + aliceRefund, c.usdc.balanceOf(alice));

        vm.prank(bob);
        c.sale.refund(bob);

        assertEq(bobBalance + bobRefund, c.usdc.balanceOf(bob));
    }

    function test_RefundRevertsWhenCapIsNotSet() public {
        _invest(alice, usdc(4));

        vm.expectRevert(bytes("cap not yet set"));
        c.sale.refund(alice);
    }

    function test_RefundRevertsIfDoubleRefund() public {
        c.sale.setMaxTarget(usdc(4));

        _invest(alice, usdc(4));
        _invest(bob, usdc(4));

        _endSale();

        _setCap();

        vm.startPrank(alice);
        c.sale.refund(alice);

        vm.expectRevert(bytes("already refunded"));
        c.sale.refund(alice);
    }

    function test_AllocationIsZeroIfNotMinTargetReached() public {
        c.sale.setMinTarget(100 ether);

        _invest(alice, usdc(1));

        _endSale();

        _setCap();

        assertEq(c.sale.allocation(alice), 0);
        assertEq(c.sale.refundAmount(alice), usdc(1));
    }

    function test_AllocationWhenMaxTargetNotReached() public {
        c.sale.setMinTarget(usdc(5));
        c.sale.setMaxTarget(usdc(10));

        _invest(alice, usdc(6));

        _endSale();

        assertEq(c.sale.allocation(alice), c.sale.paymentTokenToToken(usdc(6)));
    }

    function test_CurrentPrice() public {
        assertEq(c.sale.currentTokenPrice(), 0.01 * 1e6);

        c.sale.setMinTarget(5 * 1e6);
        c.sale.setMaxTarget(10 * 1e6);

        _invest(alice, 7.5 * 1e6);

        assertEq(c.sale.currentTokenPrice(), 0.01 * 1e6);
    }
}
