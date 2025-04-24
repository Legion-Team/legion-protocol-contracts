// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../src/utils/Constants.sol";
import { Errors } from "../src/utils/Errors.sol";

import { ILegionPreLiquidSaleV1 } from "../src/interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV1Factory } from "../src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/access/LegionBouncer.sol";
import { LegionPreLiquidSaleV1 } from "../src/sales/LegionPreLiquidSaleV1.sol";
import { LegionPreLiquidSaleV1Factory } from "../src/factories/LegionPreLiquidSaleV1Factory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Sale V1 Test
 * @author Legion
 * @notice Test suite for the LegionPreLiquidSaleV1 contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionPreLiquidSaleV1Test is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the pre-liquid sale
    ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams;

    /// @notice Linear vesting configuration for investors
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearVestingConfig;

    /// @notice Linear epoch vesting configuration for investors
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearEpochVestingConfig;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Template instance of the LegionPreLiquidSaleV1 contract for cloning
    LegionPreLiquidSaleV1 preLiquidSaleV1Template;

    /// @notice Factory contract for creating pre-liquid sale instances
    LegionPreLiquidSaleV1Factory legionSaleFactory;

    /// @notice Factory contract for creating vesting instances
    LegionVestingFactory legionVestingFactory;

    /// @notice Mock token used as the bidding currency
    MockERC20 bidToken;

    /// @notice Mock token used as the sale token
    MockERC20 askToken;

    /// @notice Address of the deployed pre-liquid sale instance
    address legionPreLiquidSaleInstance;

    /// @notice Address representing an AWS broadcaster, set to 0x10
    address awsBroadcaster = address(0x10);

    /// @notice Address representing a Legion EOA, set to 0x01
    address legionEOA = address(0x01);

    /// @notice Address of the LegionBouncer contract, initialized with legionEOA and awsBroadcaster
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Signature for investor1's investment
    bytes signatureInv1;

    /// @notice Signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcess;

    /// @notice Updated signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcessUpdated;

    /// @notice Signature for investor1's token allocation claim
    bytes signatureInv1Claim;

    /// @notice Updated signature for investor1's token allocation claim
    bytes signatureInv1Updated2;

    /// @notice Vesting signature for investor1's linear vesting
    bytes vestingSignatureInv1;

    /// @notice Vesting signature for investor2's linear epoch vesting
    bytes vestingSignatureInv2Epoch;

    /// @notice Signature for investor2's investment
    bytes signatureInv2;

    /// @notice Signature for investor2's token allocation claim
    bytes signatureInv2Claim;

    /// @notice Invalid signature for testing invalid cases
    bytes invalidSignature;

    /// @notice Invalid vesting signature for testing invalid cases
    bytes invalidVestingSignature;

    /// @notice Private key for the Legion signer, set to 1234
    uint256 legionSignerPK = 1234;

    /// @notice Private key for a non-Legion signer, set to 12_345
    uint256 nonLegionSignerPK = 12_345;

    /// @notice Address representing investor1, set to 0x03
    address investor1 = address(0x03);

    /// @notice Address representing investor2, set to 0x04
    address investor2 = address(0x04);

    /// @notice Address representing investor5, set to 0x07
    address investor5 = address(0x07);

    /// @notice Address representing the Referrer fee receiver, set to 0x08
    address referrerFeeReceiver = address(0x08);

    /// @notice Address representing the Legion fee receiver, set to 0x09
    address legionFeeReceiver = address(0x09);

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     * @dev Initializes sale template, factory, vesting factory, registry, tokens, and vesting configs
     */
    function setUp() public {
        preLiquidSaleV1Template = new LegionPreLiquidSaleV1();
        legionSaleFactory = new LegionPreLiquidSaleV1Factory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
        prepareInvestorLinearVestingConfig();
        prepareInvestorLinearEpochVestingConfig();
    }

    /**
     * @notice Sets the pre-liquid sale configuration parameters
     * @dev Updates the preLiquidSaleInitParams with provided initialization parameters
     * @param _preLiquidSaleInitParams Parameters for initializing a pre-liquid sale
     */
    function setSaleConfig(ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams memory _preLiquidSaleInitParams)
        public
    {
        preLiquidSaleInitParams = ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
            refundPeriodSeconds: _preLiquidSaleInitParams.refundPeriodSeconds,
            legionFeeOnCapitalRaisedBps: _preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _preLiquidSaleInitParams.legionFeeOnTokensSoldBps,
            referrerFeeOnCapitalRaisedBps: _preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps,
            referrerFeeOnTokensSoldBps: _preLiquidSaleInitParams.referrerFeeOnTokensSoldBps,
            bidToken: _preLiquidSaleInitParams.bidToken,
            projectAdmin: _preLiquidSaleInitParams.projectAdmin,
            addressRegistry: _preLiquidSaleInitParams.addressRegistry,
            referrerFeeReceiver: _preLiquidSaleInitParams.referrerFeeReceiver
        });
    }

    /**
     * @notice Creates and initializes a LegionPreLiquidSaleV1 instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            })
        );
        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance = legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @notice Mints tokens to investors and approves the sale instance
     * @dev Prepares bid and ask tokens for investors and project admin
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(legionBouncer);
        bidToken.mint(investor1, 100_000 * 1e6);
        bidToken.mint(investor2, 100_000 * 1e6);
        vm.stopPrank();

        vm.prank(investor1);
        bidToken.approve(legionPreLiquidSaleInstance, 100_000 * 1e6);

        vm.prank(investor2);
        bidToken.approve(legionPreLiquidSaleInstance, 100_000 * 1e6);

        vm.startPrank(projectAdmin);
        askToken.mint(projectAdmin, 1_000_000 * 1e18);
        bidToken.mint(projectAdmin, 1_000_000 * 1e6);
        askToken.approve(legionPreLiquidSaleInstance, 1_000_000 * 1e18);
        bidToken.approve(legionPreLiquidSaleInstance, 1_000_000 * 1e6);
        vm.stopPrank();
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

    /**
     * @notice Prepares the linear vesting configuration for investors
     * @dev Sets up a linear vesting schedule with predefined parameters
     */
    function prepareInvestorLinearVestingConfig() public {
        investorLinearVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR, (1_209_603 + 2 weeks + 2), 31_536_000, 3600, 0, 0, 1e17
        );
    }

    /**
     * @notice Prepares the linear epoch vesting configuration for investors
     * @dev Sets up a linear epoch vesting schedule with predefined parameters
     */
    function prepareInvestorLinearEpochVestingConfig() public {
        investorLinearEpochVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
            (1_209_603 + 2 weeks + 2),
            31_536_000,
            3600,
            2_628_000,
            12,
            1e17
        );
    }

    /**
     * @notice Prepares investor signatures for authentication
     * @dev Generates signatures for investment, withdrawal, and vesting actions
     */
    function prepareInvestorSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        address nonLegionSigner = vm.addr(nonLegionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1 = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();

        bytes32 digest1WithdrawExcess = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(9000 * 1e6),
                uint256(4_000_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest1WithdrawExcessUpdated = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(5000 * 1e6),
                uint256(2_500_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest1Claim = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.CLAIM_TOKEN_ALLOCATION
            )
        ).toEthSignedMessageHash();

        bytes32 digest1Updated2 = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(5000 * 1e6),
                uint256(2_500_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.CLAIM_TOKEN_ALLOCATION
            )
        ).toEthSignedMessageHash();

        bytes32 digest1Vesting = keccak256(
            abi.encode(investor1, legionPreLiquidSaleInstance, block.chainid, investorLinearVestingConfig)
        ).toEthSignedMessageHash();

        bytes32 digest2VestingEpoch = keccak256(
            abi.encode(investor2, legionPreLiquidSaleInstance, block.chainid, investorLinearEpochVestingConfig)
        ).toEthSignedMessageHash();

        bytes32 digest2 = keccak256(
            abi.encodePacked(
                investor2,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();

        bytes32 digest2Claim = keccak256(
            abi.encodePacked(
                investor2,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionPreLiquidSaleV1.SaleAction.CLAIM_TOKEN_ALLOCATION
            )
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1);
        signatureInv1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1WithdrawExcess);
        signatureInv1WithdrawExcess = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1WithdrawExcessUpdated);
        signatureInv1WithdrawExcessUpdated = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1Claim);
        signatureInv1Claim = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1Updated2);
        signatureInv1Updated2 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1Vesting);
        vestingSignatureInv1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2VestingEpoch);
        vestingSignatureInv2Epoch = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2);
        signatureInv2 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2Claim);
        signatureInv2Claim = abi.encodePacked(r, s, v);

        vm.stopPrank();

        vm.startPrank(nonLegionSigner);

        bytes32 digest5 = keccak256(
            abi.encodePacked(
                investor1,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
                ILegionPreLiquidSaleV1.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(nonLegionSignerPK, digest5);
        invalidSignature = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(nonLegionSignerPK, digest1Vesting);
        invalidVestingSignature = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Retrieves the refund period end time
     * @dev Fetches the refund end time from the sale configuration
     * @return uint256 The refund period end time in seconds
     */
    function refundEndTime() public view returns (uint256) {
        ILegionPreLiquidSaleV1.PreLiquidSaleStatus memory _saleStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleStatusDetails();
        return _saleStatus.refundEndTime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization with valid parameters
     * @dev Verifies sale configuration, status, and vesting setup post-creation
     */
    function test_createPreLiquidSale_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();
        ILegionPreLiquidSaleV1.PreLiquidSaleConfig memory saleConfig =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleConfiguration();
        ILegionPreLiquidSaleV1.PreLiquidSaleStatus memory saleStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).saleStatusDetails();
        ILegionVestingManager.LegionVestingConfig memory vestingConfig =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).vestingConfiguration();

        // Expect
        assertEq(saleConfig.refundPeriodSeconds, 2 weeks);
        assertEq(saleConfig.legionFeeOnCapitalRaisedBps, 250);
        assertEq(saleConfig.legionFeeOnTokensSoldBps, 250);
        assertEq(saleConfig.bidToken, address(bidToken));
        assertEq(saleConfig.projectAdmin, projectAdmin);
        assertEq(saleConfig.addressRegistry, address(legionAddressRegistry));

        assertEq(vestingConfig.vestingFactory, address(legionVestingFactory));

        assertEq(saleStatus.askToken, address(0));
        assertEq(saleStatus.askTokenTotalSupply, 0);
        assertEq(saleStatus.totalCapitalInvested, 0);
        assertEq(saleStatus.totalTokensAllocated, 0);
        assertEq(saleStatus.totalCapitalWithdrawn, 0);
        assertEq(saleStatus.isCanceled, false);
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).initialize(preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            })
        );

        address preLiquidSaleImplementation = legionSaleFactory.i_preLiquidSaleV1Template();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV1(payable(preLiquidSaleImplementation)).initialize(preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV1(preLiquidSaleV1Template).initialize(preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value parameters reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when refund period is zero
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
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
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with invalid period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when refund period is misconfigured
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfig() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 2 weeks + 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by Legion admin
     * @dev Expects Paused event emission when paused by legionBouncer
     */
    function test_pauseSale_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pauseSale_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();
    }

    /**
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).unpauseSale();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpauseSale_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).unpauseSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful investment in the sale
     * @dev Expects CapitalInvested event emission with correct parameters
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalInvested(10_000 * 1e6, investor1, 5_000_000_000_000_000, 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing after sale cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with a used signature reverts
     * @dev Expects LegionSale__SignatureAlreadyUsed revert when signature is reused
     */
    function test_invest_revertsIfSignatureAlreadyUsed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SignatureAlreadyUsed.selector, signatureInv1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing more than allowed amount reverts
     * @dev Expects LegionSale__InvalidPositionAmount revert when exceeding signed amount
     */
    function test_invest_revertsIfInvestingMoreThanAllowed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            11_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing by a non-whitelisted investor reverts
     * @dev Expects LegionSale__InvalidSignature revert when signature doesn’t match investor
     */
    function test_invest_revertsIfInvestorNotInWhitelist() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing when sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale has ended
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, 1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                REFUND TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful refund before refund period ends
     * @dev Expects CapitalRefunded event emission with correct amount
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRefunded(10_000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding after refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when period expires
     */
    function test_refund_revertsIfRefundPeriodIsOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when already refunded
     */
    function test_refund_revertsIfInvestorHasAlreadyRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 3600);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();

        vm.warp(block.timestamp + 7200);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects LegionSale__InvalidRefundAmount revert when no investment exists
     */
    function test_refund_revertsIfInvestorHasNoCapitalToRefund() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidRefundAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful sale cancellation with no capital to return
     * @dev Expects SaleCanceled event emission when no capital remains
     */
    function test_cancelSale_successfullyEmitsSaleCanceledWithNoCapitalToReturn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @notice Tests successful sale cancellation with capital to return
     * @dev Expects SaleCanceled event emission after capital is withdrawn
     */
    function test_cancelSale_successfullyEmitsSaleCanceledWithCapitalToReturn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1 days);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();

        vm.warp(block.timestamp + 2 weeks + 2 days);

        vm.prank(projectAdmin);
        bidToken.approve(legionPreLiquidSaleInstance, 10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is already canceled
     */
    function test_cancelSale_revertsIfSaleIsAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_cancelSale_revertsIfCalledByNonProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling after tokens are supplied reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert when tokens are supplied
     */
    function test_cancelSale_revertsIfAskTokensHaveBeenSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLISH TGE DETAILS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of TGE details by Legion admin
     * @dev Expects TgeDetailsPublished event emission with correct parameters
     */
    function test_publishTgeDetails_successfullyEmitsTgeDetailsPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TgeDetailsPublished(address(askToken), 1_000_000 * 1e18, 20_000 * 1e18);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /**
     * @notice Tests that publishing TGE details when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_publishTgeDetails_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /**
     * @notice Tests that publishing TGE details by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishTgeDetails_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                           SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token supply by project admin
     * @dev Expects TokensSuppliedForDistribution event emission with correct amounts
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TokensSuppliedForDistribution(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens twice reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert when tokens are already supplied
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_supplyTokens_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);

        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect token amount reverts
     * @dev Expects LegionSale__InvalidTokenAmountSupplied revert when amount mismatches TGE details
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidTokenAmountSupplied.selector, 19_000 * 1e18, 20_000 * 1e18)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(19_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect Legion fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when Legion fee is incorrect
     */
    function test_supplyTokens_revertsIfIncorrectLegionFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 499 * 1e18, 500 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect referrer fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when referrer fee is incorrect
     */
    function test_supplyTokens_revertsIfIncorrectReferrerFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 199 * 1e18, 200 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 199 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with no allocation reverts
     * @dev Expects LegionSale__TokensNotAllocated revert when total tokens allocated is zero
     */
    function test_supplyTokens_revertsIfTokensNotAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(address(askToken), 1_000_000 * 1e18, 0);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful emergency withdrawal by Legion admin
     * @dev Expects EmergencyWithdraw event emission with correct parameters
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH CAPITAL RAISED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully publish capital raised and accepted capital merkle root
     * @dev Expects CapitalRaisedPublished event emission with correct amount after sale ends and refund period expires
     */
    function test_publishCapitalRaised_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised by non-legion admin
     * @dev Expects LegionSale__NotCalledByLegion revert when called by an unauthorized address
     */
    function testFuzz_publishCapitalRaised_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to publish after sale cancellation
     */
    function test_publishCapitalRaised_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if sale has not ended
     * @dev Expects LegionSale__SaleHasNotEnded revert when sale is still active
     */
    function test_publishCapitalRaised_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasNotEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refund period expires
     */
    function test_publishCapitalRaised_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised if already published
     * @dev Expects LegionSale__CapitalRaisedAlreadyPublished revert when attempting to publish twice
     */
    function test_publishCapitalRaised_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully withdraw raised capital by project admin
     * @dev Expects CapitalWithdrawn event emission after capital is published and refund period ends
     */
    function test_withdrawRaisedCapital_successfullyEmitsCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalWithdrawn(10_000 * 1e6);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital without project admin permissions
     * @dev Expects LegionSale__NotCalledByProject revert when called by a non-project admin address
     */
    function testFuzz_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);

        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital when sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to withdraw after cancellation
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital before refund period ends
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refund period expires
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsNotOver.selector, (block.timestamp), refundEndTime()
            )
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital if already withdrawn
     * @dev Expects LegionSale__CapitalAlreadyWithdrawn revert when attempting to withdraw twice
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital if capital raised is not published
     * @dev Expects LegionSale__CapitalNotRaised revert when capital raised has not been published
     */
    function test_withdrawRaisedCapital_revertsIfCapitalRaisedNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalNotRaised.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                  WITHDRAW CAPITAL IF SALE IS CANCELED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of invested capital by an investor after sale cancellation
     * @dev Verifies CapitalRefundedAfterCancel event is emitted with 10,000 USDC for investor1
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRefundedAfterCancel(10_000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital when the sale is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when investor1 tries to withdraw without cancellation
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital with no investment reverts
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor2, who didn't invest, tries to withdraw
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW EXCESS CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully withdraw excess capital if amount allowed to invest has changed
     * @dev Expects ExcessCapitalWithdrawn event emission with correct parameters
     */
    function test_withdrawExcessInvestedCapital_successfullyEmitsExcessCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.ExcessCapitalWithdrawn(
            1000 * 1e6, investor1, 4_000_000_000_000_000, (block.timestamp)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital after sale cancellation
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to withdraw after sale is canceled
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital with used signature
     * @dev Expects LegionSale__SignatureAlreadyUsed revert when reusing a signature for withdrawal
     */
    function test_withdrawExcessInvestedCapital_revertsIfSignatureAlreadyUsed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__SignatureAlreadyUsed.selector, signatureInv1WithdrawExcess)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw more than allowed excess capital
     * @dev Expects LegionSale__InvalidPositionAmount revert when withdrawal exceeds allowed excess
     */
    function test_withdrawExcessInvestedCapital_revertsIfTryToWithdrawMoreThanExcess() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            2000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital with invalid signature
     * @dev Expects LegionSale__InvalidSignature revert when signature data does not match expected values
     */
    function test_withdrawExcessInvestedCapital_revertsIfInvalidSignatureData() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1WithdrawExcess)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 100, signatureInv1WithdrawExcess
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM TOKEN ALLOCATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear vesting
     * @dev Verifies token allocation and vesting setup with linear vesting after TGE details and token supply
     */
    function test_claimTokenAllocation_successfullyEmitsTokenAllocationClaimedWithLinearVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Claim,
            vestingSignatureInv1
        );

        ILegionPreLiquidSaleV1.InvestorPosition memory position =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorPositionDetails(investor1);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorVestingStatus(investor1);

        // Expect
        assertEq(position.hasSettled, true);
        assertEq(MockERC20(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockERC20(askToken).balanceOf(investor1), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + 2 weeks + 2));
        assertEq(vestingStatus.end, (1_209_603 + 2 weeks + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + 2 weeks + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear epoch vesting
     * @dev Verifies token allocation and vesting setup with linear epoch vesting after TGE details and token supply
     */
    function test_claimTokenAllocation_successfullyEmitsTokenAllocationClaimedWithLinearEpochVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearEpochVestingConfig,
            signatureInv2Claim,
            vestingSignatureInv2Epoch
        );

        ILegionPreLiquidSaleV1.InvestorPosition memory position =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorPositionDetails(investor2);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorVestingStatus(investor2);

        // Expect
        assertEq(position.hasSettled, true);
        assertEq(MockERC20(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockERC20(askToken).balanceOf(investor2), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + 2 weeks + 2));
        assertEq(vestingStatus.end, (1_209_603 + 2 weeks + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + 2 weeks + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid linear vesting config
     * @dev Expects LegionVesting__InvalidVestingConfig revert when linear vesting parameters are invalid
     */
    function test_claimTokenAllocation_revertsIfInvalidLinearVestingConfig() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionVesting__InvalidVestingConfig.selector,
                uint8(ILegionVestingManager.VestingType.LEGION_LINEAR),
                Constants.MAX_VESTING_LOCKUP_SECONDS + block.timestamp + 1,
                520 weeks + 1,
                520 weeks + 2,
                0,
                0,
                1e18 + 1
            )
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            ILegionVestingManager.LegionInvestorVestingConfig(
                ILegionVestingManager.VestingType.LEGION_LINEAR,
                Constants.MAX_VESTING_LOCKUP_SECONDS + block.timestamp + 1,
                520 weeks + 1,
                520 weeks + 2,
                0,
                0,
                1e18 + 1
            ),
            signatureInv1Claim,
            vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid linear vesting config
     * @dev Expects LegionVesting__InvalidVestingConfig revert when linear epoch vesting parameters are invalid
     */
    function test_claimTokenAllocation_revertsIfInvalidLinearEpochVestingConfig() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionVesting__InvalidVestingConfig.selector,
                uint8(ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH),
                0,
                520 weeks - 1,
                520 weeks - 2,
                520 weeks + 1,
                100,
                1e17
            )
        );

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            ILegionVestingManager.LegionInvestorVestingConfig(
                ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
                0,
                520 weeks - 1,
                520 weeks - 2,
                520 weeks + 1,
                100,
                1e17
            ),
            signatureInv2Claim,
            vestingSignatureInv2Epoch
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens when allocation amount is updated without claiming excess capital
     * @dev Expects LegionSale__InvalidSignature revert initially, then verifies claim after excess capital withdrawal
     */
    function test_claimTokenAllocation_revertsIfAllocationAmountIsUpdatedAndExcessCapitalIsNotClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1Updated2));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Updated2,
            vestingSignatureInv1
        );

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            5_000_000_000, 5_000_000_000, 2_500_000_000_000_000, signatureInv1WithdrawExcessUpdated
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            5_000_000_000,
            2_500_000_000_000_000,
            investorLinearVestingConfig,
            signatureInv1Updated2,
            vestingSignatureInv1
        );

        ILegionPreLiquidSaleV1.InvestorPosition memory position =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorPositionDetails(investor1);

        assertEq(position.hasSettled, true);
        assertEq(MockERC20(askToken).balanceOf(position.vestingAddress), 2250 * 1e18);
        assertEq(MockERC20(askToken).balanceOf(investor1), 250 * 1e18);
    }

    /**
     * @notice Test case: Attempt to claim tokens without having invested capital
     * @dev Expects LegionSale__InvalidPositionAmount revert when investor has no prior investment
     */
    function test_claimTokenAllocation_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPositionAmount.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1,
            vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens before ask tokens are supplied
     * @dev Expects LegionSale__TokensNotSupplied revert when tokens are not yet supplied
     */
    function test_claimTokenAllocation_revertsIfTokensNotSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotSupplied.selector));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1,
            vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens that were already claimed
     * @dev Expects LegionSale__AlreadySettled revert when attempting to claim a settled position
     */
    function test_claimTokenAllocation_revertsIfPositionAlreadySettled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Claim,
            vestingSignatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadySettled.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Claim,
            vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid vesting signature
     * @dev Expects LegionSale__InvalidSignature revert when vesting signature is invalid
     */
    function test_claimTokenAllocation_revertsIfVestingSignatureNotValid() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidVestingSignature));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Claim,
            invalidVestingSignature
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        RELEASE VESTED TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully release tokens from vesting contract after vesting period
     * @dev Verifies token release from vesting contract to investor after cliff period has passed
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            investorLinearVestingConfig,
            signatureInv1Claim,
            vestingSignatureInv1
        );

        vm.warp(block.timestamp + 2 weeks + 1 hours + 3600);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseVestedTokens();

        // Expect
        assertEq(MockERC20(askToken).balanceOf(investor1), 501_027_111_872_146_118_721);
    }

    /**
     * @notice Test case: Attempt to release tokens without a deployed vesting contract
     * @dev Expects LegionSale__ZeroAddressProvided revert when investor has no vesting contract deployed
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseVestedTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               END SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully end sale by project admin
     * @dev Expects SaleEnded event emission when project admin ends the sale
     */
    function test_endSale_successfullyEndsSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleEnded(1);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();
    }

    /**
     * @notice Test case: Attempt to end sale without project admin permissions
     * @dev Expects LegionSale__NotCalledByLegionOrProject revert when called by non-project admin
     */
    function testFuzz_endSale_revertsIfCalledByNonProjectOrNonLegionAdmin(address nonProjectOrLegionAdmin) public {
        // Arrange
        vm.assume(nonProjectOrLegionAdmin != projectAdmin && nonProjectOrLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegionOrProject.selector));

        // Act
        vm.prank(nonProjectOrLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully sync Legion addresses from registry
     * @dev Expects LegionAddressesSynced event emission with updated addresses from registry
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Test case: Attempt to sync Legion addresses without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).syncLegionAddresses();
    }
}
