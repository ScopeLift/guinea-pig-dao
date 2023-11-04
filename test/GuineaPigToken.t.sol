// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {GuineaPigToken} from "src/GuineaPigToken.sol";

contract GuineaPigTokenTest is Test {
  address deployer = address(0xde470);
  GuineaPigToken gpdToken;

  // For convenience, we pull these off the token after deployment
  bytes32 DEFAULT_ADMIN_ROLE;
  bytes32 MINTER_ROLE;
  bytes32 BURNER_ROLE;
  bytes32 MINTER_ADMIN_ROLE;
  bytes32 BURNER_ADMIN_ROLE;

  function setUp() public {
    vm.label(deployer, "Deployer");

    vm.prank(deployer);
    gpdToken = new GuineaPigToken();

    vm.label(address(gpdToken), "GPDT");

    DEFAULT_ADMIN_ROLE = gpdToken.DEFAULT_ADMIN_ROLE();
    MINTER_ROLE = gpdToken.MINTER_ROLE();
    BURNER_ROLE = gpdToken.BURNER_ROLE();
    MINTER_ADMIN_ROLE = gpdToken.MINTER_ADMIN_ROLE();
    BURNER_ADMIN_ROLE = gpdToken.BURNER_ADMIN_ROLE();
  }

  function _assumeSafeReceiver(address _receiver) public pure {
    vm.assume(_receiver != address(0));
  }

  function _grantRole(bytes32 _role, address _to) public {
    vm.prank(deployer);
    gpdToken.grantRole(_role, _to);
    assertTrue(gpdToken.hasRole(_role, _to), "Failure to grant role");
  }

  function _revokeRole(bytes32 _role, address _from) public {
    vm.prank(deployer);
    gpdToken.revokeRole(_role, _from);
    assertFalse(gpdToken.hasRole(_role, _from), "Failure to revoke role");
  }
}

contract Constructor is GuineaPigTokenTest {
  function test_ConstructedCorrectly() public {
    assertEq(gpdToken.name(), "Guinea Pig DAO Token");
    assertEq(gpdToken.symbol(), "GPDT");
    assertEq(gpdToken.getRoleMember(gpdToken.DEFAULT_ADMIN_ROLE(), 0), deployer);
  }

  function testFuzz_DeployerCanGrantDefaultAdminRole(address _admin) public {
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    assertEq(gpdToken.getRoleMember(DEFAULT_ADMIN_ROLE, 1), _admin);
  }
}

contract Mint is GuineaPigTokenTest {
  function testFuzz_DeployerCanGrantMinterRole(address _minter) public {
    _grantRole(MINTER_ROLE, _minter);
    assertEq(gpdToken.getRoleMember(MINTER_ROLE, 0), _minter);
  }

  function testFuzz_DeployerCanGrantMinterAdminRole(address _minterAdmin) public {
    vm.assume(_minterAdmin != deployer);
    _grantRole(MINTER_ADMIN_ROLE, _minterAdmin);
    assertEq(gpdToken.getRoleMember(MINTER_ADMIN_ROLE, 1), _minterAdmin);
  }

  function testFuzz_NewMinterCanMintTokens(address _minter, address _receiver, uint256 _amount)
    public
  {
    _assumeSafeReceiver(_receiver);
    _amount = bound(_amount, 0, type(uint224).max); // To avoid max supply check in ERC20Votes
    _grantRole(MINTER_ROLE, _minter);

    vm.prank(_minter);
    gpdToken.mint(_receiver, _amount);

    assertEq(gpdToken.balanceOf(_receiver), _amount);
  }

  function testFuzz_TwoMintersCanMintTokens(
    address _minter1,
    address _minter2,
    address _receiver1,
    address _receiver2,
    uint256 _amount1,
    uint256 _amount2
  ) public {
    _assumeSafeReceiver(_receiver1);
    _assumeSafeReceiver(_receiver2);
    vm.assume(_receiver1 != _receiver2);
    _amount1 = bound(_amount1, 0, type(uint224).max / 2 - 1);
    _amount2 = bound(_amount2, 0, type(uint224).max / 2 - 1);

    _grantRole(MINTER_ROLE, _minter1);
    _grantRole(MINTER_ROLE, _minter2);

    vm.prank(_minter1);
    gpdToken.mint(_receiver1, _amount1);

    vm.prank(_minter2);
    gpdToken.mint(_receiver2, _amount2);

    assertEq(gpdToken.balanceOf(_receiver1), _amount1);
    assertEq(gpdToken.balanceOf(_receiver2), _amount2);
  }

  function testFuzz_MinterAdminCanRevokeFromAMinter(
    address _minter1,
    address _minter2,
    address _receiver,
    uint256 _amount
  ) public {
    _assumeSafeReceiver(_receiver);
    vm.assume(_minter1 != _minter2);
    _amount = bound(_amount, 0, type(uint224).max);
    _grantRole(MINTER_ROLE, _minter1);
    _grantRole(MINTER_ROLE, _minter2);

    // Minters can mint tokens
    vm.prank(_minter2);
    gpdToken.mint(_receiver, _amount);
    assertEq(gpdToken.balanceOf(_receiver), _amount);

    _revokeRole(MINTER_ROLE, _minter1);
    // After revocation, only the second minter should have the role
    assertEq(gpdToken.getRoleMember(MINTER_ROLE, 0), _minter2);

    // The revoked minter should not be able to mint
    vm.prank(_minter1);
    vm.expectRevert();
    gpdToken.mint(_receiver, _amount);
  }

  function testFuzz_DefaultAdminCanAddANewMinterAdmin(
    address _minterAdmin,
    address _minter,
    address _receiver,
    uint256 _amount
  ) public {
    _assumeSafeReceiver(_receiver);
    _amount = bound(_amount, 0, type(uint224).max);
    _grantRole(MINTER_ADMIN_ROLE, _minterAdmin);

    vm.prank(_minterAdmin);
    gpdToken.grantRole(MINTER_ROLE, _minter);

    assertEq(gpdToken.getRoleMember(MINTER_ROLE, 0), _minter);
    assertTrue(gpdToken.hasRole(MINTER_ROLE, _minter));

    vm.prank(_minter);
    gpdToken.mint(_receiver, _amount);

    assertEq(gpdToken.balanceOf(_receiver), _amount);
  }
}

contract Burn is GuineaPigTokenTest {
  function _makeDeployerMinter() public {
    vm.prank(deployer);
    gpdToken.grantRole(MINTER_ROLE, deployer);
  }

  function _mint(address _to, uint256 _amount) public {
    _assumeSafeReceiver(_to);
    uint256 _initialBalance = gpdToken.balanceOf(_to);

    if (!gpdToken.hasRole(MINTER_ROLE, deployer)) _makeDeployerMinter();

    vm.prank(deployer);
    gpdToken.mint(_to, _amount);

    assertEq(gpdToken.balanceOf(_to) - _amount, _initialBalance, "Mint failed in Burn tests");
  }

  function testFuzz_DeployerCanGrantBurnerRole(address _burner) public {
    _grantRole(BURNER_ROLE, _burner);
    assertEq(gpdToken.getRoleMember(BURNER_ROLE, 0), _burner);
  }

  function testFuzz_DeployerCanGrantBurnerAdminRole(address _burnerAdmin) public {
    vm.assume(_burnerAdmin != deployer);
    _grantRole(BURNER_ADMIN_ROLE, _burnerAdmin);
    assertEq(gpdToken.getRoleMember(BURNER_ADMIN_ROLE, 1), _burnerAdmin);
  }

  function testFuzz_NewBurnerCanBurnTokens(
    address _burner,
    address _receiver,
    uint256 _mintAmount,
    uint256 _burnAmount
  ) public {
    _mintAmount = bound(_mintAmount, 0, type(uint224).max);
    _burnAmount = bound(_burnAmount, 0, _mintAmount);
    _mint(_receiver, _mintAmount);
    _grantRole(BURNER_ROLE, _burner);

    vm.prank(_burner);
    gpdToken.burn(_receiver, _burnAmount);

    assertEq(gpdToken.balanceOf(_receiver), _mintAmount - _burnAmount);
  }

  function testFuzz_TwoBurnersCanBurnTokens(
    address _burner1,
    address _burner2,
    address _receiver,
    uint256 _mintAmount,
    uint256 _burnAmount1,
    uint256 _burnAmount2
  ) public {
    _mintAmount = bound(_mintAmount, 0, type(uint224).max);
    _burnAmount1 = bound(_burnAmount1, 0, _mintAmount);
    _burnAmount2 = bound(_burnAmount2, 0, _mintAmount - _burnAmount1);
    _mint(_receiver, _mintAmount);

    _grantRole(BURNER_ROLE, _burner1);
    _grantRole(BURNER_ROLE, _burner2);

    vm.prank(_burner1);
    gpdToken.burn(_receiver, _burnAmount1);
    assertEq(gpdToken.balanceOf(_receiver), _mintAmount - _burnAmount1);

    vm.prank(_burner2);
    gpdToken.burn(_receiver, _burnAmount2);
    assertEq(gpdToken.balanceOf(_receiver), _mintAmount - _burnAmount1 - _burnAmount2);
  }

  function testFuzz_BurnerAdminCanRevokeFromABurner(
    address _burner1,
    address _burner2,
    address _receiver,
    uint256 _mintAmount,
    uint256 _burnAmount1,
    uint256 _burnAmount2
  ) public {
    vm.assume(_burner1 != _burner2);
    _mintAmount = bound(_mintAmount, 0, type(uint224).max);
    _burnAmount1 = bound(_burnAmount1, 0, _mintAmount);
    _burnAmount2 = bound(_burnAmount2, 0, _mintAmount - _burnAmount1);
    _mint(_receiver, _mintAmount);

    _grantRole(BURNER_ROLE, _burner1);
    _grantRole(BURNER_ROLE, _burner2);

    vm.prank(_burner1);
    gpdToken.burn(_receiver, _burnAmount1);
    assertEq(gpdToken.balanceOf(_receiver), _mintAmount - _burnAmount1);

    _revokeRole(BURNER_ROLE, _burner2);

    vm.prank(_burner2);
    vm.expectRevert();
    gpdToken.burn(_receiver, _burnAmount2);
  }

  function testFuzz_DefaultAdminCanAddNewBurnerAdmin(
    address _burnerAdmin,
    address _burner,
    address _receiver,
    uint256 _mintAmount,
    uint256 _burnAmount
  ) public {
    _mintAmount = bound(_mintAmount, 0, type(uint224).max);
    _burnAmount = bound(_burnAmount, 0, _mintAmount);
    _mint(_receiver, _mintAmount);
    _grantRole(BURNER_ADMIN_ROLE, _burnerAdmin);

    vm.prank(_burnerAdmin);
    gpdToken.grantRole(BURNER_ROLE, _burner);

    assertEq(gpdToken.getRoleMember(BURNER_ROLE, 0), _burner);
    assertTrue(gpdToken.hasRole(BURNER_ROLE, _burner));

    vm.prank(_burner);
    gpdToken.burn(_receiver, _burnAmount);

    assertEq(gpdToken.balanceOf(_receiver), _mintAmount - _burnAmount);
  }
}
