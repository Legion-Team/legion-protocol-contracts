// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ILegionAddressRegistry } from "../../src/interfaces/registries/ILegionAddressRegistry.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";

/**
 * @title Legion Address Registry Test
 * @author Legion
 * @notice Test suite for the Legion Address Registry contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionAddressRegistryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Instance of the LegionAddressRegistry contract under test
    LegionAddressRegistry public addressRegistry;

    /// @notice Address representing the Legion admin (owner)
    address legionAdmin = address(0x01);

    /// @notice Address to be set in the registry for testing
    address registry = address(0x03);

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying a new LegionAddressRegistry
     * @dev Initializes the contract with legionAdmin as the owner before each test
     */
    function setUp() public {
        addressRegistry = new LegionAddressRegistry(legionAdmin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that the ownership is correctly set during initialization
     * @dev Verifies that the owner of the contract matches the legionAdmin address
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Expect
        assertEq(addressRegistry.owner(), legionAdmin);
    }

    /**
     * @notice Tests that setLegionAddress updates the address when called by the owner
     * @dev Expects an event emission and checks the update logic using vm.prank
     */
    function test_setLegionAddress_successfullyUpdatesAddressIfCalledByOwner() public {
        // Expect
        vm.expectEmit();
        emit ILegionAddressRegistry.LegionAddressSet(bytes32("LEGION_REGISTRY"), address(0), registry);

        // Act
        vm.prank(legionAdmin);
        addressRegistry.setLegionAddress(bytes32("LEGION_REGISTRY"), registry);
    }

    /**
     * @notice Tests that setLegionAddress reverts when called by a non-owner
     * @dev Expects an Unauthorized revert from the Ownable contract
     */
    function testFuzz_setLegionAddress_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionAdmin);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        addressRegistry.setLegionAddress(bytes32("LEGION_REGISTRY"), registry);
    }

    /**
     * @notice Tests that getLegionAddress returns a previously set address
     * @dev Sets an address and verifies it can be retrieved correctly
     */
    function test_getLegionAddress_successfullyReturnsLegionAddress() public {
        // Arrange
        vm.prank(legionAdmin);
        addressRegistry.setLegionAddress(bytes32("LEGION_ADMIN"), legionAdmin);

        // Act
        address _legionAdmin = addressRegistry.getLegionAddress(bytes32("LEGION_ADMIN"));

        // Expect
        assertEq(_legionAdmin, legionAdmin);
    }

    /**
     * @notice Tests that getLegionAddress returns zero address for an unset key
     * @dev Verifies default behavior when no address has been set for a key
     */
    function test_getLegionAddress_successfullyReturnsZeroAddressIfNotSet() public view {
        // Arrange
        address _legionAdmin = addressRegistry.getLegionAddress(bytes32("LEGION_ADMIN"));

        // Expect
        assertEq(_legionAdmin, address(0));
    }
}
