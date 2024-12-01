// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { VestingWalletUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionVestingFactory } from "../src/interfaces/ILegionVestingFactory.sol";
import { LegionLinearVesting } from "../src/LegionLinearVesting.sol";
import { LegionVestingFactory } from "../src/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionLinearVestingTest is Test {
    LegionLinearVesting public linearVestingTemplate;
    LegionVestingFactory public legionVestingFactory;

    MockToken public askToken;

    address public legionVestingInstance;

    address legionAdmin = address(0x01);
    address allowedDeployer = address(0x02);
    address nonOwner = address(0x03);
    address vestingOwner = address(0x04);

    function setUp() public {
        linearVestingTemplate = new LegionLinearVesting();
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockToken("LFG Coin", "LFG", 18);
    }

    /**
     * @dev Helper method to create a Legion linear vesting schedule instance
     */
    function prepareCreateLegionLinearVesting() public {
        legionVestingInstance = legionVestingFactory.createLinearVesting(
            vestingOwner, uint64(block.timestamp), uint64(Constants.ONE_YEAR), uint64(Constants.ONE_HOUR)
        );

        vm.deal(legionVestingInstance, 1000 ether);
        MockToken(askToken).mint(legionVestingInstance, 1000 * 1e18);
    }

    /**
     * @dev Test Case: Successfully initialize the contract with a valid beneficiary, start timestamp, and duration
     */
    function test_createLinearVesting_successfullyDeployWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionLinearVesting();

        // Assert
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).owner(), vestingOwner);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).start(), block.timestamp);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).duration(), Constants.ONE_YEAR);
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).cliffEnd(), block.timestamp + Constants.ONE_HOUR);
    }

    /**
     * @dev Test Case: Attempt to re-initialize the contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Assert
        vm.expectRevert();

        // Act
        vm.prank(nonOwner);
        LegionLinearVesting(payable(legionVestingInstance)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(Constants.ONE_YEAR), uint64(Constants.ONE_HOUR)
        );
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionLinearVesting` implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address linearVestingImplementation = legionVestingFactory.linearVestingTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearVesting(payable(linearVestingImplementation)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(Constants.ONE_YEAR), uint64(Constants.ONE_HOUR)
        );
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionLinearVesting` template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionLinearVesting(payable(linearVestingTemplate)).initialize(
            vestingOwner, uint64(block.timestamp), uint64(Constants.ONE_YEAR), uint64(Constants.ONE_HOUR)
        );
    }

    /**
     * @dev Test Case: Attempt to release tokens if cliff has not ended
     */
    function test_release_revertsIfCliffHasNotEndedToken() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @dev Test Case: Successfully release tokens after cliff has ended.
     */
    function test_release_successfullyReleaseTokensAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        vm.warp(block.timestamp + Constants.ONE_HOUR + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 114_186_960_933_536_276);
        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @dev Test Case: Attempt to release ETH if cliff has not ended
     */
    function test_release_revertsIfCliffHasNotEndedETH() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release();
    }

    /**
     * @dev Test Case: Successfully release ETH after cliff has ended.
     */
    function test_release_successfullyReleaseETHAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        vm.warp(block.timestamp + Constants.ONE_HOUR + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.EtherReleased(114_186_960_933_536_276);
        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release();
    }
}
