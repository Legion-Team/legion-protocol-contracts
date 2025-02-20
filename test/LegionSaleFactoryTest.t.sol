// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionSale } from "../src/interfaces/ILegionSale.sol";
import { ILegionFixedPriceSale } from "../src/interfaces/ILegionFixedPriceSale.sol";
import { ILegionPreLiquidSaleV2 } from "../src/interfaces/ILegionPreLiquidSaleV2.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/ILegionSealedBidAuctionSale.sol";
import { ILegionSaleFactory } from "../src/interfaces/ILegionSaleFactory.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionFixedPriceSale } from "../src/LegionFixedPriceSale.sol";
import { LegionPreLiquidSaleV2 } from "../src/LegionPreLiquidSaleV2.sol";
import { LegionSealedBidAuctionSale } from "../src/LegionSealedBidAuctionSale.sol";
import { LegionSaleFactory } from "../src/LegionSaleFactory.sol";
import { LegionVestingFactory } from "../src/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionSaleFactoryTest is Test {
    struct SaleTestConfig {
        FixedPriceSaleTestConfig fixedPriceSaleTestConfig;
        SealedBidAuctionSaleTestConfig sealedBidAuctionSaleTestConfig;
        PreLiquidSaleTestConfig preLiquidSaleTestConfig;
    }

    struct FixedPriceSaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams;
        ILegionSale.LegionVestingInitializationParams vestingInitParams;
    }

    struct SealedBidAuctionSaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams;
        ILegionSale.LegionVestingInitializationParams vestingInitParams;
    }

    struct PreLiquidSaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionSale.LegionVestingInitializationParams vestingInitParams;
    }

    SaleTestConfig testConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
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
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Helper method: Set the fixed price sale configuration
     */
    function setFixedPriceSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory _fixedPriceSaleInitParams,
        ILegionSale.LegionVestingInitializationParams memory _vestingInitParams
    )
        public
    {
        testConfig.fixedPriceSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams = _fixedPriceSaleInitParams;
        testConfig.fixedPriceSaleTestConfig.vestingInitParams = _vestingInitParams;
    }

    /**
     * @notice Helper method: Set the pre-liquid sale configuration
     */
    function setPreLiquidSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSale.LegionVestingInitializationParams memory _vestingInitParams
    )
        public
    {
        testConfig.preLiquidSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.preLiquidSaleTestConfig.vestingInitParams = _vestingInitParams;
    }

    /**
     * @notice Helper method: Set the sealed bid auction configuration
     */
    function setSealedBidAuctionSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory _sealedBidAuctionSaleInitParams,
        ILegionSale.LegionVestingInitializationParams memory _vestingInitParams
    )
        public
    {
        testConfig.sealedBidAuctionSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams = _sealedBidAuctionSaleInitParams;
        testConfig.sealedBidAuctionSaleTestConfig.vestingInitParams = _vestingInitParams;
    }

    /**
     * @notice Helper method: Create a pre-liquid sale
     */
    function prepareCreateLegionPreLiquidSale() public {
        setPreLiquidSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e18,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance = legionSaleFactory.createPreLiquidSaleV2(
            testConfig.preLiquidSaleTestConfig.saleInitParams, testConfig.preLiquidSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Helper method: Create a fixed price sale
     */
    function prepareCreateLegionFixedPriceSale() public {
        setFixedPriceSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e18,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: Constants.ONE_HOUR,
                prefundAllocationPeriodSeconds: Constants.ONE_HOUR,
                tokenPrice: 1e18
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionFixedPriceSaleInstance = legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams,
            testConfig.fixedPriceSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Helper method: Create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSealedBidAuctionSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e18,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.vestingInitParams
        );
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
     * @notice Test case: Successfully create a new LegionFixedPriceSale instance by the owner
     */
    function test_createFixedPriceSale_successullyCreatesFixedPriceSale() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();

        // Assert
        assertNotEq(legionFixedPriceSaleInstance, address(0));
    }

    /**
     * @notice Test case: Attempt to create a new LegionFixedPriceSale instance by a non-owner account
     */
    function test_createFixedPriceSale_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams,
            testConfig.fixedPriceSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configurations
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setFixedPriceSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e18,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: Constants.ONE_HOUR,
                prefundAllocationPeriodSeconds: Constants.ONE_HOUR,
                tokenPrice: 1e18
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams,
            testConfig.fixedPriceSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero value configurations
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams,
            testConfig.fixedPriceSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Verify LegionFixedPriceSale instance initializes with correct configuration
     */
    function test_createFixedPriceSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();

        ILegionSale.LegionVestingConfiguration memory _vestingConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).vestingConfiguration();
        ILegionFixedPriceSale.FixedPriceSaleConfiguration memory _fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).fixedPriceSaleConfiguration();

        // Assert
        assertEq(_fixedPriceSaleConfig.tokenPrice, 1e18);
        assertEq(_vestingConfig.vestingDurationSeconds, Constants.ONE_YEAR);
        assertEq(_vestingConfig.vestingCliffDurationSeconds, Constants.ONE_HOUR);
    }

    /**
     * @notice Test case: Successfully create a new LegionPreLiquidSaleV2 instance by the owner
     */
    function test_createPreLiquidSale_successullyCreatesPreLiquidSale() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        // Assert
        assertNotEq(legionPreLiquidSaleInstance, address(0));
    }

    /**
     * @notice Test case: Attempt to create a new LegionPreLiquidSaleV2 instance by a non-owner account
     */
    function test_createPreLiquidSale_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createPreLiquidSaleV2(
            testConfig.preLiquidSaleTestConfig.saleInitParams, testConfig.preLiquidSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configurations
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(
            testConfig.preLiquidSaleTestConfig.saleInitParams, testConfig.preLiquidSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero value configurations
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setPreLiquidSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                referrerFeeOnTokensSoldBps: 0,
                minimumInvestAmount: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(
            testConfig.preLiquidSaleTestConfig.saleInitParams, testConfig.preLiquidSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Verify LegionPreLiquidSaleV2 instance initializes with correct configuration
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionPreLiquidSaleV2.PreLiquidSaleConfiguration memory _preLiquidSaleConfig =
            LegionPreLiquidSaleV2(payable(legionPreLiquidSaleInstance)).preLiquidSaleConfiguration();

        // Assert
        assertEq(_preLiquidSaleConfig.refundPeriodSeconds, Constants.TWO_WEEKS);
        assertEq(_preLiquidSaleConfig.hasEnded, false);
    }

    /**
     * @notice Test case: Successfully create a new LegionSealedBidAuctionSale instance by the owner
     */
    function test_createSealedBidAuction_successullyCreatesSealedBidAuction() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        // Assert
        assertNotEq(legionSealedBidAuctionInstance, address(0));
    }

    /**
     * @notice Test case: Attempt to create a new LegionSealedBidAuctionSale instance by a non-owner account
     */
    function test_createSealedBidAuction_revertsIfNotCalledByOwner() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidAuctionSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e18,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero value configurations
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSealedBidAuctionSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                referrerFeeOnTokensSoldBps: 0,
                minimumInvestAmount: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonOwner)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Verify LegionSealedBidAuctionSale instance initializes with correct configuration
     */
    function test_createSealedBidAuction_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        ILegionSealedBidAuctionSale.SealedBidAuctionSaleConfiguration memory _sealedBidAuctionSaleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).sealedBidAuctionSaleConfiguration();

        ILegionSale.LegionVestingConfiguration memory _vestingConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).vestingConfiguration();

        // Assert
        assertEq(_sealedBidAuctionSaleConfig.publicKey.x, PUBLIC_KEY.x);
        assertEq(_sealedBidAuctionSaleConfig.publicKey.y, PUBLIC_KEY.y);

        assertEq(_vestingConfig.vestingDurationSeconds, Constants.ONE_YEAR);
        assertEq(_vestingConfig.vestingCliffDurationSeconds, Constants.ONE_HOUR);
    }
}
