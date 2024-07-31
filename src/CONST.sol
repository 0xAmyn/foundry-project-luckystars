// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract CONST {
    uint256 public constant MIN_ETH_RAFFLE = 0.01 ether;

    enum NftTier {
        Coal,
        Silver,
        Gold,
        Diamond
    }
}
