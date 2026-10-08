// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Njangi} from "../src/Njangi.sol";
import {NjangiTypes} from "../src/types/NjangiTypes.sol";
import {NjangiErrors} from "../src/errors/NjangiErrors.sol";
import {NjangiConstants} from "../src/constants/NjangiConstants.sol";
import {INjangi} from "../src/interfaces/INjangi.sol";

abstract contract BaseTest is Test {
    Njangi internal njangi;

    address internal creator;
    address internal tizih;
    address internal mark;
    address internal prince;
    address internal stranger;

    uint256 internal constant CONTRIBUTION = 0.01 ether;

    function setUp() public virtual {
        njangi = new Njangi();

        creator = makeAddr("creator");
        tizih = makeAddr("tizih");
        mark = makeAddr("mark");
        prince = makeAddr("prince");
        stranger = makeAddr("stranger");
    }

    // helper function to build a member array of N addresses startx from tizih
    function _threeMembers() internal view returns (address[] memory members){
        members = new address[](3);
        members[0] = tizih;
        members[1] = mark;
        members[2] = prince;
    }

}

contract CreateGroupTest is BaseTest {
    function testCreateGroupHappyPath() public {
        address[] memory members = _threeMembers();

        vm.prank(creator);
        uint256 groupId = njangi.createGroup("Family Njangi", CONTRIBUTION, members);

        assertEq(groupId, 1);
        assertEq(njangi.getGroupCount(), 1);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(group.id, 1);
        assertEq(group.name, "Family Njangi");
        assertEq(group.creator, creator);
        assertEq(group.contributionAmount, CONTRIBUTION);
        assertEq(group.memberCount, 3);
        assertEq(group.currentRound, 0);
        assertEq(group.totalContributedThisRound, 0);
        assertEq(uint256(group.status), uint256(NjangiTypes.GroupStatus.Active));

        address[] memory stored = njangi.getMembers(groupId);
        assertEq(stored.length, 3);
        assertEq(stored[0], tizih);
        assertEq(stored[1], mark);
        assertEq(stored[2], prince);

        assertTrue(njangi.hasContributed(groupId, tizih) == false);
    }

    function testCreateGroupEmitsEvent() public {
        address[] memory members = _threeMembers();

        vm.expectEmit(true, true, false, true);
        emit INjangi.GroupCreated(1, creator, "Family Njangi", CONTRIBUTION, 3);
        // emit Njangi.GroupCreated(1, creator, "Family Njangi", CONTRIBUTION, 3);

        vm.prank(creator);
        njangi.createGroup("Family Njangi", CONTRIBUTION, members);
    }

    function testGroupIdsIncrement() public {
        address[] memory members = _threeMembers();

        vm.prank(creator);
        uint256 id1 = njangi.createGroup("First", CONTRIBUTION, members);

        vm.prank(creator);
        uint256 id2 = njangi.createGroup("Second", CONTRIBUTION, members);

        assertEq(id1, 1);
        assertEq(id2, 2);
        assertEq(njangi.getGroupCount(), 2);
    }

    function testCannotCreateWithEmptyName() public {
        address[] memory members = _threeMembers();

        vm.expectRevert(NjangiErrors.InvalidGroupName.selector);
        vm.prank(creator);
        njangi.createGroup("", CONTRIBUTION, members);
    }

    function testCannotCreateWithContributionBelowMinimum() public {
        address[] memory members = _threeMembers();

        vm.expectRevert(NjangiErrors.InvalidContributionAmount.selector);
        vm.prank(creator);
        njangi.createGroup("Test", NjangiConstants.MIN_CONTRIBUTION - 1, members);
    }

    function testCannotCreateWithTooFewMembers() public {
        address[] memory members = new address[](1);
        members[0] = tizih;

        vm.expectRevert(NjangiErrors.InvalidMemberCount.selector);
        vm.prank(creator);
        njangi.createGroup("Test", CONTRIBUTION, members);
    }

    function testCannotCreateWithTooManyMembers() public {
        uint256 max = NjangiConstants.MAX_MEMBERS;
        address[] memory members = new address[](max + 1);
        for (uint256 i = 0; i < max + 1; i++) {
            members[i] = address(uint160(uint256(keccak256(abi.encodePacked("member", i)))));
        }

        vm.expectRevert(NjangiErrors.InvalidMemberCount.selector);
        vm.prank(creator);
        njangi.createGroup("Test", CONTRIBUTION, members);
    }

    function testCannotCreateWithDuplicateMembers() public {
        address[] memory members = new address[](3);
        members[0] = tizih;
        members[1] = mark;
        members[2] = tizih; // duplicate

        vm.expectRevert(NjangiErrors.DuplicateMember.selector);
        vm.prank(creator);
        njangi.createGroup("Test", CONTRIBUTION, members);
    }

    function testCannotCreateWithZeroAddressMember() public {
        address[] memory members = new address[](3);
        members[0] = tizih;
        members[1] = address(0);
        members[2] = prince;

        vm.expectRevert(NjangiErrors.InvalidMemberCount.selector);
        vm.prank(creator);
        njangi.createGroup("Test", CONTRIBUTION, members);
    }

    function testCannotCreateWithCreatorAsMember() public {
        address[] memory members = new address[](3);
        members[0] = tizih;
        members[1] = creator; // creator is in the member list
        members[2] = mark;

        vm.expectRevert(NjangiErrors.CreatorCannotBeMember.selector);
        vm.prank(creator);
        njangi.createGroup("Test", CONTRIBUTION, members);
    }

    function testCreateGroupAtMinimumMembers() public {
        address[] memory members = new address[](2);
        members[0] = tizih;
        members[1] = mark;

        vm.prank(creator);
        uint256 groupId = njangi.createGroup("Pair", CONTRIBUTION, members);

        assertEq(njangi.getMembers(groupId).length, 2);
    }

    function testCreateGroupAtMaximumMembers() public {
        uint256 max = NjangiConstants.MAX_MEMBERS;
        address[] memory members = new address[](max);
        for (uint256 i = 0; i < max; i++) {
            members[i] = address(uint160(uint256(keccak256(abi.encodePacked("m", i)))));
        }

        vm.prank(creator);
        uint256 groupId = njangi.createGroup("Big", CONTRIBUTION, members);

        assertEq(njangi.getMembers(groupId).length, max);
    }


}
