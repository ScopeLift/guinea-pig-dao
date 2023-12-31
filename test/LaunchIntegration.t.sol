// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

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

  function setUp() public virtual {
    DeployLaunch _deploy = new DeployLaunch();
    _deploy.setUp();
    (timelock, token, governor) = _deploy.run();

    vm.label(address(timelock), "Timelock");
    vm.label(address(token), "Token");
    vm.label(address(governor), "Governor");
    vm.label(INITIAL_MINT_RECEIVER, "Initial Receiver");
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

contract ProposalTest is GuineaPigDaoLaunchIntegrationTest {
  address delegatee = address(0xbabb1e);

  uint8 SUPPORT_AGAINST = 0;
  uint8 SUPPORT_FOR = 1;
  uint8 SUPPORT_ABSTAIN = 2;

  uint256 MAX_MINT_AMOUNT = type(uint128).max;

  uint8 PROPOSAL_STATE_DEFEATED = 3;
  uint8 PROPOSAL_STATE_SUCCEEDED = 4;

  function setUp() public virtual override {
    super.setUp();
    vm.label(delegatee, "Delegate");

    // delegate to the delegate
    vm.prank(INITIAL_MINT_RECEIVER);
    token.delegate(delegatee);

    // advance one block so check pointing allows for proposals
    vm.roll(block.number + 1);
  }

  function _buildProposalData(string memory _signature, bytes memory _calldata)
    internal
    pure
    returns (bytes memory)
  {
    return abi.encodePacked(bytes4(keccak256(bytes(_signature))), _calldata);
  }

  function _boundSafeAmount(uint256 _amount) public view returns (uint256) {
    return bound(_amount, 0, MAX_MINT_AMOUNT);
  }

  function _assumeSafeReceiver(address _to) public view {
    vm.assume(_to != address(0) && _to != INITIAL_MINT_RECEIVER);
  }

  function _queueVoteAndExecuteProposal(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description,
    uint8 _support
  ) public {
    require(_support <= 2, "Invalid support value used in proposal test");

    vm.prank(delegatee);
    uint256 _proposalId = governor.propose(_targets, _values, _calldatas, _description);

    vm.roll(block.number + INITIAL_VOTING_DELAY + 1);

    vm.prank(delegatee);
    governor.castVote(_proposalId, _support);

    vm.roll(block.number + INITIAL_VOTING_PERIOD + 1);
    governor.queue(_targets, _values, _calldatas, keccak256(bytes(_description)));

    vm.warp(block.timestamp + TIMELOCK_MIN_DELAY + 1);
    governor.execute(_targets, _values, _calldatas, keccak256(bytes(_description)));
  }

  function _passProposalToGrantTimelockRole(bytes32 _role) public {
    address[] memory _targets = new address[](1);
    _targets[0] = address(token);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 0;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] =
      _buildProposalData("grantRole(bytes32,address)", abi.encode(_role, address(timelock)));

    _queueVoteAndExecuteProposal(
      _targets, _values, _calldatas, "Grant timelock Minter role", SUPPORT_FOR
    );
  }

  function _passProposalToGrantTimelockMinterRole() public {
    _passProposalToGrantTimelockRole(token.MINTER_ROLE());
  }

  function _passProposalToGrantTimelockBurnerRole() public {
    _passProposalToGrantTimelockRole(token.BURNER_ROLE());
  }

  function _passProposalToMintTokens(address _to, uint256 _amount) public returns (uint256) {
    require(
      token.hasRole(token.MINTER_ROLE(), address(timelock)),
      "Test process error: grant minter role before minting"
    );
    _assumeSafeReceiver(_to);
    _amount = _boundSafeAmount(_amount);

    address[] memory _targets = new address[](1);
    _targets[0] = address(token);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 0;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _buildProposalData("mint(address,uint256)", abi.encode(_to, _amount));

    _queueVoteAndExecuteProposal(_targets, _values, _calldatas, "Mint new tokens", SUPPORT_FOR);

    return _amount;
  }

  function _passProposalToBurnTokens(address _from, uint256 _amount) public {
    require(
      token.hasRole(token.BURNER_ROLE(), address(timelock)),
      "Test process error: grant minter role before minting"
    );
    require(token.balanceOf(_from) >= _amount, "Test error: asking to burn more than held");

    address[] memory _targets = new address[](1);
    _targets[0] = address(token);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 0;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _buildProposalData("burn(address,uint256)", abi.encode(_from, _amount));

    _queueVoteAndExecuteProposal(_targets, _values, _calldatas, "Burn tokens", SUPPORT_FOR);
  }
}

contract MintProposal is ProposalTest {
  function test_GrantMinterRoleToTimelockProposal() public {
    _passProposalToGrantTimelockMinterRole();
    assertTrue(token.hasRole(token.MINTER_ROLE(), address(timelock)));
  }

  function testFuzz_MintTokensProposal(address _to, uint256 _amount) public {
    _passProposalToGrantTimelockMinterRole();
    _amount = _passProposalToMintTokens(_to, _amount);

    assertEq(token.balanceOf(_to), _amount);
    assertEq(token.totalSupply(), INITIAL_MINT_AMOUNT + _amount);
  }

  function testFuzz_GrantMinterRoleAndMintTokensAtomicProposal(address _to, uint256 _amount) public {
    _assumeSafeReceiver(_to);
    _amount = _boundSafeAmount(_amount);

    address[] memory _targets = new address[](2);
    _targets[0] = address(token);
    _targets[1] = address(token);

    uint256[] memory _values = new uint256[](2);
    _values[0] = 0;
    _values[1] = 0;

    bytes[] memory _calldatas = new bytes[](2);
    _calldatas[0] = _buildProposalData(
      "grantRole(bytes32,address)", abi.encode(token.MINTER_ROLE(), address(timelock))
    );
    _calldatas[1] = _buildProposalData("mint(address,uint256)", abi.encode(_to, _amount));

    _queueVoteAndExecuteProposal(
      _targets,
      _values,
      _calldatas,
      "Grant timelock minter role and mint more tokens in one proposal",
      SUPPORT_FOR
    );

    assertEq(token.balanceOf(_to), _amount);
    assertEq(token.totalSupply(), INITIAL_MINT_AMOUNT + _amount);
  }
}

contract BurnProposal is ProposalTest {
  function test_GrantBurnerRoleToTimelockProposal() public {
    _passProposalToGrantTimelockBurnerRole();
    assertTrue(token.hasRole(token.BURNER_ROLE(), address(timelock)));
  }

  function testFuzz_BurnTokensProposal(address _holder, uint256 _sendAmount, uint256 _burnAmount)
    public
  {
    _assumeSafeReceiver(_holder);
    _sendAmount = bound(_sendAmount, 0, INITIAL_MINT_AMOUNT);
    _burnAmount = bound(_burnAmount, 0, _sendAmount);

    // send tokens to the holder
    vm.prank(INITIAL_MINT_RECEIVER);
    token.transfer(_holder, _sendAmount);
    assertEq(token.balanceOf(_holder), _sendAmount);

    // have the holder delegate to our delegatee to ensure passed proposal
    vm.prank(_holder);
    token.delegate(delegatee);

    // burn some of the holder's tokens via governance
    _passProposalToGrantTimelockBurnerRole();
    _passProposalToBurnTokens(_holder, _burnAmount);

    assertEq(token.balanceOf(_holder), _sendAmount - _burnAmount);
    assertEq(token.totalSupply(), INITIAL_MINT_AMOUNT - _burnAmount);
  }
}

contract FailedProposal is ProposalTest {
  function testFuzz_FailsAProposalThatDoesNotPass(address _againstVoter, uint256 _againstVoteAmount)
    public
  {
    _assumeSafeReceiver(_againstVoter);
    // ensure the amount that will vote against is greater than the amount that will vote for
    _againstVoteAmount =
      bound(_againstVoteAmount, (INITIAL_MINT_AMOUNT / 2) + 1, INITIAL_MINT_AMOUNT - 1);

    // send majority of tokens to new voter
    vm.prank(INITIAL_MINT_RECEIVER);
    token.transfer(_againstVoter, _againstVoteAmount);

    // the new voter delegates to themselves
    vm.prank(_againstVoter);
    token.delegate(_againstVoter);

    // advance blocks for check pointing
    vm.roll(block.number + 1);

    // the proposal would make the delegatee the token's admin
    address[] memory _targets = new address[](1);
    _targets[0] = address(token);
    uint256[] memory _values = new uint256[](1);
    _values[0] = 0;
    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _buildProposalData(
      "grantRole(bytes32,address)", abi.encode(token.DEFAULT_ADMIN_ROLE, address(delegatee))
    );
    string memory _description = "This proposal adds a new admin to the token";

    // submit the proposal
    vm.prank(_againstVoter);
    uint256 _proposalId = governor.propose(_targets, _values, _calldatas, _description);

    // advance past the voting delay
    vm.roll(block.number + INITIAL_VOTING_DELAY + 1);

    // both cast votes
    vm.prank(delegatee);
    governor.castVote(_proposalId, SUPPORT_FOR);
    vm.prank(_againstVoter);
    governor.castVote(_proposalId, SUPPORT_AGAINST);

    // jump past the voting period
    vm.roll(block.number + INITIAL_VOTING_PERIOD + 1);

    assertEq(uint8(governor.state(_proposalId)), PROPOSAL_STATE_DEFEATED);
    vm.expectRevert("Governor: proposal not successful");
    governor.queue(_targets, _values, _calldatas, keccak256(bytes(_description)));
  }
}

contract FlexibleVoting is ProposalTest {
  function testFuzz_AllowsForFlexibleVoting(
    uint256 _forVotes,
    uint256 _againstVotes,
    uint256 _abstainVotes
  ) public {
    _forVotes = bound(_forVotes, 0, INITIAL_MINT_AMOUNT);
    _againstVotes = bound(_againstVotes, 0, INITIAL_MINT_AMOUNT - _forVotes);
    _abstainVotes = bound(_abstainVotes, 0, INITIAL_MINT_AMOUNT - _forVotes - _againstVotes);

    // the proposal would make the delegatee the token's admin
    address[] memory _targets = new address[](1);
    _targets[0] = address(token);
    uint256[] memory _values = new uint256[](1);
    _values[0] = 0;
    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _buildProposalData(
      "grantRole(bytes32,address)", abi.encode(token.DEFAULT_ADMIN_ROLE, address(delegatee))
    );
    string memory _description = "This proposal adds a new admin to the token";

    // submit the proposal
    vm.prank(delegatee);
    uint256 _proposalId = governor.propose(_targets, _values, _calldatas, _description);

    // advance past the voting delay
    vm.roll(block.number + INITIAL_VOTING_DELAY + 1);

    // cast fractionalized vote
    bytes memory _fractionalizedVotes =
      abi.encodePacked(uint128(_againstVotes), uint128(_forVotes), uint128(_abstainVotes));

    vm.prank(delegatee);
    governor.castVoteWithReasonAndParams(
      _proposalId,
      0,
      "This is my vote, there are many like it, but this one is mine.",
      _fractionalizedVotes
    );

    (uint256 _actualAgainstVotes, uint256 _actualForVotes, uint256 _actualAbstainVotes) =
      governor.proposalVotes(_proposalId);

    assertEq(_forVotes, _actualForVotes);
    assertEq(_againstVotes, _actualAgainstVotes);
    assertEq(_abstainVotes, _actualAbstainVotes);

    // jump past the voting period
    vm.roll(block.number + INITIAL_VOTING_PERIOD + 1);

    // ensure result is as expected
    bool _isVoteSuccessful = (_forVotes > _againstVotes)
      && ((_forVotes + _abstainVotes) > governor.quorum(block.number - 1));
    uint8 _expectedState = _isVoteSuccessful ? PROPOSAL_STATE_SUCCEEDED : PROPOSAL_STATE_DEFEATED;
    assertEq(uint8(governor.state(_proposalId)), _expectedState);
  }
}
