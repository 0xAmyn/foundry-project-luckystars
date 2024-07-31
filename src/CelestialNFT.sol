// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/Script.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import "./CONST.sol";

contract CelestialNFT is VRFConsumerBaseV2Plus, ERC721, CONST {
    error CelestialNFT__NotEnoughEth();

    uint256 public tokenId;
    mapping(uint256 requestId => address user) requestIdToUserMapping;
    mapping(address user => mapping(uint256 tier => uint256 count)) userMintPermit;

    uint256 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    constructor(
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) ERC721("Celestial", "CLST") {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
    }

    function mintNft() public returns (string memory tokenURI) {
        // first we have to check if allowed to mint
    }

    function enterRaffle() public payable returns (uint256 requestId) {
        //check min amount
        if (msg.value < MIN_ETH_RAFFLE) {
            revert CelestialNFT__NotEnoughEth();
        }

        // ask vrf to create rnd
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        requestIdToUserMapping[requestId] = msg.sender;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 result = randomWords[0] % 100;
        uint256 tier;
        if (result < 65) {
            tier = 0;
        } else if (result < 85) {
            tier = 1;
        } else if (result < 95) {
            tier = 2;
        } else {
            tier = 3;
        }

        address user = requestIdToUserMapping[requestId];
        userMintPermit[user][tier] += 1;

        console.log(randomWords[0]);
        console.log(user);
        console.log(tier);
    }
}
