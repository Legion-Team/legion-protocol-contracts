// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Test, console2, Vm} from "forge-std/Test.sol";

import {ILegionVestingFactory} from "../src/interfaces/ILegionVestingFactory.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {LegionLinearVesting} from "../src/LegionLinearVesting.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockAskToken} from "../src/mocks/MockAskToken.sol";
import {VestingWalletUpgradeable} from "@openzeppelin/contracts-upgradeable/finance/VestingWalletUpgradeable.sol";

contract LegionLinearVestingTest is Test {
    LegionLinearVesting public linearVestingTemplate;
    LegionVestingFactory public legionVestingFactory;

    MockAskToken public askToken;

    address public legionVestingInstance;

    address legionAdmin = address(0x01);
    address allowedDeployer = address(0x02);
    address nonOwner = address(0x03);
    address vestingOwner = address(0x04);

    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant CLIFF_DURATION_SECONDS = 3600;

    function setUp() public {
        linearVestingTemplate = new LegionLinearVesting();
        legionVestingFactory = new LegionVestingFactory();
        askToken = new MockAskToken("LFG Coin", "LFG");
    }

    /**
     * @dev Helper method to create a Legion linear vesting schedule instance
     */
    function prepareCreateLegionLinearVesting() public {
        vm.prank(allowedDeployer);
        legionVestingInstance = legionVestingFactory.createLinearVesting(
            vestingOwner, uint64(block.timestamp), uint64(VESTING_DURATION_SECONDS), uint64(CLIFF_DURATION_SECONDS)
        );

        vm.deal(legionVestingInstance, 1000 ether);
        MockAskToken(askToken).mint(legionVestingInstance, 1000 * 1e18);
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
        assertEq(LegionLinearVesting(payable(legionVestingInstance)).duration(), VESTING_DURATION_SECONDS);
        assertEq(
            LegionLinearVesting(payable(legionVestingInstance)).cliffEnd(), block.timestamp + CLIFF_DURATION_SECONDS
        );
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
            vestingOwner, uint64(block.timestamp), uint64(VESTING_DURATION_SECONDS), uint64(CLIFF_DURATION_SECONDS)
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
            vestingOwner, uint64(block.timestamp), uint64(VESTING_DURATION_SECONDS), uint64(CLIFF_DURATION_SECONDS)
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
            vestingOwner, uint64(block.timestamp), uint64(VESTING_DURATION_SECONDS), uint64(CLIFF_DURATION_SECONDS)
        );
    }

    /**
     * @dev Test Case: Attempt to release tokens if cliff has not ended
     */
    function test_release_revertsIfCliffHasNotEndedToken() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(LegionLinearVesting.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release(address(askToken));
    }

    /**
     * @dev Test Case: Successfully release tokens after cliff has ended.
     */
    function test_release_successfullyReleaseTokensAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        vm.warp(block.timestamp + CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.ERC20Released(address(askToken), 114186960933536276);
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
        vm.expectRevert(abi.encodeWithSelector(LegionLinearVesting.CliffNotEnded.selector, block.timestamp));

        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release();
    }

    /**
     * @dev Test Case: Successfully release ETH after cliff has ended.
     */
    function test_release_successfullyReleaseETHAfterCliffHasEnded() public {
        // Arrange
        prepareCreateLegionLinearVesting();

        vm.warp(block.timestamp + CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectEmit();
        emit VestingWalletUpgradeable.EtherReleased(114186960933536276);
        // Act
        LegionLinearVesting(payable(legionVestingInstance)).release();
    }
}
