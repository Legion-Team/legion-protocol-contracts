// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ILegionAddressRegistry } from "../../src/interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionBouncer } from "../../src/interfaces/access/ILegionBouncer.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";

/**
 * @title Legion Bouncer Test
 * @author Legion
 * @notice Test suite for the Legion Bouncer contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionBouncerTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Instance of the LegionAddressRegistry contract for testing interactions
    LegionAddressRegistry public addressRegistry;

    /// @notice Instance of the LegionBouncer contract under test
    LegionBouncer public legionAdmin;

    /// @notice Address representing the Legion EOA (External Owned Account)
    address legionEOA = address(0x01);

    /// @notice Address representing the AWS broadcaster with BROADCASTER_ROLE
    address awsBroadcaster = address(0x10);

    /// @notice Bytes32 identifier for the Legion admin address in the registry
    bytes32 legionAdminId = bytes32("LEGION_ADMIN");

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying LegionBouncer and LegionAddressRegistry
     * @dev Initializes LegionBouncer with legionEOA and awsBroadcaster, and sets up the registry
     */
    function setUp() public {
        legionAdmin = new LegionBouncer(legionEOA, awsBroadcaster);
        addressRegistry = new LegionAddressRegistry(address(legionAdmin));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that functionCall executes successfully with BROADCASTER_ROLE
     * @dev Verifies that an address with BROADCASTER_ROLE can call setLegionAddress via functionCall
     */
    function test_functionCall_successfullyExecuteOnlyBroadcasterRole() public {
        // Arrange
        bytes memory data =
            abi.encodeWithSignature("setLegionAddress(bytes32,address)", legionAdminId, address(legionAdmin));

        // Expect
        vm.expectEmit();
        emit ILegionAddressRegistry.LegionAddressSet(legionAdminId, address(0), address(legionAdmin));

        // Act
        vm.prank(awsBroadcaster);
        legionAdmin.functionCall(address(addressRegistry), data);
    }

    /**
     * @notice Tests that functionCall reverts when called without BROADCASTER_ROLE
     * @dev Expects an Unauthorized revert when a non-broadcaster attempts to call setLegionAddress
     */
    function testFuzz_functionCall_revertsIfCalledByNonBroadcasterRole(address nonAwsBroadcaster) public {
        // Arrange
        vm.assume(nonAwsBroadcaster != awsBroadcaster);

        bytes memory data =
            abi.encodeWithSignature("setLegionAddress(bytes32,address)", legionAdminId, address(legionAdmin));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonAwsBroadcaster);
        legionAdmin.functionCall(address(addressRegistry), data);
    }
}
