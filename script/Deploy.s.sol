// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Sale} from "src/Sale.sol";
import {MockERC20} from "test/harness/MockERC20.sol";

contract Deploy is Script {
    address usdc = address(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); // TODO this is USDC. not sure if we want USDC.e instead?
    uint256 rate = 0.02 * 1e6; // 0.2 USDC per token
    uint256 start = 1763666258 + 5*60;
    uint256 end = start + 20*60;
    uint256 totalTokensForSale = 25_000_000 ether;
    uint256 minTarget = 500_000 * 1e6; // 500k USDC
    uint256 maxTarget = 2_000_000 * 1e6; // 2M USDC

    bytes32 merkleRoot = 0x6b8c1a07416ce8fbce1908512b9ed9fcbfded402a8efb565cb9b4749e23a9d3e;
    uint256 minContribution = 100 * 1e6; // 100 USDC
    address custodian = 0x9db7439D32AddFA91cCA564Ed23762ed218e8eA7;

    function run() public {
        vm.startBroadcast();

        MockERC20 paymentToken = new MockERC20("USDC", "USDC", 6);
        paymentToken.mint(address(0xeF1d9b810e3F7c59796F694e82Ff5872dCb5E498), 1000 ether);
        paymentToken.mint(address(0x8fDD962D2d7979F78Aa103E059C1F1a3D610167d), 1000 ether);
        paymentToken.mint(address(0x6E336729686A9964dD5D0fDDD57B30d057144bfb), 1000 ether);
        paymentToken.mint(address(0xb7C5Da13C06741F6604789fD76107b0896Afa4e9), 1000 ether);

        //Sale sale = new Sale(usdc, rate, start, end, minTarget, maxTarget);
        Sale sale = new Sale(address(paymentToken), rate, start, end, minTarget, maxTarget);

        sale.setMerkleRoot(merkleRoot);
        sale.setMinContribution(minContribution);
        sale.setCustodian(custodian);

        require(sale.totalTokensForSale() == totalTokensForSale, "total tokens for sale incorrect");

        vm.stopBroadcast();
    }
}
