// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { INjangi } from "./interfaces/INjangi.sol";
import { NjangiTypes } from "./types/NjangiTypes.sol";
import {NjangiErrors} from "./errors/NjangiErrors.sol";
import {NjangiConstants} from "./constants/NjangiConstants.sol";

abstract contract Njangi is INjangi {

    // =========== STATE =====================
    uint256 private s_groupCounter;            // grp counts in IDs
    mapping(uint256 => NjangiTypes.Group) private s_groups;  // all grp 
    mapping(uint256 => address[]) private s_members;    // grp members in payout order
    mapping(uint256 => mapping(address => bool)) private s_isMember;  // members id check
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private s_paidThisRound;  // who paid for a specific round

    // ==== MODIFIERS ==
    modifier groupExists(uint256 groupId){
        if(s_groups[groupId].id == 0) revert NjangiErrors.GroupDoesNotExist();
        _;
    }

    // ===== FUNCTIONS =======

    // create grp
     function createGroup(
        string calldata name,
        uint256 contributionAmount,
        address[] calldata members
    ) external override returns (uint256 groupId) {

        // input validations
        if (bytes(name).length == 0) revert NjangiErrors.InvalidGroupName();

        if (contributionAmount < NjangiConstants.MIN_CONTRIBUTION) {
            revert NjangiErrors.InvalidContributionAmount();
        }

        uint256 memberCount = members.length;
        if (memberCount < NjangiConstants.MIN_MEMBERS || memberCount > NjangiConstants.MAX_MEMBERS) {
            revert NjangiErrors.InvalidMemberCount();
        }

        // members validation
        for (uint256 i = 0; i < memberCount; i++) {
            address member = members[i];
            // if address = 0
            if (member == address(0)) revert NjangiErrors.InvalidMemberCount();

            // the creator is not a member
            if (member == msg.sender) revert NjangiErrors.CreatorCannotBeMember();

            // no duplicate member
            for (uint256 j = 0; j < i; j++) {
                if (members[j] == member) revert NjangiErrors.DuplicateMember();
            }
        }

        // saving the grp created
        groupId = ++s_groupCounter;

        s_groups[groupId] = NjangiTypes.Group({
            id: groupId,
            name: name,
            creator: msg.sender,
            contributionAmount: contributionAmount,
            memberCount: memberCount,
            currentRound: 0,
            totalContributedThisRound: 0,
            status: NjangiTypes.GroupStatus.Active
        });

        // storing members | membership

        for (uint256 i = 0; i < memberCount; i++) {
            s_members[groupId].push(members[i]);
            s_isMember[groupId][members[i]] = true;
        }

        // output
        emit GroupCreated(groupId, msg.sender, name, contributionAmount, memberCount);

    }

    // ===== VIEW FUNCTIONS ===============
    function getGroup(uint256 groupId) external view override groupExists(groupId) 
        returns (NjangiTypes.Group memory){
        return s_groups[groupId];
    }

    function getMembers(uint256 groupId) external view override groupExists(groupId)
        returns (address[] memory) {
        return s_members[groupId];
    }

    function getGroupCount() external view override returns (uint256) {
        return s_groupCounter;
    }

    function hasContributed(uint256 groupId, address member) external view override
        returns (bool) {
        uint256 round = s_groups[groupId].currentRound;
        return s_paidThisRound[groupId][round][member];
    }

    function getCurrentRecipient(uint256 groupId) external view override groupExists(groupId)
        returns (address) {
        uint256 round = s_groups[groupId].currentRound;
        return s_members[groupId][round];
    }
}