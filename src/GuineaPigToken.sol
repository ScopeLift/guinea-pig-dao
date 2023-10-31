// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {
  ERC20Votes,
  ERC20Permit,
  ERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract GuineaPigToken is ERC20Votes {
  constructor() ERC20("Guinea Pig DAO Token", "GPDT") ERC20Permit("Guinea Pig DAO Token") {}
}
