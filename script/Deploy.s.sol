// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Sale} from "src/Sale.sol";

contract Deploy is Script {
    address usdc = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); // TODO this is USDC. not sure if we want USDC.e instead?
    uint256 rate = 0; // TODO
    uint256 start = 0; // TODO
    uint256 end = 0; // TODO
    uint256 totalTokensForSale = 25_000_000 ether; // TODO
    uint256 minTarget = 0; // TODO
    uint256 maxTarget = 0; // TODO
    uint256 startRegistration = 0; // TODO
    uint256 endRegistration = 0; // TODO

    address capValidator = address(0x0); // TODO
    address custodian = address(0x0); // TODO

    function run() public {
        vm.startBroadcast();
        Sale sale = new Sale(
            usdc, rate, start, end, totalTokensForSale, minTarget, maxTarget, startRegistration, endRegistration
        );
        sale.grantRole(sale.CAP_VALIDATOR_ROLE(), capValidator);
        sale.setCustodian(custodian);
        vm.stopBroadcast();
    }
}
