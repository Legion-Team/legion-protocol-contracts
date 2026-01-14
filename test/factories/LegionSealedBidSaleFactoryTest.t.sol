// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { ECIES, Point } from "../../src/lib/ECIES.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionSealedBidSale } from "../../src/interfaces/sales/ILegionSealedBidSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionSealedBidSale } from "../../src/sales/LegionSealedBidSale.sol";
import { LegionSealedBidSaleFactory } from "../../src/factories/LegionSealedBidSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Sealed Bid Sale Factory Test
 * @author Legion
 * @notice Test suite for the LegionSealedBidSaleFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionSealedBidSaleFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Encapsulates sealed bid sale test configuration
     */
    struct SaleTestConfig {
        SealedBidSaleTestConfig sealedBidSaleTestConfig; // Nested config for sealed bid sale
    }

    /**
     * @notice Configuration structure for sealed bid sale tests
     * @dev Combines general sale params with sealed bid sale-specific params
     */
    struct SealedBidSaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams; // General sale initialization params
        ILegionSealedBidSale.SealedBidSaleInitializationParams sealedBidSaleInitParams; // Sealed
            // bid-specific params
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test configuration for sealed bid sale tests
     * @dev Stores the configuration used across test cases
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating sealed bid sale instances
     * @dev Deploys new instances of LegionSealedBidSale
     */
    LegionSealedBidSaleFactory public legionSaleFactory;

    /**
     * @notice Factory contract for creating vesting instances
     * @dev Deploys vesting contracts for token allocations
     */
    LegionVestingFactory public legionVestingFactory;

    /**
     * @notice Mock token used as the bidding currency
     * @dev Represents the token used for bids (e.g., USDC, 6 decimals)
     */
    MockERC20 public bidToken;

    /**
     * @notice Address of the deployed sealed bid sale instance
     * @dev Points to the active sale contract being tested
     */
    address public legionSealedBidSaleInstance;

    /**
     * @notice Address representing the Legion bouncer (owner)
     * @dev Set to 0x01, has ownership privileges over the factory
     */
    address public legionBouncer = address(0x01);

    /**
     * @notice Address representing the project admin
     * @dev Set to 0x02, manages sale operations
     */
    address public projectAdmin = address(0x02);

    /**
     * @notice Address representing the Referrer fee receiver
     * @dev Set to 0x03, receives referrer fees
     */
    address public referrerFeeReceiver = address(0x03);

    /**
     * @notice Address representing the Legion fee receiver
     * @dev Set to 0x04, receives Legion fees
     */
    address public legionFeeReceiver = address(0x04);

    /**
     * @notice Private key for the Legion signer
     * @dev Set to 1234, used for signature generation
     */
    uint256 public legionSignerPK = 1234;

    /**
     * @notice Public key for sealed bid encryption
     * @dev Computed using ECIES.calcPubKey with a test point (1, 2) and private key 69
     */
    Point public PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), 69);

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Initializes factory, vesting factory, registry, and mock tokens; configures the address registry
     */
    function setUp() public {
        legionSaleFactory = new LegionSealedBidSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6); // 6 decimals for USDC
        prepareLegionAddressRegistry();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sealed bid sale configuration parameters
     * @dev Updates the testConfig with provided general and sealed bid-specific initialization parameters
     * @param _saleInitParams General sale initialization parameters
     * @param _sealedBidSaleInitParams Sealed bid sale-specific initialization parameters
     */
    function setSealedBidSaleParams(
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidSale.SealedBidSaleInitializationParams memory _sealedBidSaleInitParams
    )
        public
    {
        testConfig.sealedBidSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.sealedBidSaleTestConfig.sealedBidSaleInitParams = _sealedBidSaleInitParams;
    }

    /**
     * @notice Creates and initializes a LegionSealedBidSale instance
     * @dev Deploys a sealed bid sale with default parameters via the factory
     */
    function prepareCreateLegionSealedBidSale() public {
        setSealedBidSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                minimumInvestAmount: 1e6,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidSaleInstance = legionSaleFactory.createSealedBidSale(
            testConfig.sealedBidSaleTestConfig.saleInitParams,
            testConfig.sealedBidSaleTestConfig.sealedBidSaleInitParams
        );
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
     * @notice Tests that the factory contract initializes with the correct owner
     * @dev Verifies that the owner of the LegionSealedBidSaleFactory is set to legionBouncer during deployment
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Expect
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Tests successful creation of a new LegionSealedBidSale instance by the owner
     * @dev Ensures the factory deploys a non-zero address for the sale instance when called by legionBouncer
     */
    function test_createSealedBidSale_successullyCreatesSealedBidSale() public {
        // Arrange & Act
        prepareCreateLegionSealedBidSale();

        // Expect
        assertNotEq(legionSealedBidSaleInstance, address(0));
    }

    /**
     * @notice Tests that the created sale instance initializes with the correct configuration
     * @dev Verifies the public key and vesting factory address are correctly set in the deployed sale contract
     */
    function test_createSealedBidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionSealedBidSale();

        ILegionSealedBidSale.SealedBidSaleConfiguration memory _sealedBidSaleConfig =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).sealedBidSaleConfiguration();

        // Expect
        assertEq(_sealedBidSaleConfig.publicKey.x, PUBLIC_KEY.x); // Check x-coordinate of public key
        assertEq(_sealedBidSaleConfig.publicKey.y, PUBLIC_KEY.y); // Check y-coordinate of public key
    }

    /**
     * @notice Tests that creating a sale instance by a non-owner reverts
     * @dev Expects an Unauthorized revert from Ownable when called by nonOwner
     */
    function testFuzz_createSealedBidSale_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createSealedBidSale(
            testConfig.sealedBidSaleTestConfig.saleInitParams,
            testConfig.sealedBidSaleTestConfig.sealedBidSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects a LegionSale__ZeroAddressProvided revert when key addresses (bidToken, etc.) are zero
     */
    function test_createSealedBidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                minimumInvestAmount: 1e18,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            }),
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(
            testConfig.sealedBidSaleTestConfig.saleInitParams,
            testConfig.sealedBidSaleTestConfig.sealedBidSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects a LegionSale__ZeroValueProvided revert when key parameters (sale period, fees, etc.) are zero
     */
    function test_createSealedBidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSealedBidSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                minimumInvestAmount: 0,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(
            testConfig.sealedBidSaleTestConfig.saleInitParams,
            testConfig.sealedBidSaleTestConfig.sealedBidSaleInitParams
        );
    }
}
