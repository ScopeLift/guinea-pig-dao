// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {GuineaPigGovernor, IVotes, TimelockController} from "src/GuineaPigGovernor.sol";
import {GuineaPigToken} from "src/GuineaPigToken.sol";

contract GuineaPigGovernorTest is Test {
  GuineaPigGovernor governor;

  IVotes token;
  TimelockController timelock;

  uint256 INITIAL_VOTING_DELAY = 50;
  uint256 INITIAL_VOTING_PERIOD = 7200;
  uint256 INITIAL_PROPOSAL_THRESHOLD = 100_000e18;

  function setUp() public {
    timelock = new TimelockController(
      100,
       new address[](0),
       new address[](0),
      address(this)
    );

    token = new GuineaPigToken(address(timelock), address(0xcafe), 100e18);

    governor = new GuineaPigGovernor(
      token,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      timelock
    );
  }
}

contract Constructor is GuineaPigGovernorTest {
  function test_ConstructorArgumentsSetCorrectly() public {
    assertEq(governor.votingDelay(), INITIAL_VOTING_DELAY);
    assertEq(governor.votingPeriod(), INITIAL_VOTING_PERIOD);
    assertEq(governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
    assertEq(governor.timelock(), address(timelock));
    assertEq(address(governor.token()), address(token));
  }
}
