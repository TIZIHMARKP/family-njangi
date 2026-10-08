// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice platform constants for the Njangi contract
library NjangiConstants {

    uint256 internal constant MIN_CONTRIBUTION = 1000 wei; // minimum contribution amount to prevent dust rounds

    uint256 internal constant MIN_MEMBERS = 2;  // minimum members required for a group

    uint256 internal constant MAX_MEMBERS = 20; // maximum members per group to keep loops bounded
}