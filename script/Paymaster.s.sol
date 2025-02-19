// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { ScriptExt } from "forge-zksync-std/ScriptExt.sol";
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

        // Prepare encoded input for using the Paymaster
        paymasterEncodedInput = abi.encodeWithSelector(
            bytes4(keccak256("general(bytes)")),
            bytes("")
        );
        // Use the zkUsePaymaster cheatcode for next transaction
        vmExt.zkUsePaymaster(paymaster, paymasterEncodedInput);
        // Deploy the Counter contract using the Paymaster
        counter = new Counter();

        vmExt.zkUsePaymaster(paymaster, paymasterEncodedInput);
        counter.setNumber(42);

        vm.stopBroadcast();
    }
}
