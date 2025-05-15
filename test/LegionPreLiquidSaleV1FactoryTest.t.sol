// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../src/utils/Constants.sol";
import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";

import { ILegionFixedPriceSale } from "../src/interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionPreLiquidSaleV1 } from "../src/interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV1Factory } from "../src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/sales/ILegionSealedBidAuctionSale.sol";

import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionFixedPriceSale } from "../src/sales/LegionFixedPriceSale.sol";
import { LegionPreLiquidSaleV1 } from "../src/sales/LegionPreLiquidSaleV1.sol";
import { LegionPreLiquidSaleV1Factory } from "../src/factories/LegionPreLiquidSaleV1Factory.sol";
import { LegionSealedBidAuctionSale } from "../src/sales/LegionSealedBidAuctionSale.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Sale V1 Factory Test
 * @author Legion
 * @notice Test suite for the LegionPreLiquidSaleV1Factory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionPreLiquidSaleV1FactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Configuration struct for sale test setup
    struct SaleTestConfig {
        PreLiquidSaleTestConfig preLiquidSaleTestConfig;
    }

    /// @notice Configuration struct for pre-liquid sale parameters
    struct PreLiquidSaleTestConfig {
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Test configuration instance
    SaleTestConfig testConfig;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Factory contract for creating pre-liquid sale instances
    LegionPreLiquidSaleV1Factory legionSaleFactory;

    /// @notice Factory contract for creating vesting instances
    LegionVestingFactory legionVestingFactory;

    /// @notice Mock token used as the bidding currency
    MockERC20 bidToken;

    /// @notice Mock token used as the sale token
    MockERC20 askToken;

    /// @notice Address of a deployed LegionPreLiquidSaleV1 instance
    address legionPreLiquidSaleInstance;

    /// @notice Address representing the Legion bouncer, set to 0x01
    address legionBouncer = address(0x01);

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Address representing the Referrer fee receiver, set to 0x03
    address referrerFeeReceiver = address(0x03);

    /// @notice Address representing the Legion fee receiver, set to 0x04
    address legionFeeReceiver = address(0x04);

    /// @notice Private key for the Legion signer, set to 1234
    uint256 legionSignerPK = 1234;

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Initializes the factory, vesting factory, registry, and mock tokens
     */
    function setUp() public {
        legionSaleFactory = new LegionPreLiquidSaleV1Factory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the pre-liquid sale configuration parameters
     * @dev Updates the testConfig with provided initialization parameters
     * @param _preLiquidSaleInitParams Parameters for initializing a pre-liquid sale
     */
    function setPreLiquidSaleParams(
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams memory _preLiquidSaleInitParams
    )
        public
    {
        testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams = _preLiquidSaleInitParams;
    }

    /**
     * @notice Creates and initializes a LegionPreLiquidSaleV1 instance
     * @dev Sets up a pre-liquid sale with default parameters and deploys it
     */
    function prepareCreateLegionPreLiquidSale() public {
        setPreLiquidSaleParams(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            })
        );

        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance =
            legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Prepares the LegionAddressRegistry with initial addresses
     * @dev Sets Legion bouncer, signer, fee receiver, and vesting factory addresses
     */
    function prepareLegionAddressRegistry() public {
        vm.startPrank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_SIGNER"), vm.addr(legionSignerPK));
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), legionFeeReceiver);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_FACTORY"), address(legionVestingFactory));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that the factory initializes with the correct owner
     * @dev Verifies ownership is set to legionBouncer
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Tests successful creation of a LegionPreLiquidSaleV1 instance
     * @dev Verifies the instance address is not zero
     */
    function test_createPreLiquidSale_successullyCreatesPreLiquidSale() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        // Expect
        assertNotEq(legionPreLiquidSaleInstance, address(0));
    }

    /**
     * @notice Tests that creating a pre-liquid sale by a non-owner reverts
     * @dev Expects Unauthorized revert from Ownable when called by nonOwner
     */
    function testFuzz_createPreLiquidSale_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that creating a pre-liquid sale with zero address reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when config lacks initialization
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that creating a pre-liquid sale with zero values reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when all numeric fields are zero
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
                referrerFeeReceiver: referrerFeeReceiver
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(testConfig.preLiquidSaleTestConfig.preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that a pre-liquid sale initializes with correct configuration
     * @dev Verifies sale configuration and status details post-creation
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionPreLiquidSaleV1.PreLiquidSaleConfig memory _preLiquidSaleConfig =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleConfiguration();

        ILegionPreLiquidSaleV1.PreLiquidSaleStatus memory _preLiquidSaleStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleStatusDetails();

        // Expect
        assertEq(_preLiquidSaleConfig.refundPeriodSeconds, 2 weeks);
        assertEq(_preLiquidSaleStatus.hasEnded, false);
    }
}
