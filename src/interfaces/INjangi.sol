// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { NjangiTypes } from "../types/NjangiTypes.sol";
import { NjangiEvents } from "../events/NjangiEvents.sol";

/// @notice public api interface of the Njangi contract
interface INjangi is NjangiEvents {

    // create a new njangi grp with a name
    function createGroup(
        string calldata name,
        uint256 contributionAmount,
        address[] calldata members            // ordered list of members
    ) external returns (uint256 groupId);     // we return the new groups ID


    function contribute(uint256 groupId) external payable; // contribute fixed amount for a current round in ETH

    function payout(uint256 groupId) external;   // send the round pot to the current person recieving the njangi

    function cancelGroup(uint256 groupId) external; // creator can cancell the grp b4 any contribution


    // =======       VIEWS     ===============

    // get full grp state
    function getGroup(uint256 groupId) external view returns (NjangiTypes.Group memory);

    // get payout order for a grp
    function getMembers(uint256 groupId) external view returns (address[] memory);

    // get the address of the person turn that it is to receive the njangi
    function getCurrentRecipient(uint256 groupId) external view returns (address);

    // get the total number of grp
    function getGroupCount() external view returns (uint256);

    // check if an address has contributed for a round
    function hasContributed(uint256 groupId, address member) external view returns (bool);

}