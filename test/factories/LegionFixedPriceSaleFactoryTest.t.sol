// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionFixedPriceSale } from "../../src/interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionFixedPriceSale } from "../../src/sales/LegionFixedPriceSale.sol";
import { LegionFixedPriceSaleFactory } from "../../src/factories/LegionFixedPriceSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Fixed Price Sale Factory Test
 * @author Legion
 * @notice Test suite for the LegionFixedPriceSaleFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionFixedPriceSaleFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct to hold overall sale test configuration
    struct SaleTestConfig {
        FixedPriceSaleTestConfig fixedPriceSaleTestConfig;
    }

    /// @notice Struct to hold fixed price sale-specific test configuration
    struct FixedPriceSaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams;
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Configuration for the sale test
    SaleTestConfig testConfig;

    /// @notice Instance of the LegionAddressRegistry contract for address management
    LegionAddressRegistry public legionAddressRegistry;

    /// @notice Instance of the LegionFixedPriceSaleFactory contract under test
    LegionFixedPriceSaleFactory public legionSaleFactory;

    /// @notice Instance of the LegionVestingFactory contract for vesting management
    LegionVestingFactory public legionVestingFactory;

    /// @notice Mock token used as the bid token (e.g., USDC)
    MockERC20 public bidToken;

    /// @notice Mock token used as the ask token (e.g., LFG)
    MockERC20 public askToken;

    /// @notice Address of the deployed LegionFixedPriceSale instance
    address legionFixedPriceSaleInstance;

    /// @notice Address representing the Legion bouncer (factory owner)
    address legionBouncer = address(0x01);

    /// @notice Address representing the project admin
    address projectAdmin = address(0x02);

    /// @notice Address representing the referrer fee receiver
    address referrerFeeReceiver = address(0x03);

    /// @notice Address representing the Legion fee receiver
    address legionFeeReceiver = address(0x04);

    /// @notice Private key for generating the Legion signer address
    uint256 legionSignerPK = 1234;

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Deploys factory, vesting factory, registry, and mock tokens; configures registry
     */
    function setUp() public {
        legionSaleFactory = new LegionFixedPriceSaleFactory(legionBouncer);
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
     * @notice Configures the fixed price sale parameters for testing
     * @dev Sets the sale initialization parameters in the testConfig struct
     * @param _saleInitParams General sale initialization parameters
     * @param _fixedPriceSaleInitParams Fixed price sale-specific initialization parameters
     */
    function setFixedPriceSaleParams(
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory _fixedPriceSaleInitParams
    )
        public
    {
        testConfig.fixedPriceSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams = _fixedPriceSaleInitParams;
    }

    /**
     * @notice Prepares and creates a LegionFixedPriceSale instance for testing
     * @dev Sets default parameters and deploys a sale instance as the legionBouncer
     */
    function prepareCreateLegionFixedPriceSale() public {
        setFixedPriceSaleParams(
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
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
     * @notice Configures the LegionAddressRegistry with necessary addresses
     * @dev Sets bouncer, signer, fee receiver, and vesting factory addresses as legionBouncer
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
     * @dev Verifies that the owner of the factory is set to legionBouncer
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Expect
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Tests that a new LegionFixedPriceSale instance is successfully created by the owner
     * @dev Deploys a sale instance and checks that the address is non-zero
     */
    function test_createFixedPriceSale_successfullyCreatesFixedPriceSale() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        assertNotEq(legionFixedPriceSaleInstance, address(0));
    }

    /**
     * @notice Tests that createFixedPriceSale reverts when called by a non-owner
     * @dev Expects an Unauthorized revert from the Ownable contract
     */
    function testFuzz_createFixedPriceSale_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that createFixedPriceSale reverts with zero address configurations
     * @dev Sets zero addresses and expects a LegionSale__ZeroAddressProvided revert
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setFixedPriceSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: address(0),
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e18
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that createFixedPriceSale reverts with uninitialized (zero) configurations
     * @dev Uses uninitialized testConfig and expects a LegionSale__ZeroValueProvided revert
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(
            testConfig.fixedPriceSaleTestConfig.saleInitParams,
            testConfig.fixedPriceSaleTestConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that a LegionFixedPriceSale instance is created with correct configuration
     * @dev Verifies token price and vesting factory address after deployment
     */
    function test_createFixedPriceSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Act
        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).vestingConfiguration();
        ILegionFixedPriceSale.FixedPriceSaleConfiguration memory _fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).fixedPriceSaleConfiguration();

        // Expect
        assertEq(_fixedPriceSaleConfig.tokenPrice, 1e18);
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));

        assertEq(LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).name(), "Legion LFG Sale");
        assertEq(LegionFixedPriceSale(payable(legionFixedPriceSaleInstance)).symbol(), "LLFGS");
    }
}
