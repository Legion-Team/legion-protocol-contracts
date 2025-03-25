// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../src/utils/Constants.sol";
import { Errors } from "../src/utils/Errors.sol";

import { ILegionVestingFactory } from "../src/interfaces/factories/ILegionVestingFactory.sol";

import { LegionLinearVesting } from "../src/vesting/LegionLinearVesting.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Linear Vesting Test
 * @author Legion
 * @notice Test suite for the LegionLinearVesting contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionLinearVestingTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Template instance of the LegionLinearVesting contract for cloning
    LegionLinearVesting public linearVestingTemplate;

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
        linearVestingTemplate = new LegionLinearVesting();
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockERC20("LFG Coin", "LFG", 18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates and initializes a LegionLinearVesting instance
     * @dev Sets up a vesting schedule with predefined parameters and funds it
     */
    function prepareCreateLegionLinearVesting() public {
        legionVestingInstance = legionVestingFactory.createLinearVesting(
            vestingOwner, uint64(block.timestamp), uint64(52 weeks), uint64(1 hours)
        );
        vm.deal(legionVestingInstance, 1000 ether);
        askToken.mint(legionVestingInstance, 1000 * 1e18);
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
        prepareCreateLegionLinearVesting();

        // Expect
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).owner(), vestingOwner);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).start(), block.timestamp);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).duration(), 52 weeks);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).cliffEndTimestamp(), block.timestamp + 1 hours);
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(52 weeks), uint64(1 hours)
        );
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address linearVestingImplementation = legionVestingFactory.i_linearVestingTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearVesting(payable(linearVestingImplementation)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(52 weeks), uint64(1 hours)
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
        LegionLinearVesting(payable(linearVestingTemplate)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(52 weeks), uint64(1 hours)
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TOKEN RELEASE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that releasing tokens before cliff period ends reverts
     * @dev Expects CliffNotEnded revert with current timestamp
     */
    function test_release_revertsIfCliffHasNotEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @notice Tests successful token release after cliff period ends
     * @dev Expects ERC20Released event with calculated amount after cliff
     */
    function test_release_successfullyReleaseTokensAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        vm.warp(block.timestamp + 1 hours + 1);

        // Expect
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 114_500_661_375_661_375);

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release(address(askToken));
    }
}
