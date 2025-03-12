// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionVestingFactory } from "../src/interfaces/factories/ILegionVestingFactory.sol";
import { LegionLinearEpochVesting } from "../src/vesting/LegionLinearEpochVesting.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

/**
 * @title Legion Linear Epoch Vesting Test
 * @notice Test suite for the Legion Linear Vesting contract
 */
contract LegionLinearEpochVestingTest is Test {
    LegionLinearEpochVesting public linearVestingTemplate;
    LegionVestingFactory public legionVestingFactory;

    MockToken public askToken;

    address public legionVestingInstance;

    address legionAdmin = address(0x01);
    address allowedDeployer = address(0x02);
    address nonOwner = address(0x03);
    address vestingOwner = address(0x04);

    function setUp() public {
        linearVestingTemplate = new LegionLinearEpochVesting();
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockToken("LFG Coin", "LFG", 18);
    }

    /**
     * @notice Helper method: Create and initialize a Legion linear vesting schedule instance
     */
    function prepareCreateLegionLinearEpochVesting() public {
        legionVestingInstance = legionVestingFactory.createLinearEpochVesting(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(Constants.ONE_HOUR), 2_678_400, 12
        );
        //console2.log(block.timestamp);
        vm.deal(legionVestingInstance, 1200 ether);
        MockToken(askToken).mint(legionVestingInstance, 1200 * 1e18);
    }

    /**
     * @notice Test case: Successfully initialize contract with valid parameters
     */
    function test_createLinearVesting_successfullyDeployWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionLinearEpochVesting();

        // Assert
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).owner(), vestingOwner);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).start(), block.timestamp);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).duration(), 2_678_400 * 12);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).cliffEnd(), Constants.ONE_HOUR + 1);
        assertEq(LegionLinearEpochVesting(payable(legionVestingInstance)).getCurrentEpoch(), 1);
        assertEq(
            LegionLinearEpochVesting(payable(legionVestingInstance)).getCurrentEpochAtTimestamp(block.timestamp), 1
        );
    }

    /**
     * @dev Test case: Attempt to re-initialize an already initialized contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Assert
        vm.expectRevert();

        // Act
        vm.prank(nonOwner);
        LegionLinearEpochVesting(payable(legionVestingInstance)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(Constants.ONE_HOUR), 2_678_400, 12
        );
    }

    /**
     * @dev Test case: Attempt to initialize the implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address linearVestingImplementation = legionVestingFactory.linearEpochVestingTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearEpochVesting(payable(linearVestingImplementation)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(Constants.ONE_HOUR), 2_678_400, 12
        );
    }

    /**
     * @dev Test case: Attempt to initialize the template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearEpochVesting(payable(linearVestingTemplate)).initialize(
            vestingOwner, uint64(block.timestamp), 2_678_400 * 12, uint64(Constants.ONE_HOUR), 2_678_400, 12
        );
    }

    /**
     * @dev Test case: Attempt to release tokens before cliff period ends
     */
    function test_release_revertsIfCliffHasNotEndedToken() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @notice Test case: Successfully release tokens after cliff period ends
     */
    function test_release_successfullyReleaseTokensAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Move to EPOCH 2
        vm.warp(block.timestamp + 2_678_400 + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 100 * 1e18);
        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @notice Test case: Successfully release tokens after all epochs have elapsed
     */
    function test_release_successfullyReleaseTokensAfterAllEpochsElapsed() public {
        // Arrange
        prepareCreateLegionLinearEpochVesting();

        // Move to EPOCH 13
        vm.warp(block.timestamp + 2_678_400 * 12 + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 1200 * 1e18);
        // Act
        LegionLinearEpochVesting(payable(legionVestingInstance)).release(address(askToken));
    }
}
