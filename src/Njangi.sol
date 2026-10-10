// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { INjangi } from "./interfaces/INjangi.sol";
import { NjangiTypes } from "./types/NjangiTypes.sol";
import {NjangiErrors} from "./errors/NjangiErrors.sol";
import {NjangiConstants} from "./constants/NjangiConstants.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Njangi is INjangi ReentrancyGuard {

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


    // ================ CONTRIBUTIONS ====================

    function contribute(uint256 groupId) external payable override groupExists(groupId){
        NjangiTypes.Group storage group = s_groups[groupId];

        
        if (group.status != NjangiTypes.GroupStatus.Active) { // group must be active
            revert NjangiErrors.GroupNotActive();
        }

        if (!s_isMember[groupId][msg.sender]) {  // caller must be a member
            revert NjangiErrors.NotAMember();
        }

        if (msg.value != group.contributionAmount) {  // must send exactly the contribution amount
            revert NjangiErrors.IncorrectContributionAmount();
        }

        uint256 round = group.currentRound;
        if (s_paidThisRound[groupId][round][msg.sender]) {  // must not have already contributed this round
            revert NjangiErrors.AlreadyContributed();
        }

        s_paidThisRound[groupId][round][msg.sender] = true;  // record contribution
        group.totalContributedThisRound += msg.value;

        emit ContributionMade(groupId, msg.sender, msg.value, round);
    }

    // ================ PAYOUT ====================

    function payout(uint256 groupId) external override groupExists(groupId) nonReentrant {
        NjangiTypes.Group storage group = s_groups[groupId];

        if (group.status != NjangiTypes.GroupStatus.Active) {
            revert NjangiErrors.GroupNotActive();
        }

        // the round must be full
        uint256 round = group.currentRound;
        uint256 expectedPot = group.contributionAmount * group.memberCount;
        if (group.totalContributedThisRound != expectedPot) {
            revert NjangiErrors.RoundNotFull();
        }

        address recipient = s_members[groupId][round];   // determine recipient
        uint256 payoutAmount = group.totalContributedThisRound;

        group.totalContributedThisRound = 0;  // reset round contribution counter before the transfer

        group.currentRound = round + 1;  // next round

        if (group.currentRound == group.memberCount) {  // check if the group just finished its last round so as to pay the recipient and move to the next round
            group.status = NjangiTypes.GroupStatus.Completed;
        }

        emit PayoutSent(groupId, recipient, payoutAmount, round);

        // send the pot
        (bool success, ) = payable(recipient).call{value: payoutAmount}("");
        if (!success) revert NjangiErrors.TransferFailed();

        emit RoundAdvanced(groupId, group.currentRound);

        if (group.status == NjangiTypes.GroupStatus.Completed) {
            emit GroupCompleted(groupId);
        }
    }

    // ================ CANCEL GROUP ====================
    function cancelGroup(uint256 groupId) external override groupExists(groupId){
        NjangiTypes.Group storage group = s_groups[groupId];

        if (msg.sender != group.creator) {      // only the creator can cancel
            revert NjangiErrors.NotGroupCreator();
        }

        if (group.currentRound != 0 || group.totalContributedThisRound != 0) { // can only cancel before any contribution has been made
            revert NjangiErrors.CannotCancelAfterStart();
        }

        group.status = NjangiTypes.GroupStatus.Cancelled;

        emit GroupCancelled(groupId);
    }









    // ========= VIEW FUNCTIONS ====================
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