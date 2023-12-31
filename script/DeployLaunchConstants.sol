// SPDX-License-Identifier: MIT
// slither-disable-start reentrancy-benign
pragma solidity 0.8.23;

contract DeployLaunchConstants {
  uint256 INITIAL_VOTING_DELAY = 25; // 5 minutes given 12 second blocks
  uint256 INITIAL_VOTING_PERIOD = 7200; // 1 day given 12 second blocks
  uint256 INITIAL_PROPOSAL_THRESHOLD = 24_000e18; // 2% of total supply
  uint256 TIMELOCK_MIN_DELAY = 300; // 300 sec == 5 minutes
  address INITIAL_MINT_RECEIVER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // default anvil
  uint256 INITIAL_MINT_AMOUNT = 1_200_000e18;
}
