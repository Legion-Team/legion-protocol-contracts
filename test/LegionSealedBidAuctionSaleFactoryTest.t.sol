// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/sales/ILegionSealedBidAuctionSale.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";
import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionSealedBidAuctionSale } from "../src/sales/LegionSealedBidAuctionSale.sol";
import { LegionSealedBidAuctionSaleFactory } from "../src/factories/LegionSealedBidAuctionSaleFactory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionSealedBidAuctionSaleFactoryTest is Test {
    struct SaleTestConfig {
        SealedBidAuctionSaleTestConfig sealedBidAuctionSaleTestConfig;
    }

    struct SealedBidAuctionSaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams;
    }

    SaleTestConfig testConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionSealedBidAuctionSaleFactory legionSaleFactory;
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
        legionSaleFactory = new LegionSealedBidAuctionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Helper method: Set the sealed bid auction configuration
     */
    function setSealedBidAuctionSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory _sealedBidAuctionSaleInitParams
    )
        public
    {
        testConfig.sealedBidAuctionSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams = _sealedBidAuctionSaleInitParams;
    }

    /**
     * @notice Helper method: Create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSealedBidAuctionSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
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
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidAuctionSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
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

        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).vestingConfiguration();

        // Assert
        assertEq(_sealedBidAuctionSaleConfig.publicKey.x, PUBLIC_KEY.x);
        assertEq(_sealedBidAuctionSaleConfig.publicKey.y, PUBLIC_KEY.y);

        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
    }
}
