// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { ECIES, Point } from "../../src/lib/ECIES.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionSealedBidAuctionSale } from "../../src/interfaces/sales/ILegionSealedBidAuctionSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionSealedBidAuctionSale } from "../../src/sales/LegionSealedBidAuctionSale.sol";
import { LegionSealedBidAuctionSaleFactory } from "../../src/factories/LegionSealedBidAuctionSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Sealed Bid Auction Sale Factory Test
 * @author Legion
 * @notice Test suite for the LegionSealedBidAuctionSaleFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionSealedBidAuctionSaleFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Encapsulates sealed bid auction sale test configuration
     */
    struct SaleTestConfig {
        SealedBidAuctionSaleTestConfig sealedBidAuctionSaleTestConfig; // Nested config for sealed bid auction
    }

    /**
     * @notice Configuration structure for sealed bid auction sale tests
     * @dev Combines general sale params with sealed bid auction-specific params
     */
    struct SealedBidAuctionSaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams; // General sale initialization params
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams; // Sealed
            // bid-specific params
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test configuration for sealed bid auction sale tests
     * @dev Stores the configuration used across test cases
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating sealed bid auction sale instances
     * @dev Deploys new instances of LegionSealedBidAuctionSale
     */
    LegionSealedBidAuctionSaleFactory public legionSaleFactory;

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
     * @notice Mock token used as the sale token
     * @dev Represents the token being sold (e.g., LFG, 18 decimals)
     */
    MockERC20 public askToken;

    /**
     * @notice Address of the deployed sealed bid auction sale instance
     * @dev Points to the active sale contract being tested
     */
    address public legionSealedBidAuctionInstance;

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
     * @notice Public key for sealed bid auction encryption
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
        legionSaleFactory = new LegionSealedBidAuctionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6); // 6 decimals for USDC
        askToken = new MockERC20("LFG Coin", "LFG", 18); // 18 decimals for LFG
        prepareLegionAddressRegistry();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sealed bid auction sale configuration parameters
     * @dev Updates the testConfig with provided general and sealed bid-specific initialization parameters
     * @param _saleInitParams General sale initialization parameters
     * @param _sealedBidAuctionSaleInitParams Sealed bid auction-specific initialization parameters
     */
    function setSealedBidAuctionSaleParams(
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory _sealedBidAuctionSaleInitParams
    )
        public
    {
        testConfig.sealedBidAuctionSaleTestConfig.saleInitParams = _saleInitParams;
        testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams = _sealedBidAuctionSaleInitParams;
    }

    /**
     * @notice Creates and initializes a LegionSealedBidAuctionSale instance
     * @dev Deploys a sealed bid auction sale with default parameters via the factory
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSealedBidAuctionSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours, // 3600 seconds
                refundPeriodSeconds: 2 weeks, // 1,209,600 seconds
                legionFeeOnCapitalRaisedBps: 250, // 2.5%
                legionFeeOnTokensSoldBps: 250, // 2.5%
                referrerFeeOnCapitalRaisedBps: 100, // 1%
                referrerFeeOnTokensSoldBps: 100, // 1%
                minimumInvestAmount: 1e6, // 1 bid token (6 decimals adjusted in contract)
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuctionSale(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
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
     * @dev Verifies that the owner of the LegionSealedBidAuctionSaleFactory is set to legionBouncer during deployment
     */
    function test_transferOwnership_successfullySetsTheCorrectOwner() public view {
        // Expect
        assertEq(legionSaleFactory.owner(), legionBouncer);
    }

    /**
     * @notice Tests successful creation of a new LegionSealedBidAuctionSale instance by the owner
     * @dev Ensures the factory deploys a non-zero address for the sale instance when called by legionBouncer
     */
    function test_createSealedBidAuctionSale_successullyCreatesSealedBidAuction() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        // Expect
        assertNotEq(legionSealedBidAuctionInstance, address(0));
    }

    /**
     * @notice Tests that the created sale instance initializes with the correct configuration
     * @dev Verifies the public key and vesting factory address are correctly set in the deployed sale contract
     */
    function test_createSealedBidAuctionSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        ILegionSealedBidAuctionSale.SealedBidAuctionSaleConfiguration memory _sealedBidAuctionSaleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).sealedBidAuctionSaleConfiguration();
        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).vestingConfiguration();

        // Expect
        assertEq(_sealedBidAuctionSaleConfig.publicKey.x, PUBLIC_KEY.x); // Check x-coordinate of public key
        assertEq(_sealedBidAuctionSaleConfig.publicKey.y, PUBLIC_KEY.y); // Check y-coordinate of public key
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory)); // Check vesting factory address

        assertEq(LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).name(), "Legion LFG Sale");
        assertEq(LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).symbol(), "LLFGS");
    }

    /**
     * @notice Tests that creating a sale instance by a non-owner reverts
     * @dev Expects an Unauthorized revert from Ownable when called by nonOwner
     */
    function testFuzz_createSealedBidAuctionSale_revertsIfNotCalledByOwner(address nonOwner) public {
        // Arrange
        vm.assume(nonOwner != legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Ownable.Unauthorized.selector));

        // Act
        vm.prank(nonOwner);
        legionSaleFactory.createSealedBidAuctionSale(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects a LegionSale__ZeroAddressProvided revert when key addresses (bidToken, askToken, etc.) are zero
     */
    function test_createSealedBidAuctionSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSealedBidAuctionSaleParams(
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuctionSale(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects a LegionSale__ZeroValueProvided revert when key parameters (sale period, fees, etc.) are zero
     */
    function test_createSealedBidAuctionSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSealedBidAuctionSaleParams(
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
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuctionSale(
            testConfig.sealedBidAuctionSaleTestConfig.saleInitParams,
            testConfig.sealedBidAuctionSaleTestConfig.sealedBidAuctionSaleInitParams
        );
    }
}
