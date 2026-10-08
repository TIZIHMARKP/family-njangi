// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice shared data strucctures for the Njangi contract
library NjangiTypes {

    /// @notice lifecycle of a group
    enum GroupStatus {
        Active,            // contributions and payouts are running
        Completed,         // every round has been paid out
        Cancelled          // creator cancelled before the first contribution
    }

    /// @notice the full state of a Njangi group
    struct Group {
        uint256 id;
        string name;
        address creator;
        uint256 contributionAmount;
        uint256 memberCount;
        uint256 currentRound;
        uint256 totalContributedThisRound;
        GroupStatus status;
    }
}