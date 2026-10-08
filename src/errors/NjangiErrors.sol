// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice custom errors for the Njangi contract
library NjangiErrors {

    // ------ group creation -----------
    error InvalidGroupName();
    error InvalidContributionAmount();
    error InvalidMemberCount();
    error DuplicateMember();
    error CreatorCannotBeMember();

    // -------- group state ---------
    error GroupDoesNotExist();
    error GroupNotActive();
    error GroupNotCompleted();
    error GroupNotCancelled();

    // --------- membership -----
    error NotAMember();
    error AlreadyContributed();

    // --------- contributions ------------
    error IncorrectContributionAmount();
    error RoundNotFull();
    error RoundAlreadyPaid();

    // ------------ payout ----------
    error TransferFailed();

    // ---- cancel ----------
    error CannotCancelAfterStart();
    error CannotCancelAsStranger();

    // ------------- access ----------
    error NotGroupCreator();
}