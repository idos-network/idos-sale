// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Sale} from "src/Sale.sol";

contract Deploy is Script {
    address usdc = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); // TODO this is USDC. not sure if we want USDC.e instead?
    uint256 rate = 0.02 * 1e6; // 0.2 USDC per token
    uint256 start = 0; // TODO
    uint256 end = 0; // TODO
    uint256 totalTokensForSale = 25_000_000 ether;
    uint256 minTarget = 500_000 * 1e6; // 500k USDC
    uint256 maxTarget = 2_000_000 * 1e6; // 2M USDC

    function run() public {
        vm.startBroadcast();
        Sale sale = new Sale(usdc, rate, start, end, minTarget, maxTarget);
        require(sale.totalTokensForSale() == totalTokensForSale, "total tokens for sale incorrect");
        vm.stopBroadcast();
    }
}
