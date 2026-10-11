// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Njangi} from "../src/Njangi.sol";


contract DeployNjangi is Script {
    function run() external returns (Njangi njangi) {
        vm.startBroadcast();
        njangi = new Njangi();
        vm.stopBroadcast();
    }
}