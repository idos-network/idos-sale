pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {Sale} from "src/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";
import "forge-std/console.sol";

import {TestSetup} from "test/TestSetup.sol";

contract SaleMaxTargetReachedTest is TestSetup {
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    address[] testAccounts;
    bytes32[] proof = new bytes32[](0);

    uint256 day = 60 * 60 * 24;

    function setUp() public {
        setup();
    }

    function test_AllocationAfterMaxTargetReached() public {
        uint256 maxTarget = c.sale.maxTarget();

        invest(alice, maxTarget);
        invest(bob, maxTarget);

        endSale();

        setCap();

        assertEq(c.sale.risingTide_isValidCap(), true);
        assertEq(c.sale.allocation(address(alice)), maxTarget / 2);
        assertEq(c.sale.allocation(address(bob)), maxTarget / 2);
    }
}
