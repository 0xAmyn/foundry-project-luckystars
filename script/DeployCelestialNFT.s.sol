// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CelestialNFT} from "../src/CelestialNFT.sol";
import {ConfigHelper} from "./ConfigHelper.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract DeployCelestialNFT is Script {
    CelestialNFT celestialNFT;

    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant LOCAL_CHAINID = 31337;

    function run() external returns (CelestialNFT, address vrfcoord) {
        ConfigHelper helper = new ConfigHelper();
        ConfigHelper.Config memory config;
        VRFCoordinatorV2_5Mock mock;

        if (block.chainid == SEPOLIA_CHAINID) {
            config = helper.getSepoliaConfig();
        } else if (block.chainid == LOCAL_CHAINID) {
            (config, mock) = helper.getAnvilConfig();
        }

        vm.startBroadcast();
        celestialNFT = new CelestialNFT(
            config.vrfCoordinator,
            config.keyHash,
            config.subscriptionId
        );
        if (block.chainid == LOCAL_CHAINID) {
            mock.addConsumer(config.subscriptionId, address(celestialNFT));
        }
        vm.stopBroadcast();

        return (celestialNFT, config.vrfCoordinator);
    }
}
