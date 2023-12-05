// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {TTTDemo} from "../src/TTTDemo.sol";

contract TTTDemoTest is Test {
    TTTDemo sepolia_contract;
    TTTDemo mumbai_contract;
    address OWNER = makeAddr("OWNER");
    uint256 sepoliaId;
    uint256 mumbaiId;
    address sepoliaRouter = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
    address mumbaiRouter = 0x70499c328e1E2a3c41108bd3730F6670a44595D1;

    function setUp() public {
        sepoliaId = vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"));
        deal(OWNER, 100 ether);
        vm.startPrank(OWNER);
        sepolia_contract = new TTTDemo(sepoliaRouter);
        vm.stopPrank();

        mumbaiId = vm.createSelectFork(vm.envString("MUMBAI_RPC_URL"));
        deal(OWNER, 100 ether);
        vm.startPrank(OWNER);
        mumbai_contract = new TTTDemo(mumbaiRouter);
        vm.stopPrank();
    }

    function testStartNewGame() public {
        vm.selectFork(sepoliaId);
        vm.startPrank(OWNER);
        sepolia_contract.updateRouter(mumbaiRouter);
        sepolia_contract.start(uint64(vm.envUint("MUMBAI_CHAIN_SELECTOR")), address(mumbai_contract));
        bytes32 _uniqueId = keccak256(abi.encodePacked(block.timestamp, msg.sender));
        bytes32 uniqueId = sepolia_contract.sessionIds(0);
        assertEq(_uniqueId, uniqueId);
        vm.stopPrank();
    }

    function testUpdateRouter() public {
        vm.startPrank(OWNER);
        vm.selectFork(sepoliaId);
        console.log("sepolia router", sepolia_contract._router());
        address _testRouter = makeAddr("TEST ROUTER");
        sepolia_contract.updateRouter(_testRouter);
        assertEq(_testRouter, sepolia_contract._router());
        vm.stopPrank();
    }

    function testSepoliaContract() public {
        string memory desc = sepolia_contract.description();
        string memory version = mumbai_contract.description();
        console.log(desc);
        assertEq(desc, "this is version 0.0");
        assertEq(version, "this is version 0.0");
    }
}
