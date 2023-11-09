// SPDX-License-Identifier: MIT
// slither-disable-start reentrancy-benign
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";
import {GuineaPigToken} from "src/GuineaPigToken.sol";
import {GuineaPigGovernor} from "src/GuineaPigGovernor.sol";

// TODO: rename to something more specific, launch deploy, initial deploy
contract Deploy is Script {
  // TODO: move to constants file
  uint256 INITIAL_VOTING_DELAY;
  uint256 INITIAL_VOTING_PERIOD;
  uint256 INITIAL_PROPOSAL_THRESHOLD;
  uint256 TIMELOCK_MIN_DELAY = 300;

  function run() public {
    // Governor needs the Timelock & the Token in constructor
    // Token needs the Timelock to be set as role(s) afterwards
    // Timelock can take Governor in constructor or set as role(s) afterwards

    // Plan:
    // x Modify Token to take god role as constructor argument instead of deployer
    // Modify token to take an in initial mint-to address & amount
    // Deploy the Timelock first w/ deployer having admin role
    // Deploy the Token w/ Timelock address in constructor
    // Deploy the Governor w/ Timelock & Token addresses in constructor
    // Send transaction(s) to give Governor the role(s) on the Timelock
    address[] memory _proposers = new address[](1);
    _proposers[0] = address(0x0); // TODO: change to deployer address

    address[] memory _executors = new address[](1);
    _executors[0] = address(0x0); // setting this to address 0 makes it open so anyone can execute
    address _admin;

    vm.broadcast();
    TimelockController _timelock = new TimelockController(TIMELOCK_MIN_DELAY, _proposers, _executors, _admin);

    vm.broadcast();
    GuineaPigToken _token = new GuineaPigToken(address(_timelock));

    vm.broadcast();
    GuineaPigGovernor _governor = new GuineaPigGovernor(_token, INITIAL_VOTING_DELAY, INITIAL_VOTING_PERIOD, INITIAL_PROPOSAL_THRESHOLD, _timelock);
  }
}
