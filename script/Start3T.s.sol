// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {TTTDemo} from "../src/TTTDemo.sol";

contract Start3T is Script {
    address sepoliaContract = 0x6961883b86CAA1e09031E9472DccA6A68DA30941;
    address mumbaiContract = 0x676f5411d73B4f66c7001FF9556a05a6f3D99805;

    uint64 sepo_chainSelector = 16015286601757825753;
    uint64 mum_chainSelector = 12532609583862916517;

    TTTDemo sepolia3T;
    TTTDemo mumbai3T;

    function run() public {
        sepolia3T = TTTDemo(payable(sepoliaContract));
        mumbai3T = TTTDemo(payable(mumbaiContract));
        startGame();
    }

    function startGame() public {
        vm.startBroadcast();
        sepolia3T.start(mum_chainSelector, mumbaiContract);
        vm.stopBroadcast();
    }
}
