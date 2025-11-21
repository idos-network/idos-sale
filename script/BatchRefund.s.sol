// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/Vm.sol";
import {Sale} from "src/Sale.sol";
import "@openzeppelin/utils/structs/EnumerableSet.sol";

contract BatchRefundScript is Script {
    Sale sale = Sale(0x825B4CbC7dDe0949e44770bf94354673261D75dC);
    
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private participants;

    function setUp() public  {
        uint256 fromBlock = 402296505;
        uint256 toBlock = vm.parseUint(vm.toString(vm.rpc("eth_blockNumber", "[]")));

        bytes32[] memory topics = new bytes32[](1);
        topics[0] = keccak256("Purchase(address,uint256)");

        for (uint256 i = fromBlock; i <= toBlock; i += 10000) {
            Vm.EthGetLogs[] memory logs =
                vm.eth_getLogs(i, Math.min(i+9999, toBlock), address(sale), topics);

            for (uint256 j = 0; j < logs.length; j++)
                participants.add(address(uint160(uint256(logs[j].topics[1]))));
        }
    }

    function run() public {
        vm.startBroadcast();

        for (uint256 i = 0; i < participants.length(); i++) {
            address investor = participants.at(i);
            uint256 refundAmount = sale.refundAmount(investor);
            console2.log(investor, refundAmount);
            if (refundAmount > 0) {
                console2.log("\tRefunding...");
                sale.refund(investor);
            }
        }

        vm.stopBroadcast();
    }
}
