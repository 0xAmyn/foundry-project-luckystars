// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract ConfigHelper is Script {
    struct Config {
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
    }

    function getSepoliaConfig() external pure returns (Config memory) {
        Config memory config;
        config.vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
        config.keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        config.subscriptionId = 13776262586500480373311165999477537471776542632075330984454994469971867623352;

        return config;
    }

    function getArbSepoliaConfig() external pure returns (Config memory) {
        Config memory config;
        config.vrfCoordinator = 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61;
        config.keyHash = 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be;
        config.subscriptionId = 57936845172886992251547119765040066857818563253583446363768873029455652265665;

        return config;
    }

    function getAnvilConfig() external returns (Config memory, VRFCoordinatorV2_5Mock) {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock mock = new VRFCoordinatorV2_5Mock(0.001 ether, 1e9, 4e15);
        uint256 subscriptionId = mock.createSubscription();
        mock.fundSubscription(subscriptionId, 10 ether);

        vm.stopBroadcast();

        Config memory config;
        config.vrfCoordinator = address(mock);
        config.keyHash = 0x0;
        config.subscriptionId = subscriptionId;

        return (config, mock);
    }
}
