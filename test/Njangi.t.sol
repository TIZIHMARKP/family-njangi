// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Njangi} from "../src/Njangi.sol";
import {NjangiTypes} from "../src/types/NjangiTypes.sol";
import {NjangiErrors} from "../src/errors/NjangiErrors.sol";
import {NjangiConstants} from "../src/constants/NjangiConstants.sol";
import {NjangiEvents} from "../src/events/NjangiEvents.sol";
// import {INjangi} from "../src/interfaces/INjangi.sol";

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
        // emit INjangi.GroupCreated(1, creator, "Family Njangi", CONTRIBUTION, 3);
        // emit Njangi.GroupCreated(1, creator, "Family Njangi", CONTRIBUTION, 3);
        emit NjangiEvents.GroupCreated(1, creator, "Family Njangi", CONTRIBUTION, 3);


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

contract ContributeTest is BaseTest {
    uint256 internal groupId;

    function setUp() public override {
        super.setUp();

        address[] memory members = _threeMembers();
        vm.prank(creator);
        groupId = njangi.createGroup("Family Njangi", CONTRIBUTION, members);
    }

    // ------ happy path ----------

    function testContributeHappyPath() public {
        vm.deal(tizih, 1 ether);

        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(group.totalContributedThisRound, CONTRIBUTION);
        assertTrue(njangi.hasContributed(groupId, tizih));
    }

    function testContributeEmitsEvent() public {
        vm.deal(tizih, 1 ether);

        vm.expectEmit(true, true, false, true);
        emit NjangiEvents.ContributionMade(groupId, tizih, CONTRIBUTION, 0);

        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);
    }

    function testMultipleMembersCanContribute() public {
        vm.deal(tizih, 1 ether);
        vm.deal(mark, 1 ether);
        vm.deal(prince, 1 ether);

        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.prank(mark);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.prank(prince);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(group.totalContributedThisRound, CONTRIBUTION * 3);

        assertTrue(njangi.hasContributed(groupId, tizih));
        assertTrue(njangi.hasContributed(groupId, mark));
        assertTrue(njangi.hasContributed(groupId, prince));
    }

    // ------ reverts handlers -------

    function testCannotContributeWrongAmount() public {
        vm.deal(tizih, 1 ether);

        vm.expectRevert(NjangiErrors.IncorrectContributionAmount.selector);
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION - 1}(groupId);
    }

    function testCannotContributeTwice() public {
        vm.deal(tizih, 1 ether);

        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.expectRevert(NjangiErrors.AlreadyContributed.selector);
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);
    }

    function testStrangerCannotContribute() public {
        vm.deal(stranger, 1 ether);

        vm.expectRevert(NjangiErrors.NotAMember.selector);
        vm.prank(stranger);
        njangi.contribute{value: CONTRIBUTION}(groupId);
    }

    function testCannotContributeToNonExistentGroup() public {
        vm.deal(tizih, 1 ether);

        vm.expectRevert(NjangiErrors.GroupDoesNotExist.selector);
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(999);
    }

    function testCannotContributeAfterCancel() public {
        vm.prank(creator);
        njangi.cancelGroup(groupId);

        vm.deal(tizih, 1 ether);

        vm.expectRevert(NjangiErrors.GroupNotActive.selector);
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);
    }
}


contract PayoutTest is BaseTest {
    uint256 internal groupId;

    function setUp() public override {
        super.setUp();

        address[] memory members = _threeMembers();
        vm.prank(creator);
        groupId = njangi.createGroup("Family Njangi", CONTRIBUTION, members);

        vm.deal(tizih, 1 ether);  // funding all members
        vm.deal(mark, 1 ether);
        vm.deal(prince, 1 ether);
    }

    // helper fxn to let everyone pay for the current round
    function _allContributeForCurrentRound() internal {
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.prank(mark);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.prank(prince);
        njangi.contribute{value: CONTRIBUTION}(groupId);
    }

        // ------ happy path ----------

    function testPayoutSendsPotToFirstMember() public {
        _allContributeForCurrentRound();

        uint256 expectedPot = CONTRIBUTION * 3;
        uint256 tizihBefore = tizih.balance;

        njangi.payout(groupId);

        assertEq(tizih.balance, tizihBefore + expectedPot);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(group.currentRound, 1);
        assertEq(group.totalContributedThisRound, 0);
    }

    function testPayoutEmitsEvents() public {
        _allContributeForCurrentRound();

        uint256 expectedPot = CONTRIBUTION * 3;

        vm.expectEmit(true, true, false, true);
        emit NjangiEvents.PayoutSent(groupId, tizih, expectedPot, 0);

        njangi.payout(groupId);
    }

    function testPayoutRotatesThroughAllMembers() public {
        // round 0: tizih receives the njangi
        _allContributeForCurrentRound();
        uint256 tizihBefore = tizih.balance;
        njangi.payout(groupId);
        assertEq(tizih.balance, tizihBefore + CONTRIBUTION * 3);

        // round 1: mark receives the njangi
        _allContributeForCurrentRound();
        uint256 markBefore = mark.balance;
        njangi.payout(groupId);
        assertEq(mark.balance, markBefore + CONTRIBUTION * 3);

        // round 2: prince receives the njangi
        _allContributeForCurrentRound();
        uint256 princeBefore = prince.balance;
        njangi.payout(groupId);

        assertEq(prince.balance, princeBefore + CONTRIBUTION * 3);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(uint256(group.status), uint256(NjangiTypes.GroupStatus.Completed));
    }

    function testRoundAdvancedEventEmitted() public {
        _allContributeForCurrentRound();

        vm.expectEmit(true, false, false, true);
        emit NjangiEvents.RoundAdvanced(groupId, 1);

        njangi.payout(groupId);
    }

    function testGroupCompletedEventEmittedOnFinalPayout() public {
        
        _allContributeForCurrentRound(); // complete rounds 0 and 1 silently
        njangi.payout(groupId);

        _allContributeForCurrentRound();
        njangi.payout(groupId);

        _allContributeForCurrentRound();  // cinal round: expect GroupCompleted

        vm.expectEmit(true, false, false, false);
        emit NjangiEvents.GroupCompleted(groupId);

        njangi.payout(groupId);
    }

        // ------ reverts handlers -------

    function testCannotPayoutWhenRoundNotFull() public {
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.expectRevert(NjangiErrors.RoundNotFull.selector);
        njangi.payout(groupId);
    }

    function testCannotPayoutNonExistentGroup() public {
        vm.expectRevert(NjangiErrors.GroupDoesNotExist.selector);
        njangi.payout(999);
    }

    function testCannotPayoutAfterGroupCompleted() public {
        // complete all three rounds
        _allContributeForCurrentRound();
        njangi.payout(groupId);

        _allContributeForCurrentRound();
        njangi.payout(groupId);

        _allContributeForCurrentRound();
        njangi.payout(groupId);

        // group is now completed so the payout should revert n not work
        vm.expectRevert(NjangiErrors.GroupNotActive.selector);
        njangi.payout(groupId);
    }
}


contract CancelGroupTest is BaseTest {
    uint256 internal groupId;

    function setUp() public override {
        super.setUp();

        address[] memory members = _threeMembers();
        vm.prank(creator);
        groupId = njangi.createGroup("Family Njangi", CONTRIBUTION, members);
    }

    // ------ happy path ----------

    function testCreatorCanCancelBeforeContributions() public {
        vm.expectEmit(true, false, false, false);
        emit NjangiEvents.GroupCancelled(groupId);

        vm.prank(creator);
        njangi.cancelGroup(groupId);

        NjangiTypes.Group memory group = njangi.getGroup(groupId);
        assertEq(uint256(group.status), uint256(NjangiTypes.GroupStatus.Cancelled));
    }

    // ------ reverts handlers -------

    function testCannotCancelAfterContribution() public {
        vm.deal(tizih, 1 ether);
        vm.prank(tizih);
        njangi.contribute{value: CONTRIBUTION}(groupId);

        vm.expectRevert(NjangiErrors.CannotCancelAfterStart.selector);
        vm.prank(creator);
        njangi.cancelGroup(groupId);
    }

    function testOnlyCreatorCanCancel() public {
        vm.expectRevert(NjangiErrors.NotGroupCreator.selector);
        vm.prank(tizih);
        njangi.cancelGroup(groupId);
    }

    function testCannotCancelNonExistentGroup() public {
        vm.expectRevert(NjangiErrors.GroupDoesNotExist.selector);
        vm.prank(creator);
        njangi.cancelGroup(999);
    }

}



