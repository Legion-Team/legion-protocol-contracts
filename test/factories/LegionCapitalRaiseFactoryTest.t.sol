// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Errors } from "../../src/utils/Errors.sol";

import { ILegionCapitalRaise } from "../../src/interfaces/raise/ILegionCapitalRaise.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionCapitalRaise } from "../../src/raise/LegionCapitalRaise.sol";
import { LegionCapitalRaiseFactory } from "../../src/factories/LegionCapitalRaiseFactory.sol";

/**
 * @title Legion Capital Raise Factory Test
 * @author Legion
 * @notice Test suite for the LegionCapitalRaiseFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionCapitalRaiseFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the pre-liquid capital raise
    ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Template instance of the LegionCapitalRaise contract for cloning
    LegionCapitalRaise capitalRaiseTemplate;

    /// @notice Factory contract for creating pre-liquid capital raise instances
    LegionCapitalRaiseFactory legionCapitalRaiseFactory;

    /// @notice Mock token used as the bidding currency
    MockERC20 bidToken;

    /// @notice Address of the deployed pre-liquid capital raise instance
    address legionCapitalRaiseInstance;

    /// @notice Address representing an AWS broadcaster, set to 0x10
    address awsBroadcaster = address(0x10);

    /// @notice Address representing a Legion EOA, set to 0x01
    address legionEOA = address(0x01);

    /// @notice Address of the LegionBouncer contract, initialized with legionEOA and awsBroadcaster
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Private key for the Legion signer, set to 1234
    uint256 legionSignerPK = 1234;

    /// @notice Address representing the Referrer fee receiver, set to 0x08
    address referrerFeeReceiver = address(0x08);

    /// @notice Address representing the Legion fee receiver, set to 0x09
    address legionFeeReceiver = address(0x09);

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     * @dev Initializes capital raise template, factory, registry and tokens
     */
    function setUp() public {
        capitalRaiseTemplate = new LegionCapitalRaise();
        legionCapitalRaiseFactory = new LegionCapitalRaiseFactory(legionBouncer);
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Sets the pre-liquid capital raise configuration parameters
     * @dev Updates the capitalRaiseInitParams with provided initialization parameters
     * @param _capitalRaiseInitParams Parameters for initializing a pre-liquid capital raise
     */
    function setCapitalRaiseConfig(ILegionCapitalRaise.CapitalRaiseInitializationParams memory _capitalRaiseInitParams)
        public
    {
        capitalRaiseInitParams = ILegionCapitalRaise.CapitalRaiseInitializationParams({
            refundPeriodSeconds: _capitalRaiseInitParams.refundPeriodSeconds,
            legionFeeOnCapitalRaisedBps: _capitalRaiseInitParams.legionFeeOnCapitalRaisedBps,
            referrerFeeOnCapitalRaisedBps: _capitalRaiseInitParams.referrerFeeOnCapitalRaisedBps,
            bidToken: _capitalRaiseInitParams.bidToken,
            projectAdmin: _capitalRaiseInitParams.projectAdmin,
            addressRegistry: _capitalRaiseInitParams.addressRegistry,
            referrerFeeReceiver: _capitalRaiseInitParams.referrerFeeReceiver,
            saleName: _capitalRaiseInitParams.saleName,
            saleSymbol: _capitalRaiseInitParams.saleSymbol,
            saleBaseURI: _capitalRaiseInitParams.saleBaseURI
        });
    }

    /**
     * @notice Creates and initializes a LegionCapitalRaise instance
     * @dev Deploys a pre-liquid capital raise with default parameters via the factory
     */
    function prepareCreateLegionCapitalRaise() public {
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );
        vm.prank(legionBouncer);
        legionCapitalRaiseInstance = legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
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
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization with valid parameters
     * @dev Verifies capital raise configuration, status, and vesting setup post-creation
     */
    function test_createCapitalRaise_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionCapitalRaise();
        ILegionCapitalRaise.CapitalRaiseConfig memory raiseConfig =
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).saleConfiguration();
        ILegionCapitalRaise.CapitalRaiseStatus memory raiseStatus =
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).saleStatus();

        // Expect
        assertEq(raiseConfig.refundPeriodSeconds, 2 weeks);
        assertEq(raiseConfig.legionFeeOnCapitalRaisedBps, 250);
        assertEq(raiseConfig.bidToken, address(bidToken));
        assertEq(raiseConfig.projectAdmin, projectAdmin);
        assertEq(raiseConfig.addressRegistry, address(legionAddressRegistry));
        assertEq(raiseStatus.totalCapitalInvested, 0);
        assertEq(raiseStatus.totalCapitalWithdrawn, 0);
        assertEq(raiseStatus.isCanceled, false);

        assertEq(LegionCapitalRaise(payable(legionCapitalRaiseInstance)).name(), "Legion LFG Sale");
        assertEq(LegionCapitalRaise(payable(legionCapitalRaiseInstance)).symbol(), "LLFGS");
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        address capitalRaiseImplementation = legionCapitalRaiseFactory.i_capitalRaiseTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(payable(capitalRaiseImplementation)).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(capitalRaiseTemplate).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createCapitalRaise_revertsWithZeroAddressProvided() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0),
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with zero value parameters reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when refund period is zero
     */
    function test_createCapitalRaise_revertsWithZeroValueProvided() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
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
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with invalid period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when refund period is misconfigured
     */
    function test_createCapitalRaise_revertsWithInvalidPeriodConfig() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks + 1,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }
}
