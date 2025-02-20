// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ILegionBouncer } from "../src/interfaces/ILegionBouncer.sol";
import { ILegionAddressRegistry } from "../src/interfaces/ILegionAddressRegistry.sol";
import { LegionBouncer } from "../src/LegionBouncer.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";

/**
 * @title Legion Bouncer Test
 * @notice Test suite for the Legion Bouncer contract
 */
contract LegionBouncerTest is Test {
    LegionAddressRegistry public addressRegistry;
    LegionBouncer public legionAdmin;

    address legionEOA = address(0x01);
    address awsBroadcaster = address(0x10);
    address nonAwsBroadcaster = address(0x02);

    bytes32 legionAdminId = bytes32("LEGION_ADMIN");

    function setUp() public {
        legionAdmin = new LegionBouncer(legionEOA, awsBroadcaster);
        addressRegistry = new LegionAddressRegistry(address(legionAdmin));
    }

    /**
     * @notice Test Case: Successfully execute function call with BROADCASTER_ROLE
     * @dev Test Case: Successfully executes function call with `BROADCASTER_ROLE`
     */
    function test_functionCall_successfullyExecuteOnlyBroadcasterRole() public {
        // Arrange
        bytes memory data =
            abi.encodeWithSignature("setLegionAddress(bytes32,address)", legionAdminId, address(legionAdmin));

        // Assert
        vm.expectEmit();
        emit ILegionAddressRegistry.LegionAddressSet(legionAdminId, address(0), address(legionAdmin));

        // Act
        vm.prank(awsBroadcaster);
        legionAdmin.functionCall(address(addressRegistry), data);
    }

    /**
     * @dev Test Case: Attempt to execute function call without BROADCASTER_ROLE
     * @notice Tests that addresses without BROADCASTER_ROLE cannot execute function calls
     */
    function test_functionCall_revertsIfCalledByNonBroadcasterRole() public {
        // Arrange
        bytes memory data =
            abi.encodeWithSignature("setLegionAddress(bytes32,address)", legionAdminId, address(legionAdmin));

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonAwsBroadcaster);
        legionAdmin.functionCall(address(addressRegistry), data);
    }
}
