// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Initializable } from "@solady/src/utils/Initializable.sol";
import { ILegionPreLiquidSaleV1 } from "../src/interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV1Factory } from "../src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";
import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/access/LegionBouncer.sol";
import { LegionPreLiquidSaleV1 } from "../src/sales/LegionPreLiquidSaleV1.sol";
import { LegionPreLiquidSaleV1Factory } from "../src/factories/LegionPreLiquidSaleV1Factory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";

/**
 * @title Legion Pre-Liquid Sale V1 Test
 * @notice Test suite for the Legion Pre-Liquid Sale V1 contract
 */
contract LegionPreLiquidSaleV1Test is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams;
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearVestingConfig;
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearEpochVestingConfig;

    LegionAddressRegistry legionAddressRegistry;
    LegionPreLiquidSaleV1 preLiquidSaleV1Template;
    LegionPreLiquidSaleV1Factory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionPreLiquidSaleInstance;
    address awsBroadcaster = address(0x10);
    address legionEOA = address(0x01);
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));
    address projectAdmin = address(0x02);

    bytes signatureInv1;
    bytes signatureInv1WithdrawExcess;
    bytes signatureInv1WithdrawExcessUpdated;
    bytes signatureInv1Claim;
    bytes signatureInv1Updated2;
    bytes vestingSignatureInv1;
    bytes vestingSignatureInv2Epoch;
    bytes signatureInv2;
    bytes signatureInv2Claim;
    bytes invalidSignature;
    bytes invalidVestingSignature;

    uint256 legionSignerPK = 1234;
    uint256 nonLegionSignerPK = 12_345;

    address investor1 = address(0x03);
    address investor2 = address(0x04);
    address investor5 = address(0x07);

    address nonLegionAdmin = address(0x08);
    address nonProjectAdmin = address(0x09);
    address legionFeeReceiver = address(0x10);

    address nonOwner = address(0x03);

    uint256 constant REFUND_PERIOD_SECONDS = 1_209_600;
    uint256 constant VESTING_DURATION_SECONDS = 31_536_000;
    uint256 constant VESTING_CLIFF_DURATION_SECONDS = 3600;
    uint256 constant TOKEN_ALLOCATION_TGE_RATE = 1e17;
    uint256 constant LEGION_FEE_CAPITAL_RAISED_BPS = 250;
    uint256 constant LEGION_FEE_TOKENS_SOLD_BPS = 250;
    uint256 constant REFERRER_FEE_CAPITAL_RAISED_BPS = 100;
    uint256 constant REFERRER_FEE_TOKENS_SOLD_BPS = 100;

    uint256 constant TWO_WEEKS = 1_209_600;

    /**
     * @notice Helper method: Set up test environment and deploy contracts
     */
    function setUp() public {
        preLiquidSaleV1Template = new LegionPreLiquidSaleV1();
        legionSaleFactory = new LegionPreLiquidSaleV1Factory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
        prepareInvestorLinearVestingConfig();
        prepareInvestorLinearEpochVestingConfig();
    }

    /**
     * @notice Helper method: Set the pre-liquid sale configuration parameters
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
     * @notice Helper method: Create and initialize a pre-liquid sale instance
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );
        vm.prank(legionBouncer);
        legionPreLiquidSaleInstance = legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @notice Helper method: Mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(legionBouncer);

        MockToken(bidToken).mint(investor1, 100_000 * 1e6);
        MockToken(bidToken).mint(investor2, 100_000 * 1e6);

        vm.stopPrank();

        vm.prank(investor1);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100_000 * 1e6);

        vm.prank(investor2);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 100_000 * 1e6);

        vm.startPrank(projectAdmin);

        MockToken(askToken).mint(projectAdmin, 1_000_000 * 1e18);
        MockToken(bidToken).mint(projectAdmin, 1_000_000 * 1e6);

        MockToken(askToken).approve(legionPreLiquidSaleInstance, 1_000_000 * 1e18);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 1_000_000 * 1e6);

        vm.stopPrank();
    }

    /**
     * @notice Helper method: Initialize LegionAddressRegistry with required addresses
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
     * @notice Helper method: Prepare investor linear vesting configuration
     */
    function prepareInvestorLinearVestingConfig() public {
        investorLinearVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR, (1_209_603 + TWO_WEEKS + 2), 31_536_000, 3600, 0, 0, 1e17
        );
    }

    /**
     * @notice Helper method: Prepare investor linear epoch vesting configuration
     */
    function prepareInvestorLinearEpochVestingConfig() public {
        investorLinearEpochVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
            (1_209_603 + TWO_WEEKS + 2),
            31_536_000,
            3600,
            2_628_000,
            12,
            1e17
        );
    }

    /**
     * @notice Helper method: Prepare investor signatures for authentication
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

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @notice Test case: Successfully initialize contract with valid parameters
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

        // Assert
        assertEq(saleConfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(saleConfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(saleConfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
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
     * @dev Test case: Attempt to re-initialize an already initialized contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert();

        // Act
        LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).initialize(preLiquidSaleInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize the implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        address preLiquidSaleImplementation = legionSaleFactory.preLiquidSaleV1Template();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV1(payable(preLiquidSaleImplementation)).initialize(preLiquidSaleInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize the template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV1(preLiquidSaleV1Template).initialize(preLiquidSaleInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize with zero address parameters
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize with zero value parameters
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize with invalid period configuration
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfig() public {
        // Arrange
        setSaleConfig(
            ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
                refundPeriodSeconds: REFUND_PERIOD_SECONDS + 1,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                referrerFeeOnCapitalRaisedBps: REFERRER_FEE_CAPITAL_RAISED_BPS,
                referrerFeeOnTokensSoldBps: REFERRER_FEE_TOKENS_SOLD_BPS,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV1(preLiquidSaleInitParams);
    }

    /* ========== PAUSE TESTS ========== */

    /**
     * @notice Test case: Pause the sale
     */
    function test_pauseSale_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();
    }

    /**
     * @notice Test case: Attempt to pause sale by non-legion admin
     */
    function test_pauseSale_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();
    }

    /**
     * @notice Test case: Unpause the sale
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();

        // Assert
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).unpauseSale();
    }

    /**
     * @notice Test case: Attempt to unpause the sale by non-legion admin
     */
    function test_unpauseSale_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).pauseSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).unpauseSale();
    }

    /* ========== INVEST TESTS ========== */

    /**
     * @notice Test case: Successfully invest capital in the sale
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalInvested(10_000 * 1e6, investor1, 5_000_000_000_000_000, 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to invest after sale has been canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to invest with used signature
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SignatureAlreadyUsed.selector, signatureInv1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to invest more than allowed amount
     */
    function test_invest_revertsIfInvestingMoreThanAllowed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            11_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to invest when not on whitelist
     */
    function test_invest_revertsIfInvestorNotInWhitelist() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to invest when sale is not accepting investments
     */
    function test_invest_revertsIfNotAcceptingInvestment() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /* ========== REFUND TESTS ========== */

    /**
     * @notice Test case: Successfully refund investment before refund period ends
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

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRefunded(10_000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test case: Attempt to refund when sale is canceled
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test case: Attempt to refund after refund period has ended
     */
    function test_refund_revertsIfRefundPeriodForInvestorIsOver() public {
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

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test case: Attempt to refund when investor has already refunded
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /**
     * @dev Test case: Attempt to refund with no capital invested
     */
    function test_refund_revertsIfInvestorHasNoCapitalToRefund() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).refund();
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @notice Test case: Successfully cancel sale by project admin with no capital to return
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

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @notice Test case: Successfully cancel sale by project admin with capital to return
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

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 2 days);

        vm.prank(projectAdmin);
        MockToken(bidToken).approve(legionPreLiquidSaleInstance, 10_000 * 1e6);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test case: Attempt to cancel an already canceled sale
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test case: Attempt to cancel sale by non-project admin
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /**
     * @dev Test case: Attempt to cancel sale after tokens have been supplied
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();
    }

    /* ========== PUBLISH TGE DETAILS TESTS ========== */

    /**
     * @notice Test case: Successfully publish TGE details by Legion admin
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TgeDetailsPublished(address(askToken), 1_000_000 * 1e18, 20_000 * 1e18);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /**
     * @dev Test case: Attempt to publish TGE details when sale is canceled
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /**
     * @dev Test case: Attempt to publish TGE details without Legion admin permissions
     */
    function test_publishTgeDetails_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );
    }

    /* ========== SUPPLY ASK TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully supply tokens for distribution by project admin
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TokensSuppliedForDistribution(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens when sale is canceled
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens that were already supplied
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens from non-project admin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply incorrect amount of tokens
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 19_000 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(19_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply incorrect Legion fee amount
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply incorrect referrer fee amount
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 199 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens when ask token is unavailable
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(0), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens before allocation by Legion
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(address(askToken), 1_000_000 * 1e18, 0);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /* ========== EMERGENCY WITHDRAW TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw funds through emergency withdrawal by Legion admin
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

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @dev Test case: Attempt to withdraw funds without Legion admin permissions
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
    }

    /* ========== PUBLISH CAPITAL RAISED TESTS ========== */

    /**
     * @notice Test case: Successfully publish capital raised and accepted capital merkle root
     */
    function test_publishCapitalRaised_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised by non-legion admin
     */
    function test_publishCapitalRaised_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if sale is canceled
     */
    function test_publishCapitalRaised_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if sale has not ended
     */
    function test_publishCapitalRaised_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasNotEnded.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if refund period is not over
     */
    function test_publishCapitalRaised_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised if already published
     */
    function test_publishCapitalRaised_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);
    }

    /* ========== WITHDRAW RAISED CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw raised capital by project admin
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalWithdrawn(10_000 * 1e6);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test case: Attempt to withdraw capital without project admin permissions
     */
    function test_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin() public {
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test case: Attempt to withdraw capital when sale is canceled
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test case: Attempt to withdraw capital before refund period ends
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test case: Attempt to withdraw capital if already withdrawn
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishCapitalRaised(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test case: Attempt to withdraw capital if capital raised is not published
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalNotRaised.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();
    }

    /* ========== WITHDRAW CAPITAL IF SALE IS CANCELED TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw capital by investor after sale cancellation
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

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRefundedAfterCancel(10_000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw capital if the sale is not canceled.
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw by investor, with no capital invested.
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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidClaimAmount.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /* ========== WITHDRAW EXCESS CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw excess capital after SAFT update
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
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
     * @dev Test case: Attempt to withdraw excess capital after sale cancellation
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw excess capital with used signature
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SignatureAlreadyUsed.selector, signatureInv1WithdrawExcess));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw more than allowed excess capital
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            2000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw excess capital with invalid signature
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

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 100, signatureInv1WithdrawExcess
        );
    }

    /* ========== CLAIM ASK TOKENS ALLOCATION TESTS ========== */

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear vesting
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

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

        assertEq(position.hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor1), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + TWO_WEEKS + 2));
        assertEq(vestingStatus.end, (1_209_603 + TWO_WEEKS + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + TWO_WEEKS + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear epoch vesting
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

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

        assertEq(position.hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor2), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + TWO_WEEKS + 2));
        assertEq(vestingStatus.end, (1_209_603 + TWO_WEEKS + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + TWO_WEEKS + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid linear vesting config
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVestingConfig.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            ILegionVestingManager.LegionInvestorVestingConfig(
                ILegionVestingManager.VestingType.LEGION_LINEAR,
                0,
                Constants.TEN_YEARS + 1,
                Constants.TEN_YEARS + 2,
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVestingConfig.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            ILegionVestingManager.LegionInvestorVestingConfig(
                ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
                0,
                Constants.TEN_YEARS - 1,
                Constants.TEN_YEARS - 2,
                Constants.TEN_YEARS + 1,
                100,
                1e17
            ),
            signatureInv2Claim,
            vestingSignatureInv2Epoch
        );
    }

    /**
     * @dev Test case: Attempt to claim tokens when allocation amount is updated without claiming excess capital
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

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
        assertEq(MockToken(askToken).balanceOf(position.vestingAddress), 2250 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor1), 250 * 1e18);
    }

    /**
     * @dev Test case: Attempt to claim tokens without having invested capital
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPositionAmount.selector, investor5));

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
     * @dev Test case: Attempt to claim tokens before ask tokens are supplied
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotSupplied() public {
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokensNotSupplied.selector));

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
     * @dev Test case: Attempt to claim tokens if ask token is not available
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(0), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

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
     * @dev Test case: Attempt to claim tokens that were already claimed
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

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

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor1));

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
     * @dev Test case: Attempt to claim tokens with invalid vesting signature
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

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

    /* ========== RELEASE TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully release tokens from vesting contract after vesting period
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

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

        vm.warp(block.timestamp + TWO_WEEKS + VESTING_CLIFF_DURATION_SECONDS + 3600);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseVestedTokens();

        // Assert
        assertEq(MockToken(askToken).balanceOf(investor1), 501_027_111_872_146_118_721);
    }

    /**
     * @dev Test case: Attempt to release tokens without a deployed vesting contract
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseVestedTokens();
    }

    /**
     * @dev Test case: Attempt to release tokens if ask token is not available
     */
    function test_releaseVestedTokens_revertsIfAskTokenUnavailable() public {
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

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(0), 1_000_000 * 1e18, 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseVestedTokens();
    }

    /* ========== TOGGLE INVESTMENT ACCEPTED TESTS ========== */

    /**
     * @notice Test case: Successfully end sale by project admin
     */
    function test_endSale_successfullyEndsSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.SaleEnded(1);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();
    }

    /**
     * @dev Test case: Attempt to end sale without project admin permissions
     */
    function test_endSale_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegionOrProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();
    }

    /* ========== SYNC LEGION ADDRESSES TESTS ========== */

    /**
     * @notice Test case: Successfully sync Legion addresses from registry
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).syncLegionAddresses();
    }

    /**
     * @dev Test case: Attempt to sync Legion addresses without Legion admin permissions
     */
    function test_syncLegionAddresses_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).syncLegionAddresses();
    }
}
