// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionVestingFactory } from "../../src/interfaces/factories/ILegionVestingFactory.sol";

import { LegionLinearVesting } from "../../src/vesting/LegionLinearVesting.sol";
import { LegionLinearEpochVesting } from "../../src/vesting/LegionLinearEpochVesting.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Vesting Factory Test
 * @author Legion
 * @notice Test suite for the LegionVestingFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionVestingFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Instance of the LegionVestingFactory contract under test
     * @dev Deployed in setUp to create vesting contracts
     */
    LegionVestingFactory public legionVestingFactory;

    /**
     * @notice Address of the deployed LegionLinearVesting instance
     * @dev Stores the result of createLinearVesting calls
     */
    address public legionLinearVestingInstance;

    /**
     * @notice Address of the deployed LegionLinearEpochVesting instance
     * @dev Stores the result of createLinearEpochVesting calls
     */
    address public legionLinearEpochVestingInstance;

    /**
     * @notice Address representing the owner of the vesting contract
     * @dev Set to 0x04, receives vested tokens
     */
    address public vestingOwner = address(0x04);

    /**
     * @notice Address representing the vesting controller
     * @dev Set to 0x05, manages vesting operations
     */
    address public vestingController = address(0x05);

    /// @notice Mock ERC20 token used for vesting tests
    MockERC20 public askToken;

    /**
     * @notice Sets up the test environment by deploying the LegionVestingFactory
     * @dev Initializes the factory contract with no initial owner restrictions
     */
    function setUp() public {
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockERC20("LFG Coin", "LFG", 18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a LegionLinearVesting instance with default parameters
     * @dev Deploys a vesting contract with vestingOwner, current timestamp start, 52-week duration, and 1-hour cliff
     * @return The address of the created vesting instance
     */
    function prepareCreateLegionLinearVesting() public returns (address) {
        legionLinearVestingInstance = legionVestingFactory.createLinearVesting(
            vestingOwner, vestingController, uint64(block.timestamp), uint64(52 weeks), uint64(1 hours)
        );
        return legionLinearVestingInstance;
    }

    /**
     * @notice Creates a LegionLinearEpochVesting instance with default parameters
     * @dev Deploys a vesting contract with vestingOwner, current timestamp start, 52-week duration, and 1-hour cliff
     * @return The address of the created vesting instance
     */
    function prepareCreateLegionLinearEpochVesting() public returns (address) {
        legionLinearEpochVestingInstance = legionVestingFactory.createLinearEpochVesting(
            vestingOwner,
            vestingController,
            address(askToken),
            uint64(block.timestamp),
            uint64(52 weeks),
            uint64(1 hours),
            1 weeks,
            52
        );
        return legionLinearEpochVestingInstance;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION AND CREATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful creation of a LegionLinearVesting instance with valid parameters
     * @dev Verifies that the factory deploys a vesting contract with correct owner, start time, duration, and cliff
     * settings
     */
    function test_createLinearVesting_successfullyCreatesLinearVestingInstance() public {
        // Arrange
        uint64 startTime = uint64(block.timestamp);

        // Act
        prepareCreateLegionLinearVesting();

        // Expect
        assertNotEq(legionLinearVestingInstance, address(0), "Vesting instance address should not be zero");

        LegionLinearVesting vestingContract = LegionLinearVesting(payable(legionLinearVestingInstance));

        assertEq(vestingContract.owner(), vestingOwner, "Vesting owner should match vestingOwner address");
        assertEq(vestingContract.start(), startTime, "Start time should match block.timestamp");
        assertEq(vestingContract.duration(), 52 weeks, "Duration should be 52 weeks");
        assertEq(vestingContract.cliffEndTimestamp(), startTime + 1 hours, "Cliff end should be start time plus 1 hour");
    }

    /**
     * @notice Tests successful creation of a LegionLinearEpochVesting instance with valid parameters
     * @dev Verifies that the factory deploys a vesting contract with correct owner, start time, duration, cliff, epoch
     * duration and epoch count settings
     */
    function test_createLinearVesting_successfullyCreatesLinearEpochVestingInstance() public {
        // Arrange
        uint64 startTime = uint64(block.timestamp);

        // Act
        prepareCreateLegionLinearEpochVesting();

        // Expect
        assertNotEq(legionLinearEpochVestingInstance, address(0), "Vesting instance address should not be zero");

        LegionLinearEpochVesting vestingContract = LegionLinearEpochVesting(payable(legionLinearEpochVestingInstance));

        assertEq(vestingContract.owner(), vestingOwner, "Vesting owner should match vestingOwner address");
        assertEq(vestingContract.start(), startTime, "Start time should match block.timestamp");
        assertEq(vestingContract.duration(), 52 weeks, "Duration should be 52 weeks");
        assertEq(vestingContract.cliffEndTimestamp(), startTime + 1 hours, "Cliff end should be start time plus 1 hour");
        assertEq(vestingContract.epochDurationSeconds(), 1 weeks, "Epoch duration should be 1 week");
        assertEq(vestingContract.numberOfEpochs(), 52, "Epoch count should be 52");
    }
}
