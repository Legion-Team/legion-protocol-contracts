// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionFixedPriceSale } from "../src/interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";
import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionFixedPriceSale } from "../src/sales/LegionFixedPriceSale.sol";
import { LegionFixedPriceSaleFactory } from "../src/factories/LegionFixedPriceSaleFactory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionFixedPriceSaleFactoryTest is Test {
    struct SaleTestConfig {
        FixedPriceSaleTestConfig fixedPriceSaleTestConfig;
    }

    struct FixedPriceSaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams;
    }

    SaleTestConfig testConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionFixedPriceSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionFixedPriceSaleInstance;

    address legionBouncer = address(0x01);
    address projectAdmin = address(0x02);
    address nonOwner = address(0x03);
    address legionFeeReceiver = address(0x04);

    uint256 legionSignerPK = 1234;

    Point PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), 69);

    function setUp() public {
        legionSaleFactory = new LegionFixedPriceSaleFactory(legionBouncer);
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
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory _fixedPriceSaleInitParams
    )
        public
    {
        testConfig.fixedPriceSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams = _fixedPriceSaleInitParams;
    }

    /**
     * @notice Helper method: Create a fixed price sale
     */
    function prepareCreateLegionFixedPriceSale() public {
        setFixedPriceSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
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
            })
        );

        vm.prank(legionBouncer);
        legionFixedPriceSaleInstance = legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
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
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
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
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
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
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Test case: Verify LegionFixedPriceSale instance initializes with correct configuration
     */
    function test_createFixedPriceSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();

        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).vestingConfiguration();
        ILegionFixedPriceSale.FixedPriceSaleConfiguration memory _fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).fixedPriceSaleConfiguration();

        // Assert
        assertEq(_fixedPriceSaleConfig.tokenPrice, 1e18);
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
    }
}
