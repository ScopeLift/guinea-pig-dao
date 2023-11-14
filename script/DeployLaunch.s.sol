// SPDX-License-Identifier: MIT
// slither-disable-start reentrancy-benign
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";
import {GuineaPigToken} from "src/GuineaPigToken.sol";
import {GuineaPigGovernor} from "src/GuineaPigGovernor.sol";
import {DeployLaunchConstants} from "script/DeployLaunchConstants.sol";

// TODO: rename to something more specific, launch deploy, initial deploy
contract DeployLaunch is DeployLaunchConstants, Script {
  address deployer;

  function setUp() public {
    deployer = vm.rememberKey(vm.envUint("DEPLOYER_PRIVATE_KEY"));
  }

  function run()
    public
    returns (TimelockController _timelock, GuineaPigToken _token, GuineaPigGovernor _governor)
  {
    // no proposers to start, we will add the Governor later
    address[] memory _proposers = new address[](0);

    address[] memory _executors = new address[](1);
    // assigning address 0 makes it open so anyone can execute
    _executors[0] = address(0x0);

    vm.startBroadcast(deployer);
    _timelock = new TimelockController(
      TIMELOCK_MIN_DELAY,
      _proposers,
      _executors,
      deployer
    );

    _token = new GuineaPigToken(address(_timelock), INITIAL_MINT_RECEIVER, INITIAL_MINT_AMOUNT);

    _governor = new GuineaPigGovernor(
      _token,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      _timelock
    );

    // Give the Governor the roles it needs to execute & cancel proposals
    _timelock.grantRole(_timelock.PROPOSER_ROLE(), address(_governor));
    _timelock.grantRole(_timelock.CANCELLER_ROLE(), address(_governor));

    // Renounce the admin role, meaning only the timelock now administers itself
    _timelock.renounceRole(_timelock.TIMELOCK_ADMIN_ROLE(), deployer);

    vm.stopBroadcast();
  }
}
