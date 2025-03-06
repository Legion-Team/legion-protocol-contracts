// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionSale } from "../src/interfaces/ILegionSale.sol";
import { ILegionFixedPriceSale } from "../src/interfaces/ILegionFixedPriceSale.sol";
import { ILegionPreLiquidSaleV1 } from "../src/interfaces/ILegionPreLiquidSaleV1.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/ILegionSealedBidAuctionSale.sol";
import { ILegionPreLiquidSaleV1Factory } from "../src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionFixedPriceSale } from "../src/LegionFixedPriceSale.sol";
import { LegionPreLiquidSaleV1 } from "../src/LegionPreLiquidSaleV1.sol";
import { LegionSealedBidAuctionSale } from "../src/LegionSealedBidAuctionSale.sol";
import { LegionPreLiquidSaleV1Factory } from "../src/factories/LegionPreLiquidSaleV1Factory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionPreLiquidSaleV1FactoryTest is Test {
    struct SaleTestConfig {
        PreLiquidSaleTestConfig preLiquidSaleTestConfig;
    }

    struct PreLiquidSaleTestConfig {
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams;
    }

    SaleTestConfig testConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionPreLiquidSaleV1Factory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionFixedPriceSaleInstance;
    address legionPreLiquidSaleInstance;
    address legionSealedBidAuctionInstance;

    address legionBouncer = address(0x01);
    address projectAdmin = address(0x02);
    address nonOwner = address(0x03);
    address legionFeeReceiver = address(0x04);

    uint256 legionSignerPK = 1234;

    Point PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), 69);

    function setUp() public {
        legionSaleFactory = new LegionPreLiquidSaleV1Factory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Helper method: Set the pre-liquid sale configuration
     */
    function setPreLiquidSaleParams(
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams memory _preLiquidSaleInitParams
    )
        public
    {
        testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams = _preLiquidSaleInitParams;
    }

    /**
     * @notice Helper method: Create a pre-liquid sale
     */
    function prepareCreateLegionPreLiquidSale() public {
        setPreLiquidSaleParams(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: Constants.TWO_WEEKS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            })
        );

        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance =
            legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Helper method: Prepare LegionAddressRegistry
     */
    function prepareLegionAddressRegistry() public {
        vm.startPrank(legionBouncer);

        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_SIGNER"), vm.addr(legionSignerPK));
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), legionFeeReceiver);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_FACTORY"), address(legionVestingFactory));

        vm.stopPrank();
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @notice Test case: Verify that the factory contract initializes with the correct owner
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Assert
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Test case: Successfully create a new LegionPreLiquidSaleV1 instance by the owner
     */
    function test_createPreLiquidSale_successullyCreatesPreLiquidSale() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        // Assert
        assertNotEq(legionPreLiquidSaleInstance, address(0));
    }

    /**
     * @notice Test case: Attempt to create a new LegionPreLiquidSaleV1 instance by a non-owner account
     */
    function test_createPreLiquidSale_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configurations
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Test case: Attempt to initialize with zero value configurations
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setPreLiquidSaleParams(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                referrerFeeOnTokensSoldBps: 0,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Test case: Verify LegionPreLiquidSaleV2 instance initializes with correct configuration
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionPreLiquidSaleV1.PreLiquidSaleConfig memory _preLiquidSaleConfig =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleConfiguration();

        ILegionPreLiquidSaleV1.PreLiquidSaleStatus memory _preLiquidSaleStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleStatusDetails();

        // Assert
        assertEq(_preLiquidSaleConfig.refundPeriodSeconds, Constants.TWO_WEEKS);
        assertEq(_preLiquidSaleStatus.hasEnded, false);
    }
}
