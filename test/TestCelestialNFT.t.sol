// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployCelestialNFT} from "../script/DeployCelestialNFT.s.sol";
import {CelestialNFT} from "../src/CelestialNFT.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestCelestialNFT is Test {
    CelestialNFT celestialNFT;
    address vrfCoordinator;

    address user0 = makeAddr("user0");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");

    function setUp() public {
        (celestialNFT, vrfCoordinator) = new DeployCelestialNFT().run();

        vm.deal(user0, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }

    function testenterRaffle() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.1 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT));
    }
}
