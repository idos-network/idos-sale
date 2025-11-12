// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {SaleHarnessNoMerkle} from "test/harness/Sale.sol";
import {MockERC20} from "src/test/MockERC20.sol";

contract TestSetup is Test {
    SaleHarnessNoMerkle sale;
    MockERC20 token;
    MockERC20 paymentToken;
    uint256 start;
    uint256 end;
    uint256 startRegistration;
    uint256 endRegistration;

    function setUp() public {
        start = vm.getBlockTimestamp();
        end = start + 60 * 60 * 24;

        startRegistration = 1714089600;
        endRegistration = 1714694400;

        paymentToken = new MockERC20("USDC", "USDC", 6);
        token = new MockERC20("idos", "idos", 18);
        token.mint(address(this), 1e8 ether);

        sale = new SaleHarnessNoMerkle(
            address(paymentToken),
            0.2 * 1e6,
            start,
            end,
            10 ether,
            5 * 1e6,
            15 * 1e6,
            startRegistration,
            endRegistration
        );

        sale.setToken(address(token));
        sale.setMinContribution(sale.paymentTokenToToken(100 * 1e6));

        // TODO; the contract will no longer have tokens, so we don't need this
        token.transfer(address(sale), 1000000 ether);
    }
}
