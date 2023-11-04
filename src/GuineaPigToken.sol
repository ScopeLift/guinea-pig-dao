// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {
  ERC20Votes,
  ERC20Permit,
  ERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract GuineaPigToken is ERC20Votes, AccessControlEnumerable {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");
  bytes32 public constant BURNER_ADMIN_ROLE = keccak256("BURNER_ADMIN_ROLE");

  constructor() ERC20("Guinea Pig DAO Token", "GPDT") ERC20Permit("Guinea Pig DAO Token") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ADMIN_ROLE, msg.sender);
    _grantRole(BURNER_ADMIN_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
    _setRoleAdmin(BURNER_ROLE, BURNER_ADMIN_ROLE);
  }

  function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
    _burn(from, amount);
  }
}