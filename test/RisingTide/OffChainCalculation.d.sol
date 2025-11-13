// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TestSetup} from "../TestSetup.sol";
import {Sale} from "src/Sale.sol";
import {OffChainCalculator} from "src/RisingTide/OffChainCalculator.sol";
import {SaleHarnessNoMerkle} from "test/harness/Sale.sol";
import {console} from "forge-std/console.sol";

contract OffChaincalculatorTest is TestSetup {
    OffChainCalculator calculator;
    uint64 duration = 100;
    address alice;
    address bob;

    bytes32[] proof = new bytes32[](0);

    function setUp() public {
        setup();
        calculator = new OffChainCalculator();

        uint256 start = vm.getBlockTimestamp();
        uint256 end = start + 24 hours;
        c.sale = new SaleHarnessNoMerkle(address(c.usdc), 1 * 1e6, start, end, 100 ether, 5 * 1e6, 100 * 1e6);

        c.sale.setMinContribution(1);

        alice = makeAddr("alice");
        bob = makeAddr("bob");

        vm.startPrank(alice);
        c.usdc.mint(address(alice), 1e8 ether);
        c.usdc.approve(address(c.sale), 1e8 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        c.usdc.mint(address(bob), 1e8 ether);
        c.usdc.approve(address(c.sale), 1e8 ether);
        vm.stopPrank();
    }

    function test_case1() public {
        c.sale.setMinTarget(1 * 1e6);
        c.sale.setMaxTarget(100 * 1e6);

        vm.startPrank(alice);
        c.sale.buy(c.sale.paymentTokenToToken(10 * 1e6), proof);
        vm.stopPrank();

        vm.startPrank(bob);
        c.sale.buy(c.sale.paymentTokenToToken(100 * 1e6), proof);
        vm.stopPrank();

        vm.warp(c.sale.end() + duration);

        uint256 cap = calculator.computeCap(c.sale);

        assertEq(cap, 90 * 1e6);
    }

    function test_gitbook() public {
        c.sale.setMaxTarget(500_000);
        c.sale.setMinTarget(0);

        address[10] memory investors = [
            makeAddr("inv1"),
            makeAddr("inv2"),
            makeAddr("inv3"),
            makeAddr("inv4"),
            makeAddr("inv5"),
            makeAddr("inv6"),
            makeAddr("inv7"),
            makeAddr("inv8"),
            makeAddr("inv9"),
            makeAddr("inv10")
        ];

        uint256[10] memory contributions =
            [uint256(50_000), 100_000, 75_000, 50_000, 100_000, 75_000, 20_000, 100_000, 80_000, 100_000];

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            c.usdc.mint(investor, 1e9 ether);
            vm.startPrank(investor);
            c.usdc.approve(address(c.sale), type(uint256).max);
            c.sale.buy(c.sale.paymentTokenToToken(contributions[i]), proof);
            vm.stopPrank();
        }

        vm.warp(c.sale.end() + duration);

        uint256 cap = calculator.computeCap(c.sale);

        assertEq(cap, 54285);
    }

    function test_gitbook_small() public {
        // Arrange
        c.sale.setMaxTarget(500_000);
        c.sale.setMinTarget(0);

        // Create 10 mock investors
        address[1] memory investors = [makeAddr("inv1")];

        uint256[1] memory contributions = [uint256(50_000)];

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            c.usdc.mint(investor, 1e9 ether);
            vm.startPrank(investor);
            c.usdc.approve(address(c.sale), type(uint256).max);
            c.sale.buy(c.sale.paymentTokenToToken(contributions[i]), proof);
            vm.stopPrank();
        }

        vm.warp(c.sale.end() + duration);

        uint256 cap = calculator.computeCap(c.sale);

        assertEq(cap, contributions[0]);
    }

    function test_realPrice() public {
        // Arrange
        c.sale.setMaxTarget(1 * 1e18);
        c.sale.setMinTarget(0);

        // Create 10 mock investors
        address[3] memory investors = [makeAddr("inv1"), makeAddr("inv2"), makeAddr("inv3")];

        uint256[3] memory contributions = [uint256(0.5 * 1e18), 0.5 * 1e18, 0.5 * 1e18];

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            c.usdc.mint(investor, 1e9 ether);
            vm.startPrank(investor);
            c.usdc.approve(address(c.sale), type(uint256).max);
            c.sale.buy(c.sale.paymentTokenToToken(contributions[i]), proof);
            vm.stopPrank();
        }

        vm.warp(c.sale.end() + duration);

        uint256 cap = calculator.computeCap(c.sale);

        assertEq(cap, 333333333333333333);
    }
}

