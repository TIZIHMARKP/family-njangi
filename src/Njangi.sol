// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { INjangi } from "./interfaces/INjangi.sol";
import { NjangiTypes } from "./types/NjangiTypes.sol";

abstract contract Njangi is INjangi {

    // =========== STATE =====================
    uint256 private s_groupCounter;            // grp counts in IDs
    mapping(uint256 => NjangiTypes.Group) private s_groups;  // all grp 
    mapping(uint256 => address[]) private s_members;    // grp members in payout order
    mapping(uint256 => mapping(address => bool)) private s_isMember;  // members id check
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private s_paidThisRound;  // who paid for a specific round

    // ===== FUNCTIONS =======
}