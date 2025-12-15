// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Oracle} from "../src/Oracle.sol";

contract OracleScript is Script {
    Oracle public oracle;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        oracle = new Oracle();

        vm.stopBroadcast();
    }
}
