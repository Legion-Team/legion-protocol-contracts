// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

import {ILegionVestingFactory} from "../src/interfaces/ILegionVestingFactory.sol";
import {LegionLinearVesting} from "../src/LegionLinearVesting.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";

contract LegionLinearVestingFactoryTest is Test {
    LegionVestingFactory public legionVestingFactory;

    address public legionVestingInstance;

    address legionAdmin = address(0x01);
    address allowedDeployer = address(0x02);
    address newAllowedDeployer = address(0x05);
    address nonOwner = address(0x03);
    address vestingOwner = address(0x04);

    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant CLIFF_DURATION_SECONDS = 3600;

    function setUp() public {
        legionVestingFactory = new LegionVestingFactory();
    }

    /**
     * @dev Helper method to create a Legion linear vesting schedule instance
     */
    function prepareCreateLegionLinearVesting() public {
        vm.prank(allowedDeployer);
        legionVestingInstance = legionVestingFactory.createLinearVesting(
            vestingOwner, uint64(block.timestamp), uint64(VESTING_DURATION_SECONDS), uint64(CLIFF_DURATION_SECONDS)
        );
    }

    /**
     * @dev Test Case: Successfully create a new LegionLinearVesting instance with valid parameters by an allowed deployer
     */
    function test_createLinearVesting_successfullyCreatesLinearVestingInstance() public {
        // Arrange & Act
        prepareCreateLegionLinearVesting();

        // Assert
        assertNotEq(legionVestingInstance, address(0));

        assertEq(LegionLinearVesting(payable(legionVestingInstance)).owner(), vestingOwner);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).start(), block.timestamp);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).duration(), VESTING_DURATION_SECONDS);
        assertEq(
            LegionLinearVesting(payable(legionVestingInstance)).cliffEnd(), block.timestamp + CLIFF_DURATION_SECONDS
        );
    }
}
