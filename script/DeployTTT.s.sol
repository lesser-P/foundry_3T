// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "../lib/forge-std/src/Script.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {TTTDemo} from "../src/TTTDemo.sol";

contract StartTTT is Script {
    address sepoliaRouter = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
    address mumbaiRouter = 0x70499c328e1E2a3c41108bd3730F6670a44595D1;

    TTTDemo sepolia_ttt;
    TTTDemo mumbai_ttt;

    function run() public {
        deployContract();
        //updateRouter();
        // startNewGame();
    }

    function deployContract() public {
        vm.startBroadcast();
        // 放入接受者路由
        sepolia_ttt = new TTTDemo(sepoliaRouter);
        //mumbai_ttt = new TTTDemo(mumbaiRouter);
        // 更新自己的路由
        sepolia_ttt.updateRouter(sepoliaRouter);
        //mumbai_ttt.updateRouter(mumbaiRouter);
        vm.stopBroadcast();
    }

    function updateRouter() public {
        vm.startBroadcast();
        sepolia_ttt.updateRouter(sepoliaRouter);
        //mumbai_ttt.updateRouter(mumbaiRouter);
        vm.stopBroadcast();
    }
}
