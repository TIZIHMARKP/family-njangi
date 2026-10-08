// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice events of Njangi contract
interface NjangiEvents {
    event GroupCreated(
        uint256 indexed groupId,
        address indexed creator,
        string name,
        uint256 contributionAmount,
        uint256 memberCount
    );

    event ContributionMade(
        uint256 indexed groupId,
        address indexed member,
        uint256 amount,
        uint256 round
    );

    event PayoutSent(
        uint256 indexed groupId,
        address indexed recipient,
        uint256 amount,
        uint256 round
    );

    event RoundAdvanced(
        uint256 indexed groupId,
        uint256 newRound
    );

    event GroupCompleted(
        uint256 indexed groupId
    );

    event GroupCancelled(
        uint256 indexed groupId
    );
}
