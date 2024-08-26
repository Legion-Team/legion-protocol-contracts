// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {ILegionAccessControl} from "../src/interfaces/ILegionAccessControl.sol";
import {ILegionAddressRegistry} from "../src/interfaces/ILegionAddressRegistry.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";
import {LegionAddressRegistry} from "../src/LegionAddressRegistry.sol";

contract LegionAccessControlTest is Test {
    LegionAddressRegistry public addressRegistry;
    LegionAccessControl public legionAdmin;

    address legionEOA = address(0x01);
    address awsBroadcaster = address(0x10);
    address nonAwsBroadcaster = address(0x02);

    bytes32 legionAdminId = bytes32("LEGION_ADMIN");

    function setUp() public {
        legionAdmin = new LegionAccessControl(legionEOA, awsBroadcaster);
        addressRegistry = new LegionAddressRegistry(address(legionAdmin));
    }

    /**
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
     * @dev Test Case: Attempt to execute function call without `BROADCASTER_ROLE`
     */
    function test_functionCall_revertsIfCalledByNonBroadcasterRole() public {
        // Arrange
        bytes memory data =
            abi.encodeWithSignature("setLegionAddress(bytes32,address)", legionAdminId, address(legionAdmin));

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                nonAwsBroadcaster,
                keccak256("BROADCASTER_ROLE")
            )
        );

        // Act
        vm.prank(nonAwsBroadcaster);
        legionAdmin.functionCall(address(addressRegistry), data);
    }
}
