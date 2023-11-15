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
        uint256 _proposalId = governor.propose(
            _targets,
            _values,
            _calldatas,
            _description
        );

        vm.roll(block.number + INITIAL_VOTING_DELAY + 1);

        vm.prank(delegatee);
        governor.castVote(_proposalId, _support);

        vm.roll(block.number + INITIAL_VOTING_PERIOD + 1);
        governor.queue(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );

        vm.warp(block.timestamp + TIMELOCK_MIN_DELAY + 1);
        governor.execute(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );
    }
}

contract MintProposal is ProposalTest {
    function _passProposalToGrantTimelockMinterRole() public {
        address[] memory _targets = new address[](1);
        _targets[0] = address(token);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 0;

        bytes[] memory _calldatas = new bytes[](1);
        _calldatas[0] = _buildProposalData("grantRole(bytes32,address)", abi.encode(token.MINTER_ROLE(), address(timelock)));

        _queueVoteAndExecuteProposal(
            _targets,
            _values,
            _calldatas,
            "Grant timelock Minter role",
            SUPPORT_FOR
        );
    }

    function _passProposalToMintTokens(address _to, uint256 _amount) public returns (uint256) {
        require(token.hasRole(token.MINTER_ROLE(), address(timelock)), "Test process error: grant minter role before minting");
        _assumeSafeReceiver(_to);
        _amount = _boundSafeAmount(_amount);

        address[] memory _targets = new address[](1);
        _targets[0] = address(token);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 0;

        bytes[] memory _calldatas = new bytes[](1);
        _calldatas[0] = _buildProposalData("mint(address,uint256)", abi.encode(_to, _amount));

        _queueVoteAndExecuteProposal(
            _targets,
            _values,
            _calldatas,
            "Mint new tokens",
            SUPPORT_FOR
        );

        return _amount;
    }

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
        _calldatas[0] = _buildProposalData("grantRole(bytes32,address)", abi.encode(token.MINTER_ROLE(), address(timelock)));
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
