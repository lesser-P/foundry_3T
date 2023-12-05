// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {TTTDemo} from "../src/TTTDemo.sol";

contract TTTDeploy is Script {
    function run(address router) public returns (TTTDemo ttdemo) {
        vm.startBroadcast();
        TTTDemo t = new TTTDemo(router);
        vm.stopBroadcast();
        return t;
    }
}
