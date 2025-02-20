// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std-1.9.6/Script.sol";
import {ScriptExt} from "forge-zksync-std-0.0.1/ScriptExt.sol";
import {Paymaster} from "../src/Paymaster.sol";
import {Counter} from "../src/Counter.sol";

contract PaymasterScript is Script, ScriptExt {
    Paymaster public paymaster;
    Counter public counter;

    bytes private paymasterEncodedInput;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        paymaster = new Paymaster();
        (bool success, ) = address(paymaster).call{value: 1 ether}("");
        require(success, "Failed to fund Paymaster.");
        console.log("Paymaster balance after funding:", address(paymaster).balance);
        console.log("Initial user Balance:", address(msg.sender).balance);

        paymasterEncodedInput = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("")
        );

        console.log("Paymaster balance before set:", address(paymaster).balance);
        counter = new Counter();
        console.log("address(counter):", address(counter));

        vmExt.zkUsePaymaster(address(paymaster), paymasterEncodedInput);
        counter.setNumber(42);
        vm.roll(1);

        console.log("After calling setNumber(42) - Paymaster balance:", address(paymaster).balance);
        console.log("User Balance:", address(msg.sender).balance);

        vm.stopBroadcast();
    }
}
