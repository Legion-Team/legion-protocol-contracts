// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionVestingFactory } from "../../src/interfaces/factories/ILegionVestingFactory.sol";

import { LegionLinearEpochVesting } from "../../src/vesting/LegionLinearEpochVesting.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Linear Epoch Vesting Test
 * @author Legion
 * @notice Test suite for the LegionLinearEpochVesting contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionLinearEpochVestingTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Template instance of the LegionLinearEpochVesting contract for cloning
    LegionLinearEpochVesting public linearVestingTemplate;

    /// @notice Factory contract for creating vesting instances
    LegionVestingFactory public legionVestingFactory;

    /// @notice Mock ERC20 token used for vesting tests
    MockERC20 public askToken;

    /// @notice Address of the deployed vesting contract instance
    address public legionVestingInstance;

    /// @notice Address representing the vesting contract owner, set to 0x04
    address vestingOwner = address(0x03);

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Initializes the vesting template, factory, and mock token for testing
     */
    function setUp() public {
        linearVestingTemplate = new LegionLinearEpochVesting();
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockERC20("LFG Coin", "LFG", 18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates and initializes a LegionLinearEpochVesting instance
     * @dev Sets up a vesting schedule with predefined parameters and funds it
     */
    function prepareCreateLegionLinearEpochVesting() public {
        legionVestingInstance = legionVestingFactory.createLinearEpochVesting(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(1 hours), 2_678_400, 12
        );
        vm.deal(legionVestingInstance, 1200 ether);
        askToken.mint(legionVestingInstance, 1200 * 1e18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful deployment and initialization with valid parameters
     * @dev Verifies ownership and vesting parameters post-initialization
     */
    function test_createLinearVesting_successfullyDeployWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionLinearEpochVesting();

        // Expect
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).owner(), vestingOwner);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).start(), block.timestamp);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).duration(), 2_678_400 * 12);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).cliffEndTimestamp(), 1 hours + 1);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).getCurrentEpoch(), 1);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).lastClaimedEpoch(), 0);
        assertEq(
            LegionLinearEpochVesting(payable(legionVestingInstance)).getCurrentEpochAtTimestamp(block.timestamp), 1
        );
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(1 hours), 2_678_400, 12
        );
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address linearVestingImplementation = legionVestingFactory.i_linearEpochVestingTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearEpochVesting(payable(linearVestingImplementation)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(1 hours), 2_678_400, 12
        );
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearEpochVesting(payable(linearVestingTemplate)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(1 hours), 2_678_400, 12
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        TOKEN RELEASE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that releasing tokens before cliff period ends reverts
     * @dev Expects LegionVesting__CliffNotEnded revert with current timestamp
     */
    function test_release_revertsIfCliffHasNotEnded() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionVesting__CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @notice Tests successful token release after cliff period ends
     * @dev Expects ERC20Released event after advancing to epoch 2
     */
    function test_release_successfullyReleaseTokensAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        vm.warp(block.timestamp + 2_678_400 + 1);

        // Expect
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 100 * 1e18);

        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @notice Tests successful token release after all epochs have elapsed
     * @dev Expects ERC20Released event with full amount after epoch 13
     */
    function test_release_successfullyReleaseTokensAfterAllEpochsElapsed() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        vm.warp(block.timestamp + 2_678_400 * 12 + 1);

        // Expect
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 1200 * 1e18);

        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }
}
