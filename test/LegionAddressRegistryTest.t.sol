// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ILegionAddressRegistry } from "../src/interfaces/ILegionAddressRegistry.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";

/**
 * @title Legion Address Registry Test
 * @notice Test suite for the Legion Address Registry contract
 */
contract LegionAddressRegistryTest is Test {
    LegionAddressRegistry public addressRegistry;

    address legionAdmin = address(0x01);
    address nonOwner = address(0x02);

    address registry = address(0x03);

    function setUp() public {
        addressRegistry = new LegionAddressRegistry(legionAdmin);
    }

    /**
     * @notice Test Case: Initialize registry and verify correct owner is set
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Assert
        assertEq(addressRegistry.owner(), legionAdmin);
    }

    /**
     * @notice Test Case: Successfully update address when called by owner
     */
    function test_setLegionAddress_successfullyUpdatesAddressIfCalledByOwner() public {
        // Assert
        vm.expectEmit();
        emit ILegionAddressRegistry.LegionAddressSet(bytes32("LEGION_REGISTRY"), address(0), registry);

        // Act
        vm.prank(legionAdmin);
        addressRegistry.setLegionAddress(bytes32("LEGION_REGISTRY"), registry);
    }

    /**
     * @dev Test Case: Attempt to update address when called by non-owner
     */
    function test_setLegionAddress_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        addressRegistry.setLegionAddress(bytes32("LEGION_REGISTRY"), registry);
    }

    /**
     * @notice Test Case: Successfully retrieve previously set Legion address
     */
    function test_getLegionAddress_successfullyReturnsLegionAddress() public {
        // Arrange
        vm.prank(legionAdmin);
        addressRegistry.setLegionAddress(bytes32("LEGION_ADMIN"), legionAdmin);

        // Act
        address _legionAdmin = addressRegistry.getLegionAddress(bytes32("LEGION_ADMIN"));

        // Assert
        assertEq(_legionAdmin, legionAdmin);
    }

    /**
     * @notice Test Case: Successfully return zero address for unset address key
     */
    function test_getLegionAddress_successfullyReturnsZeroAddressIfNotSet() public view {
        // Act
        address _legionAdmin = addressRegistry.getLegionAddress(bytes32("LEGION_ADMIN"));

        // Assert
        assertEq(_legionAdmin, address(0));
    }
}
