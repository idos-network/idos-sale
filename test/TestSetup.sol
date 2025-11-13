// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {SaleHarnessNoMerkle} from "test/harness/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";

contract TestSetup is Test {
    SaleHarnessNoMerkle sale;
    MockERC20 token;
    MockERC20 paymentToken;
    uint256 start;
    uint256 end;
    uint256 startRegistration;
    uint256 endRegistration;

    struct TestCase {
        SaleHarnessNoMerkle sale;
    }

    function _deploySale(uint64 duration) internal returns (TestCase memory ret) {
        start = vm.getBlockTimestamp();
        end = start + duration;

        paymentToken = new MockERC20("USDC", "USDC", 6);
        token = new MockERC20("idos", "idos", 18);
        token.mint(address(this), 1e8 ether);

        ret.sale = new SaleHarnessNoMerkle(address(paymentToken), 0.2 * 1e6, start, end, 10 ether, 5 * 1e6, 15 * 1e6);

        sale.setMinContribution(sale.paymentTokenToToken(100 * 1e6));

        // TODO; the contract will no longer have tokens, so we don't need this
        token.transfer(address(sale), 1000000 ether);
    }
}
