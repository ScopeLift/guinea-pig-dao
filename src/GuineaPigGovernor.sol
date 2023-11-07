// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {
  Governor, GovernorCountingFractional
} from "flexible-voting/GovernorCountingFractional.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {GovernorVotes} from "@openzeppelin/governance/extensions/GovernorVotes.sol";
import {GovernorTimelockControl} from
  "@openzeppelin/governance/extensions/GovernorTimelockControl.sol";
import {GovernorSettings} from "@openzeppelin/governance/extensions/GovernorSettings.sol";
import {IVotes} from "@openzeppelin/governance/utils/IVotes.sol";
// TODO: convert to interface?
import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

contract GuineaPigGovernor is
  GovernorCountingFractional,
  GovernorVotes,
  GovernorTimelockControl,
  GovernorSettings
{
  /// @notice Human readable name of this Governor.
  string private constant GOVERNOR_NAME = "Guinea Pig DAO Governor v1";

  constructor(
    IVotes _token,
    uint256 _initialVotingDelay,
    uint256 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    TimelockController _timelock
  )
    GovernorVotes(_token)
    GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold)
    GovernorTimelockControl(_timelock)
    Governor(GOVERNOR_NAME)
  {}

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return GovernorTimelockControl.supportsInterface(interfaceId);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function castVoteWithReasonAndParamsBySig(
    uint256 proposalId,
    uint8 support,
    string calldata reason,
    bytes memory params,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override(Governor, GovernorCountingFractional, IGovernor) returns (uint256) {
    return GovernorCountingFractional.castVoteWithReasonAndParamsBySig(
      proposalId, support, reason, params, v, r, s
    );
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function proposalThreshold()
    public
    view
    virtual
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return GovernorSettings.proposalThreshold();
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function state(uint256 proposalId)
    public
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return GovernorTimelockControl.state(proposalId);
  }

  function quorum(uint256) public pure override returns (uint256) {
    return 1; // TODO: determine quorum rules
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal virtual override(Governor, GovernorTimelockControl) {
    return GovernorTimelockControl._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _executor()
    internal
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return GovernorTimelockControl._executor();
  }

  /// @dev We override this function to resolve ambiguity between inherited contracts.
  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal virtual override(Governor, GovernorTimelockControl) returns (uint256) {
    return GovernorTimelockControl._cancel(targets, values, calldatas, descriptionHash);
  }
}
