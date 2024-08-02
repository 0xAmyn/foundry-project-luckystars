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

    event CelestialNFT__RaffleEntered(address indexed user, uint256 indexed requestId);
    event CelestialNFT__Mint(address indexed user, uint8 indexed tier, uint256 tokenId);

    function setUp() public {
        (celestialNFT, vrfCoordinator) = new DeployCelestialNFT().run();

        vm.deal(user0, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }

    function testEnterRaffle() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.001 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT));
    }

    function testMintNft() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.001 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT)); // coal is always selected
        vm.prank(user0);
        celestialNFT.mintNft(uint8(CelestialNFT.NftTier.Coal));
        assertEq(celestialNFT.ownerOf(0), user0);
    }

    function testEnterRaffle_notEnoughEther() public {
        vm.prank(user0);
        vm.expectRevert(abi.encodeWithSelector(CelestialNFT.CelestialNFT__InvalidEntranceCost.selector));
        celestialNFT.enterRaffle{value: 0.0000001 ether}();
    }

    function testEnterRaffle_ExpectEmitEnter() public {
        vm.prank(user0);

        vm.expectEmit(true, true, false, false, address(celestialNFT));
        emit CelestialNFT__RaffleEntered(address(user0), 1);

        celestialNFT.enterRaffle{value: 0.001 ether}();
    }

    function testMintNft_ExpectEmitMint() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.001 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT)); // coal is always selected

        vm.expectEmit(true, true, true, false, address(celestialNFT));
        emit CelestialNFT__Mint(address(user0), 0, 0);
        vm.prank(user0);
        celestialNFT.mintNft(uint8(CelestialNFT.NftTier.Coal));
    }

    function testBurn_RevertWhenAnotherUserTryToBurn() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.001 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT)); // coal is always selected
        vm.prank(user0);
        celestialNFT.mintNft(uint8(CelestialNFT.NftTier.Coal));
        
        vm.expectRevert();
        vm.prank(user1);
        celestialNFT.burn(0);
    }

    function testGetTierPermitCount() public {
        vm.prank(user0);
        uint256 requestId = celestialNFT.enterRaffle{value: 0.001 ether}();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(celestialNFT)); // coal is always selected
        
        uint256 userPermitCountBefore = celestialNFT.getTierPermitCount(user0, uint8(CelestialNFT.NftTier.Coal));

        vm.prank(user0);
        celestialNFT.mintNft(uint8(CelestialNFT.NftTier.Coal));

        uint256 userPermitCountAfter = celestialNFT.getTierPermitCount(user0, uint8(CelestialNFT.NftTier.Coal));
        uint256 tierCount = celestialNFT.getTokenTier(0);

        assertEq(userPermitCountBefore, 1);
        assertEq(userPermitCountAfter, 0);
        assertEq(tierCount, uint8(CelestialNFT.NftTier.Coal)); // token 0 is always coal
    }

}
