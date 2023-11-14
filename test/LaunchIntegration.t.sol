// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {
  DeployLaunch,
  DeployLaunchConstants,
  TimelockController,
  GuineaPigToken,
  GuineaPigGovernor
} from "script/DeployLaunch.s.sol";

contract GuineaPigDaoLaunchIntegrationTest is DeployLaunchConstants, Test {
  TimelockController timelock;
  GuineaPigToken token;
  GuineaPigGovernor governor;

  function setUp() public {
    DeployLaunch _deploy = new DeployLaunch();
    _deploy.setUp();
    (timelock, token, governor) = _deploy.run();

    vm.label(address(timelock), "Timelock");
    vm.label(address(token), "Token");
    vm.label(address(governor), "Governor");
  }
}

contract DeployConfiguration is GuineaPigDaoLaunchIntegrationTest {
  function test_ConfigurationIsCorrectAfterDeployment() public {
    assertEq(address(governor.timelock()), address(timelock));
    assertEq(address(governor.token()), address(token));
    assertEq(governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
    assertEq(governor.votingPeriod(), INITIAL_VOTING_PERIOD);
    assertEq(governor.votingDelay(), INITIAL_VOTING_DELAY);
    assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), address(timelock)));
    assertEq(token.balanceOf(INITIAL_MINT_RECEIVER), INITIAL_MINT_AMOUNT);
    assertEq(token.totalSupply(), INITIAL_MINT_AMOUNT);
    assertTrue(timelock.hasRole(timelock.PROPOSER_ROLE(), address(governor)));
    assertTrue(timelock.hasRole(timelock.CANCELLER_ROLE(), address(governor)));
    assertTrue(timelock.hasRole(timelock.TIMELOCK_ADMIN_ROLE(), address(timelock)));
    assertEq(timelock.getMinDelay(), TIMELOCK_MIN_DELAY);
  }
}
