// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Ownable } from "@solady/src/auth/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Initializable } from "@solady/src/utils/Initializable.sol";
import { ILegionPreLiquidSaleV1 } from "../src/interfaces/ILegionPreLiquidSaleV1.sol";
import { ILegionSaleFactory } from "../src/interfaces/ILegionSaleFactory.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/LegionBouncer.sol";
import { LegionPreLiquidSaleV1 } from "../src/LegionPreLiquidSaleV1.sol";
import { LegionSaleFactory } from "../src/LegionSaleFactory.sol";
import { LegionVestingFactory } from "../src/LegionVestingFactory.sol";
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

    LegionAddressRegistry legionAddressRegistry;
    LegionPreLiquidSaleV1 preLiquidSaleV1Template;
    LegionSaleFactory legionSaleFactory;
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
    bytes signatureInv2;
    bytes invalidSignature;

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
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Helper method: Set the pre-liquid sale configuration parameters
     */
    function setSaleConfig(ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams memory _preLiquidSaleInitParams)
        public
    {
        preLiquidSaleInitParams = ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams({
            refundPeriodSeconds: _preLiquidSaleInitParams.refundPeriodSeconds,
            vestingDurationSeconds: _preLiquidSaleInitParams.vestingDurationSeconds,
            vestingCliffDurationSeconds: _preLiquidSaleInitParams.vestingCliffDurationSeconds,
            tokenAllocationOnTGERate: _preLiquidSaleInitParams.tokenAllocationOnTGERate,
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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
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
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000030)),
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
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
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
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
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
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
                ILegionPreLiquidSaleV1.SaleAction.CLAIM_TOKEN_ALLOCATION
            )
        ).toEthSignedMessageHash();

        bytes32 digest2 = keccak256(
            abi.encodePacked(
                investor2,
                legionPreLiquidSaleInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000004)),
                ILegionPreLiquidSaleV1.SaleAction.INVEST
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

        (v, r, s) = vm.sign(legionSignerPK, digest2);
        signatureInv2 = abi.encodePacked(r, s, v);

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
        ILegionPreLiquidSaleV1.PreLiquidSaleVestingConfig memory vestingConfig =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).vestingConfiguration();

        // Assert
        assertEq(saleConfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(saleConfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(saleConfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
        assertEq(saleConfig.bidToken, address(bidToken));
        assertEq(saleConfig.projectAdmin, projectAdmin);
        assertEq(saleConfig.addressRegistry, address(legionAddressRegistry));

        assertEq(vestingConfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(vestingConfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(vestingConfig.tokenAllocationOnTGERate, TOKEN_ALLOCATION_TGE_RATE);
        assertEq(vestingConfig.vestingStartTime, 0);

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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                tokenAllocationOnTGERate: TOKEN_ALLOCATION_TGE_RATE,
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
        emit ILegionPreLiquidSaleV1.CapitalInvested(
            10_000 * 1e6,
            investor1,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            1
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            11_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
     * @dev Test case: Attempt to refund with no capital invested
     */
    function test_refund_revertsIfInvestorHasNoCapitalToRefund() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TgeDetailsPublished(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );
    }

    /* ========== SUPPLY ASK TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully supply tokens for distribution by project admin
     */
    function test_supplyAskTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.TokensSuppliedForDistribution(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens when sale is canceled
     */
    function test_supplyAskTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens that were already supplied
     */
    function test_supplyAskTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply tokens before allocation by Legion
     */
    function test_supplyAskTokens_revertsIfTokensNotAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply incorrect amount of tokens
     */
    function test_supplyAskTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 19_000 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(19_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @dev Test case: Attempt to supply incorrect Legion fee amount
     */
    function test_supplyAskTokens_revertsIfIncorrectLegionFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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
    function test_withdrawRaisedCapital_revertsIfRefundPeriodForInvestorIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
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

    /* ========== WITHDRAW CAPITAL IF SALE IS CANCELED TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw capital by investor after sale cancellation
     */
    function test_withdrawCapitalIfSaleIsCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.CapitalRefundedAfterCancel(10_000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw capital if the sale is not canceled.
     */
    function test_withdrawCapitalIfSaleIsCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /**
     * @dev Test Case: Attempt to withdraw by investor, with no capital invested.
     */
    function test_withdrawCapitalIfSaleIsCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidClaimAmount.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawCapitalIfSaleIsCanceled();
    }

    /* ========== WITHDRAW EXCESS CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw excess capital after SAFT update
     */
    function test_withdrawExcessCapital_successfullyEmitsExcessCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.ExcessCapitalWithdrawn(
            1000 * 1e6,
            investor1,
            4_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            (block.timestamp)
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e6,
            9000 * 1e6,
            4_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw excess capital after sale cancellation
     */
    function test_withdrawExcessCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e6,
            9000 * 1e6,
            4_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw more than allowed excess capital
     */
    function test_withdrawExcessCapital_revertsIfTryToWithdrawMoreThanExcess() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessCapital(
            2000 * 1e6,
            9000 * 1e6,
            4_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            signatureInv1WithdrawExcess
        );
    }

    /**
     * @dev Test case: Attempt to withdraw excess capital with invalid signature
     */
    function test_withdrawExcessCapital_revertsIfInvalidSignatureData() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + 1 days + REFUND_PERIOD_SECONDS);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessCapital(
            1000 * 1e6,
            9000 * 1e6,
            100,
            0x0000000000000000000000000000000000000000000000000000000000000030,
            signatureInv1WithdrawExcess
        );
    }

    /* ========== UPDATE VESTING TERMS TESTS ========== */

    /**
     * @dev Test Case: Successfully update vesting terms by the Project.
     */
    function test_updateVestingTerms_successfullyEmitVestingTermsUpdated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV1.VestingTermsUpdated(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms if the sale is canceled.
     */
    function test_updateVestingTerms_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms with invalid values.
     */
    function test_updateVestingTerms_revertsWithInvalidVestingConfig() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVestingConfig.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (Constants.TEN_YEARS + 1), (Constants.TEN_YEARS + 2), (1e18 + 1)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms by non-project admin.
     */
    function test_updateVestingTerms_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms if tokens are already allocated.
     */
    function test_updateVestingTerms_revertsIfTokensAreAlreadyAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );
    }

    /**
     * @dev Test Case: Attempt to update vesting terms after the project has withdrawn capital.
     */
    function test_updateVestingTerms_revertsIfCapitalHasBeenWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).endSale();

        vm.warp(block.timestamp + REFUND_PERIOD_SECONDS + 1 days);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawRaisedCapital();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ProjectHasWithdrawnCapital.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).updateVestingTerms(
            (VESTING_DURATION_SECONDS + 10), (VESTING_CLIFF_DURATION_SECONDS + 10), (TOKEN_ALLOCATION_TGE_RATE + 10)
        );
    }

    /* ========== CLAIM ASK TOKENS ALLOCATION TESTS ========== */

    /**
     * @notice Test case: Successfully claim allocated tokens by investor
     */
    function test_claimAskTokenAllocation_successfullyEmitsTokenAllocationClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Claim
        );

        (,,,,,, bool hasSettled, address vestingAddress) =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorPositions(investor1);

        assertEq(hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(vestingAddress), 4500 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor1), 500 * 1e18);
    }

    /**
     * @dev Test case: Attempt to claim tokens when allocation amount is updated without claiming excess capital
     */
    function test_claimAskTokenAllocation_revertsIfAllocationAmountIsUpdatedAndExcessCapitalIsNotClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Updated2
        );

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).withdrawExcessCapital(
            5_000_000_000,
            5_000_000_000,
            2_500_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1WithdrawExcessUpdated
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            5_000_000_000,
            2_500_000_000_000_000,
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Updated2
        );

        (,,,,,, bool hasSettled, address vestingAddress) =
            LegionPreLiquidSaleV1(payable(legionPreLiquidSaleInstance)).investorPositions(investor1);

        assertEq(hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(vestingAddress), 2250 * 1e18);
        assertEq(MockToken(askToken).balanceOf(investor1), 250 * 1e18);
    }

    /**
     * @dev Test case: Attempt to claim tokens without having invested capital
     */
    function test_claimAskTokenAllocation_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPositionAmount.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to claim tokens before ask tokens are supplied
     */
    function test_claimAskTokenAllocation_revertsIfAskTokenNotSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokensNotSupplied.selector));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1
        );
    }

    /**
     * @dev Test case: Attempt to claim tokens that were already claimed
     */
    function test_claimAskTokenAllocation_revertsIfPositionAlreadySettled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Claim
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Claim
        );
    }

    /* ========== RELEASE TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully release tokens from vesting contract after vesting period
     */
    function test_releaseTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).claimAskTokenAllocation(
            uint256(10_000 * 1e6),
            uint256(5_000_000_000_000_000),
            bytes32(uint256(0x0000000000000000000000000000000000000000000000000000000000000003)),
            signatureInv1Claim
        );

        vm.warp(block.timestamp + TWO_WEEKS + VESTING_CLIFF_DURATION_SECONDS + 3600);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseTokens();

        // Assert
        assertEq(MockToken(askToken).balanceOf(investor1), 501_027_111_872_146_118_721);
    }

    /**
     * @dev Test case: Attempt to release tokens without a deployed vesting contract
     */
    function test_releaseTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).invest(
            10_000 * 1e6,
            10_000 * 1e6,
            5_000_000_000_000_000,
            0x0000000000000000000000000000000000000000000000000000000000000003,
            signatureInv1
        );

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).supplyAskTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).releaseTokens();
    }

    /* ========== TOGGLE INVESTMENT ACCEPTED TESTS ========== */

    /**
     * @notice Test case: Successfully end sale by project admin
     */
    function test_toggleInvestmentAccepted_successfullyEmitsToggleInvestmentAccepted() public {
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
    function test_toggleInvestmentAccepted_revertsIfCalledByNonProjectAdmin() public {
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

    /**
     * @dev Test case: Attempt to end sale after tokens are allocated
     */
    function test_toggleInvestmentAccepted_revertsIfTokensAllocated() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveTokens();

        vm.warp(block.timestamp + TWO_WEEKS + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV1(legionPreLiquidSaleInstance).publishTgeDetails(
            address(askToken), 1_000_000 * 1e18, (block.timestamp + TWO_WEEKS + 2), 20_000 * 1e18
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(projectAdmin);
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
