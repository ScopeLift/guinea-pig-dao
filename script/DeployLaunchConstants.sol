// SPDX-License-Identifier: MIT
// slither-disable-start reentrancy-benign
pragma solidity 0.8.23;

contract DeployLaunchConstants {
  uint256 INITIAL_VOTING_DELAY = 25; // 5 minutes given 12 second blocks
  uint256 INITIAL_VOTING_PERIOD = 7200; // 1 day given 12 second blocks
  uint256 INITIAL_PROPOSAL_THRESHOLD = 24_000e18; // 2% of total supply
  uint256 TIMELOCK_MIN_DELAY = 300; // 300 sec == 5 minutes
  address INITIAL_MINT_RECEIVER = 0x5C04E7808455ee0e22c2773328C151d0DD79dC62;
  uint256 INITIAL_MINT_AMOUNT = 1_200_000e18;
}
