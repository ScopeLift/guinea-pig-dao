// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {GuineaPigToken} from "src/GuineaPigToken.sol";

contract GuineaPigTokenTest is Test {
  GuineaPigToken gpdToken;

  function setUp() public {
    gpdToken = new GuineaPigToken();
  }
}

contract Constructor is GuineaPigTokenTest {
  function test_ConstructedCorrectly() public {
    assertEq(gpdToken.name(), "Guinea Pig DAO Token");
    assertEq(gpdToken.symbol(), "GPDT");
  }
}
