// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title CelestialNFT
 * @dev NFT contract that uses Chainlink VRF for random tier assignment.
 */
contract CelestialNFT is VRFConsumerBaseV2Plus, ERC721, ERC721Burnable {
    // Custom errors for more efficient gas usage
    error CelestialNFT__InvalidEntranceCost();
    error CelestialNFT__TokenUriNotFound();
    error CelestialNFT__NotAllowedToMint(uint8 tier);

    // Events for logging key actions
    event CelestialNFT__RaffleEntered(address indexed user, uint256 indexed requestId);
    event CelestialNFT__Mint(address indexed user, uint8 indexed tier, uint256 tokenId);

    enum NftTier {
        Coal,
        Silver,
        Gold,
        Diamond
    }

    // State variables
    mapping(uint256 requestId => address user) private s_requestIdToUserMapping;
    mapping(address user => mapping(uint8 tier => uint256 count)) private s_userMintPermit;

    uint256 tokenId;
    string public baseTokenURI;
    mapping(uint256 tokenId => string tokenUri) private s_tokenIdToUri;
    mapping(uint256 tokenId => uint8 tier) private s_tokenToTier;

    // Immutable variables for Chainlink VRF configuration
    uint256 immutable s_enterCost;
    uint256 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant callbackGasLimit = 400000;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;


    /**
     * @dev Constructor initializes the contract with required parameters.
     * @param enterCost The cost to enter the raffle.
     * @param baseURI The base URI for token metadata.
     * @param vrfCoordinator The address of the VRF coordinator.
     * @param keyHash The key hash for VRF.
     * @param subscriptionId The subscription ID for VRF.
     */
    constructor(
        uint256 enterCost,
        string memory baseURI,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(vrfCoordinator) ERC721("Celestial", "CLST") {
        setBaseURI(baseURI);
        s_enterCost = enterCost;
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
    }

    /**
     * @dev Enter the raffle by paying the entrance cost.
     * @return requestId The request ID for the VRF.
     */
    function enterRaffle() public payable returns (uint256 requestId) {
        //check min amount
        if (msg.value != s_enterCost) {
            revert CelestialNFT__InvalidEntranceCost();
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
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        s_requestIdToUserMapping[requestId] = msg.sender;
        emit CelestialNFT__RaffleEntered(msg.sender, requestId);

        return requestId;
    }

    /**
     * @dev Fulfill the VRF random words request. Called by Chainlink's Coordinator.
     * @param requestId The request ID for the VRF.
     * @param randomWords The random words generated by VRF.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 result = randomWords[0] % 100;
        uint8 tier;
        if (result < 65) {
            tier = uint8(NftTier.Coal);
        } else if (result < 85) {
            tier = uint8(NftTier.Silver);
        } else if (result < 95) {
            tier = uint8(NftTier.Gold);
        } else {
            tier = uint8(NftTier.Diamond);
        }

        address user = s_requestIdToUserMapping[requestId];
        s_userMintPermit[user][tier] += 1;
    }

    /**
     * @dev Mint an NFT if the user has a permit for the specified tier.
     * @param tier The tier of the NFT to mint.
     * @return tokenUri The URI of the minted token.
     */
    function mintNft(uint8 tier) public returns (string memory) {
        // first we have to check if allowed to mint
        if (s_userMintPermit[msg.sender][tier] == 0) {
            revert CelestialNFT__NotAllowedToMint(tier);
        }

        string memory tokenUri;
        if (tier == uint8(NftTier.Coal)) tokenUri = string.concat(baseTokenURI, "coal-metadata.json");
        else if (tier == uint8(NftTier.Silver)) tokenUri = string.concat(baseTokenURI, "silver-metadata.json");
        else if (tier == uint8(NftTier.Gold)) tokenUri = string.concat(baseTokenURI, "gold-metadata.json");
        else if (tier == uint8(NftTier.Diamond)) tokenUri = string.concat(baseTokenURI, "diamond-metadata.json");
        else revert CelestialNFT__TokenUriNotFound();

        s_tokenIdToUri[tokenId] = tokenUri;
        s_tokenToTier[tokenId] = tier;

        _mint(msg.sender, tokenId);
        emit CelestialNFT__Mint(msg.sender, tier, tokenId);

        s_userMintPermit[msg.sender][tier] -= 1;
        tokenId++;

        return tokenUri;
    }


    /**
     * @dev Set the base URI for token metadata.
     * @param baseURI The new base URI.
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // -------------------------------------------------------------------------
    // ------------------------------- GETTERS ---------------------------------
    // -------------------------------------------------------------------------

    /**
     * @dev Get the permit count for a user's tier. Each time user mints the NFT, the permit count is decremented.
     * @param user The user's address.
     * @param tier The tier of the NFT.
     * @return The number of permits for the user's tier.
     */
    function getTierPermitCount(address user, uint8 tier) public view returns (uint256) {
        return s_userMintPermit[user][tier];
    }

    /**
     * @dev Get the token URI for a specific token ID.
     * @param tokenID The token ID.
     * @return The URI of the token.
     */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        if (ownerOf(tokenID) == address(0)) {
            revert CelestialNFT__TokenUriNotFound();
        }
        return s_tokenIdToUri[tokenID];
    }

    /**
     * @dev Get the tier of a specific token ID.
     * @param tokenID The token ID.
     * @return The tier of the token.
     */
    function getTokenTier(uint256 tokenID) public view returns (uint8) {
        return s_tokenToTier[tokenID];
    }


}
