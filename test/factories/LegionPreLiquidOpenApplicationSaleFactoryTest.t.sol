// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { ECIES, Point } from "../../src/lib/ECIES.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionPreLiquidOpenApplicationSale } from "../../src/interfaces/sales/ILegionPreLiquidOpenApplicationSale.sol";
import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionPreLiquidOpenApplicationSale } from "../../src/sales/LegionPreLiquidOpenApplicationSale.sol";
import { LegionPreLiquidOpenApplicationSaleFactory } from
    "../../src/factories/LegionPreLiquidOpenApplicationSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Factory Test
 * @author Legion
 * @notice Test suite for the LegionPreLiquidOpenApplicationSaleFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionPreLiquidOpenApplicationSaleFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Contains nested pre-liquid sale test configuration
     */
    struct SaleTestConfig {
        PreLiquidSaleTestConfig preLiquidSaleTestConfig; // Nested pre-liquid sale configuration
    }

    /**
     * @notice Configuration structure for pre-liquid sale tests
     * @dev Holds initialization parameters for the sale
     */
    struct PreLiquidSaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams; // Sale initialization parameters
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test configuration for sale-related tests
     * @dev Stores the configuration used across test cases
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating pre-liquid sale V2 instances
     * @dev Deploys new instances of LegionPreLiquidOpenApplicationSale
     */
    LegionPreLiquidOpenApplicationSaleFactory public legionSaleFactory;

    /**
     * @notice Factory contract for creating vesting instances
     * @dev Deploys vesting contracts for token allocations
     */
    LegionVestingFactory public legionVestingFactory;

    /**
     * @notice Mock token used as the bidding currency
     * @dev Represents the token used for investments (e.g., USDC)
     */
    MockERC20 public bidToken;

    /**
     * @notice Mock token used as the sale token
     * @dev Represents the token being sold (e.g., LFG)
     */
    MockERC20 public askToken;

    /**
     * @notice Address of the deployed pre-liquid sale V2 instance
     * @dev Points to the active sale contract being tested
     */
    address public legionPreLiquidSaleInstance;

    /**
     * @notice Address of the Legion bouncer (owner of the factory)
     * @dev Set to 0x01, controls factory operations
     */
    address public legionBouncer = address(0x01);

    /**
     * @notice Address of the project admin
     * @dev Set to 0x02, manages sale operations
     */
    address public projectAdmin = address(0x02);

    /**
     * @notice Address representing a non-owner account
     * @dev Set to 0x03, receives referrer fees
     */
    address public referrerFeeReceiver = address(0x03);

    /**
     * @notice Address of the Legion fee receiver
     * @dev Set to 0x04, receives Legion fees
     */
    address public legionFeeReceiver = address(0x04);

    /**
     * @notice Private key for the Legion signer
     * @dev Set to 1234, used for generating valid signatures
     */
    uint256 public legionSignerPK = 1234;

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Initializes factory, vesting factory, registry, and tokens
     */
    function setUp() public {
        legionSaleFactory = new LegionPreLiquidOpenApplicationSaleFactory(legionBouncer);
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
     * @param _saleInitParams Parameters for initializing a pre-liquid sale
     */
    function setPreLiquidSaleParams(ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams) public {
        testConfig.preLiquidSaleTestConfig.saleInitParams = _saleInitParams;
    }

    /**
     * @notice Creates and initializes a LegionPreLiquidOpenApplicationSale instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionPreLiquidSale() public {
        setPreLiquidSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance =
            legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.preLiquidSaleTestConfig.saleInitParams);
    }

    /**
     * @notice Initializes the LegionAddressRegistry with required addresses
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
     * @notice Verifies that the factory contract initializes with the correct owner
     * @dev Checks that legionBouncer is set as the owner of the factory
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Expect
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Tests successful creation of a new LegionPreLiquidOpenApplicationSale instance by the owner
     * @dev Verifies that the sale instance address is non-zero after creation
     */
    function test_createPreLiquidSale_successullyCreatesPreLiquidSale() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        // Expect
        assertNotEq(legionPreLiquidSaleInstance, address(0));
    }

    /**
     * @notice Tests that creating a sale by a non-owner account reverts
     * @dev Expects Unauthorized revert when called by nonOwner
     */
    function testFuzz_createPreLiquidSale_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.preLiquidSaleTestConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are not set
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.preLiquidSaleTestConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when key parameters are zero
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setPreLiquidSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "",
                saleSymbol: "",
                saleBaseURI: ""
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.preLiquidSaleTestConfig.saleInitParams);
    }

    /**
     * @notice Verifies that a LegionPreLiquidOpenApplicationSale instance initializes with correct configuration
     * @dev Checks refund period and sale status after creation
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionPreLiquidOpenApplicationSale.PreLiquidSaleConfiguration memory _preLiquidSaleConfig =
            LegionPreLiquidOpenApplicationSale(payable(legionPreLiquidSaleInstance)).preLiquidSaleConfiguration();

        // Expect
        assertEq(_preLiquidSaleConfig.refundPeriodSeconds, 2 weeks);
        assertEq(_preLiquidSaleConfig.hasEnded, false);

        assertEq(LegionPreLiquidOpenApplicationSale(payable(legionPreLiquidSaleInstance)).name(), "Legion LFG Sale");
        assertEq(LegionPreLiquidOpenApplicationSale(payable(legionPreLiquidSaleInstance)).symbol(), "LLFGS");
    }
}
