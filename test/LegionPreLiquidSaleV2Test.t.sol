// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console2, Vm } from "forge-std/Test.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { ILegionSale } from "../src/interfaces/ILegionSale.sol";
import { ILegionPreLiquidSaleV2 } from "../src/interfaces/ILegionPreLiquidSaleV2.sol";
import { ILegionSaleFactory } from "../src/interfaces/ILegionSaleFactory.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/LegionBouncer.sol";
import { LegionPreLiquidSaleV2 } from "../src/LegionPreLiquidSaleV2.sol";
import { LegionSaleFactory } from "../src/LegionSaleFactory.sol";
import { LegionVestingFactory } from "../src/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";

/**
 * @title Legion Pre-Liquid Sale V2 Test
 * @notice Test suite for the Legion Pre-Liquid Sale V2 contract
 */
contract LegionPreLiquidSaleV2Test is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct SaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionSale.LegionVestingInitializationParams vestingInitParams;
    }

    SaleTestConfig testConfig;

    LegionPreLiquidSaleV2 preLiquidSaleV2Template;
    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionSaleInstance;
    address awsBroadcaster = address(0x10);
    address legionEOA = address(0x01);
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));
    address projectAdmin = address(0x02);

    address investor1 = address(0x03);
    address investor2 = address(0x04);
    address investor3 = address(0x05);
    address investor4 = address(0x06);
    address investor5 = address(0x07);

    address nonLegionAdmin = address(0x08);
    address nonProjectAdmin = address(0x09);

    address legionFeeReceiver = address(0x10);

    bytes signatureInv1;
    bytes signatureInv2;
    bytes signatureInv3;
    bytes signatureInv4;
    bytes invalidSignature;

    uint256 legionSignerPK = 1234;
    uint256 nonLegionSignerPK = 12_345;

    bytes32 claimTokensMerkleRoot = 0x15c61ba404fb3c87c5853c85e7d2b741d237461665ee138f71c1041ee193862b;
    bytes32 distributeMerkleRootMalicious = 0x3669cbc540102264b01a429a06da6cc5b37f56b4f4efa289f5f0543609e8f54d;
    bytes32 distributeMerkleRootMalicious2 = 0xb2962bf5c95bc63831e3a68d7cb04b33e9e450adbc6a9847f3697af2a87ea2dc;
    bytes32 acceptedCapitalMerkleRoot = 0x54c416133cce27821e67f6c475e59fcdafb30c065ea8feaac86970c532db0202;
    bytes32 excessCapitalMerkleRootMalicious = 0x04169dca2cf842bea9fcf4df22c9372c6d6f04410bfa446585e287aa1c834974;

    /**
     * @notice Helper method: Set up test environment and deploy contracts
     */
    function setUp() public {
        preLiquidSaleV2Template = new LegionPreLiquidSaleV2();
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
    function setSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSale.LegionVestingInitializationParams memory _vestingInitParams
    )
        public
    {
        testConfig.saleInitParams = ILegionSale.LegionSaleInitializationParams({
            salePeriodSeconds: _saleInitParams.salePeriodSeconds,
            refundPeriodSeconds: _saleInitParams.refundPeriodSeconds,
            lockupPeriodSeconds: _saleInitParams.lockupPeriodSeconds,
            legionFeeOnCapitalRaisedBps: _saleInitParams.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _saleInitParams.legionFeeOnTokensSoldBps,
            referrerFeeOnCapitalRaisedBps: _saleInitParams.referrerFeeOnCapitalRaisedBps,
            referrerFeeOnTokensSoldBps: _saleInitParams.referrerFeeOnTokensSoldBps,
            minimumInvestAmount: _saleInitParams.minimumInvestAmount,
            bidToken: _saleInitParams.bidToken,
            askToken: _saleInitParams.askToken,
            projectAdmin: _saleInitParams.projectAdmin,
            addressRegistry: _saleInitParams.addressRegistry,
            referrerFeeReceiver: _saleInitParams.referrerFeeReceiver
        });

        testConfig.vestingInitParams = ILegionSale.LegionVestingInitializationParams({
            vestingDurationSeconds: _vestingInitParams.vestingDurationSeconds,
            vestingCliffDurationSeconds: _vestingInitParams.vestingCliffDurationSeconds,
            tokenAllocationOnTGERate: _vestingInitParams.tokenAllocationOnTGERate
        });
    }

    /**
     * @notice Helper method: Create and initialize a pre-liquid sale instance
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 100_000_000_000_000_000
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
    }

    /**
     * @notice Helper method: Mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.startPrank(legionBouncer);

        MockToken(bidToken).mint(investor1, 1000 * 1e6);
        MockToken(bidToken).mint(investor2, 2000 * 1e6);
        MockToken(bidToken).mint(investor3, 3000 * 1e6);
        MockToken(bidToken).mint(investor4, 4000 * 1e6);

        vm.stopPrank();

        vm.prank(investor1);
        MockToken(bidToken).approve(legionSaleInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockToken(bidToken).approve(legionSaleInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockToken(bidToken).approve(legionSaleInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockToken(bidToken).approve(legionSaleInstance, 4000 * 1e6);
    }

    /**
     * @notice Helper method: Mint tokens to the project and approve the sale instance contract
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);

        MockToken(askToken).mint(projectAdmin, 10_000 * 1e18);
        MockToken(askToken).approve(legionSaleInstance, 10_000 * 1e18);

        vm.stopPrank();
    }

    /**
     * @notice Helper method: Prepare investor signatures
     */
    function prepareInvestorSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        address nonLegionSigner = vm.addr(nonLegionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1 =
            keccak256(abi.encodePacked(investor1, legionSaleInstance, block.chainid)).toEthSignedMessageHash();
        bytes32 digest2 =
            keccak256(abi.encodePacked(investor2, legionSaleInstance, block.chainid)).toEthSignedMessageHash();
        bytes32 digest3 =
            keccak256(abi.encodePacked(investor3, legionSaleInstance, block.chainid)).toEthSignedMessageHash();
        bytes32 digest4 =
            keccak256(abi.encodePacked(investor4, legionSaleInstance, block.chainid)).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1);
        signatureInv1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2);
        signatureInv2 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest3);
        signatureInv3 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest4);
        signatureInv4 = abi.encodePacked(r, s, v);

        vm.stopPrank();

        vm.startPrank(nonLegionSigner);

        bytes32 digest5 =
            keccak256(abi.encodePacked(investor1, legionSaleInstance, block.chainid)).toEthSignedMessageHash();

        (v, r, s) = vm.sign(nonLegionSignerPK, digest5);
        invalidSignature = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Helper method: Invest capital from all investors
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.prank(investor3);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(3000 * 1e6, signatureInv3);

        vm.prank(investor4);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(4000 * 1e6, signatureInv4);
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

    /**
     * @notice Helper method: Get sale start time
     */
    function startTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Helper method: Get sale end time
     */
    function endTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Helper method: Get the refund end time
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Helper method: Get the lockup end time
     */
    function lockupEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.lockupEndTime;
    }

    /**
     * @notice Helper method: Get sale total capital raised
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionSale.LegionSaleStatus memory _saleStatusDetails =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleStatusDetails();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @notice Test case: Initialize the contract with valid parameters
     */
    function test_createPreLiquidSale_successfullyDeployedWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionSale.LegionVestingConfiguration memory _vestingConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).vestingConfiguration();

        // Assert
        assertEq(_vestingConfig.vestingDurationSeconds, Constants.ONE_YEAR);
        assertEq(_vestingConfig.vestingCliffDurationSeconds, Constants.ONE_HOUR);
    }

    /**
     * @notice Test case: Attempt to re-initialize an already initialized contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert();

        // Act
        LegionPreLiquidSaleV2(payable(legionSaleInstance)).initialize(
            testConfig.saleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize the LegionPreLiquidSaleV2 implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address fixedPriceSaleImplementation = legionSaleFactory.preLiquidSaleV2Template();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV2(payable(fixedPriceSaleImplementation)).initialize(
            testConfig.saleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize the LegionPreLiquidSaleV2 template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV2(preLiquidSaleV2Template).initialize(
            testConfig.saleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @notice Test case: Attempt to initialize with zero address configuration
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
    }

    /**
     * @notice Test case: Attempt to initialize with zero value configuration
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
    }

    /**
     * @notice Test case: Attempt to initialize with invalid period configuration (too long)
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.THREE_MONTHS + 1,
                refundPeriodSeconds: Constants.TWO_WEEKS + 1,
                lockupPeriodSeconds: Constants.SIX_MONTHS + 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
    }

    /**
     * @dev Test case: Attempt to initialize vesting configuration with invalid values.
     */
    function test_createPreLiquidSale_revertsWithInvalidVestingConfig() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.ONE_HOUR,
                lockupPeriodSeconds: Constants.ONE_HOUR,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.TEN_YEARS,
                vestingCliffDurationSeconds: Constants.TEN_YEARS + 1,
                tokenAllocationOnTGERate: 1e18 + 1
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidVestingConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
    }

    /**
     * @notice Test case: Attempt to initialize with invalid period configuration (too short)
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR - 1,
                refundPeriodSeconds: Constants.ONE_HOUR - 1,
                lockupPeriodSeconds: Constants.ONE_HOUR - 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);
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
        ILegionPreLiquidSaleV2(legionSaleInstance).pauseSale();
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
        ILegionPreLiquidSaleV2(legionSaleInstance).pauseSale();
    }

    /**
     * @notice Test case: Unpause the sale
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).pauseSale();

        // Assert
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).unpauseSale();
    }

    /**
     * @notice Test case: Attempt to unpause the sale by non-legion admin
     */
    function test_unpauseSale_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).pauseSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).unpauseSale();
    }

    /* ========== INVEST TESTS ========== */

    /**
     * @notice Test case: Successfully invest within the active sale period
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.CapitalInvested(1000 * 1e6, investor1, startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Test case: Attempt to invest after the sale has ended
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Test case: Attempt to invest with amount less than minimum
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1 * 1e5, signatureInv1);
    }

    /**
     * @notice Test case: Attempt to invest when the sale has been canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Test case: Attempt to invest with invalid signature
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, invalidSignature);
    }

    /**
     * @notice Test case: Attempt to invest when the investor has refunded
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /* ========== END SALE TESTS ========== */

    /**
     * @notice Test case: Successfully end the sale
     */
    function test_endSale_successfullyEmitsSaleEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.SaleEnded(1);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /**
     * @notice Test case: Successfully initialize the contract when lockup period is less than refund time
     */
    function test_endSale_successfullyEndSaleIfLockupPeriodLessThanRefundTime() public {
        // Arrange & Act
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.TWO_WEEKS - 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();

        // Assert
        assertEq(_saleConfig.lockupEndTime, _saleConfig.refundEndTime);
    }

    /**
     * @notice Test case: Attempt to end the sale by non-project or non-legion admin
     */
    function test_endSale_revertsIfNotCalledByLegionOrProject() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegionOrProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /**
     * @notice Test case: Attempt to end the sale if it is paused
     */
    function test_endSale_revertsIfSaleIsPaused() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).pauseSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /**
     * @notice Test case: Attempt to end the sale if it is canceled
     */
    function test_endSale_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /**
     * @notice Test case: Attempt to end the sale if already ended
     */
    function test_endSale_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /* ========== PUBLISH CAPITAL RAISED TESTS ========== */

    /**
     * @notice Test case: Successfully publish capital raised and accepted capital merkle root
     */
    function test_publishCapitalRaised_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.CapitalRaisedPublished(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to publish capital raised by non-legion admin
     */
    function test_publishCapitalRaised_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to publish capital if sale is canceled
     */
    function test_publishCapitalRaised_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
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
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to publish capital if refund period is not over
     */
    function test_publishCapitalRaised_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to publish capital raised if already published
     */
    function test_publishCapitalRaised_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);
    }

    /* ========== EMERGENCY WITHDRAW TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw funds through emergency withdraw method
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to withdraw by address other than the Legion admin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
    }

    /* ========== REFUND TESTS ========== */

    /**
     * @notice Test case: Successfully refund within the refund period
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionSale.CapitalRefunded(1000 * 1e6, investor1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();

        uint256 investor1Balance = MockToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to refund after the refund period has ended
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();
    }

    /**
     * @notice Test case: Attempt to refund when the sale is canceled
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();
    }

    /**
     * @notice Test case: Attempt to refund with no capital invested
     */
    function test_refund_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();
    }

    /**
     * @notice Test case: Attempt to refund if already refunded
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @notice Test case: Successfully cancel the ongoing sale by the project admin before results are published
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Test case: Attempt to cancel the sale if it has already been canceled
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Test case: Attempt to cancel the sale if results are published
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Test case: Attempt to cancel a sale by non-project admin
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Assert
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
    }

    /* ========== WITHDRAW INVESTED CAPITAL IF CANCELED TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw invested capital if the sale has been canceled
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Assert
        assertEq(MockToken(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to withdraw invested capital when the sale is not canceled
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Test case: Attempt to withdraw invested capital when no capital was invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /* ========== PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @notice Test case: Successfully publish sale results by the Legion admin
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.SaleResultsPublished(claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );
    }

    /**
     * @notice Test case: Attempt to publish results by non-Legion admin
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );
    }

    /**
     * @notice Test case: Attempt to publish results for a second time
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );
    }

    /**
     * @notice Test case: Attempt to publish results before the refund period is over
     */
    function test_publishSaleResults_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );
    }

    /**
     * @notice Test case: Attempt to publish results if the sale has been canceled
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );
    }

    /* ========== SET ACCEPTED CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully set accepted capital by the Legion admin
     */
    function test_setAcceptedCapital_successfullyEmitsAcceptedCapitalSet() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to set accepted capital by non-Legion admin
     */
    function test_setAcceptedCapital_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(endTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Test case: Attempt to set accepted capital if the sale has been canceled
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /* ========== SUPPLY TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully supply tokens for distribution by the project admin
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens with incorrect fee amount
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Successfully supply tokens with Legion fee set to zero
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens by non-project admin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens when the sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens with incorrect amount
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 9990 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens if sale results are not published
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens a second time
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Test case: Attempt to supply tokens if askToken is unavailable
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(claimTokensMerkleRoot, 4000 * 1e18, address(0), 0);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /* ========== CANCEL EXPIRED SALE TESTS ========== */

    /**
     * @notice Test case: Successfully cancel the sale if the lockup period is over and no tokens have been supplied
     */
    function test_cancelExpiredSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @notice Test case: Attempt to cancel when tokens have been supplied
     */
    function test_cancelExpiredSale_revertsIfTokensSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @notice Test case: Attempt to cancel when the sale has already been canceled
     */
    function test_cancelExpiredSale_revertsIfAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @notice Test case: Attempt to cancel when the lockup period is not over
     */
    function test_cancelExpiredSale_revertsIfLockupPeriodNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @notice Test case: Attempt to cancel when askToken is unavailable and results are published
     */
    function test_cancelExpiredSale_revertsIfAskTokenUnavailableAndResultsPublished() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(claimTokensMerkleRoot, 4000 * 1e18, address(0), 0);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @notice Test case: Cancel when askToken is unavailable and results are not published
     */
    function test_cancelExpiredSale_successfullyCancelIfAskTokenUnavailableAndResultsNotPublished() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();
    }

    /* ========== WITHDRAW RAISED CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw capital by the project admin after results are published and tokens are
     * supplied
     */
    function test_withdrawCapital_successfullyEmitsCapitalWithdraw() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - capitalRaised() * 250 / 10_000 - capitalRaised() * 100 / 10_000
        );
    }

    /**
     * @notice Test case: Successfully withdraw capital if the Legion fee is 0
     */
    function test_withdrawCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @notice Test case: Attempt to withdraw by someone other than the project admin
     */
    function test_withdrawCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw when sale results have not been published
     */
    function test_withdrawCapital_revertsIfCapitalRaisedNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalRaisedNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw when the refund period has not ended
     */
    function test_withdrawCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw when the sale has been canceled by the project
     */
    function test_withdrawCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw when the sale has been canceled after expiration
     */
    function test_withdrawCapital_revertsIfExpiredSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw raised capital after capital already withdrawn
     */
    function test_withdrawCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /* ========== WITHDRAW EXCESS INVESTED CAPITAL TESTS ========== */

    /**
     * @notice Test case: Successfully withdraw excess invested capital after the sale has ended
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapital() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true);
        assertEq(MockToken(bidToken).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to claim excess capital if sale is canceled
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim excess capital with incorrect merkle proof
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612707);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CannotWithdrawExcessInvestedCapital.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim excess capital if excess capital has already been claimed
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim excess capital if no capital has been invested
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);

        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(excessCapitalMerkleRootMalicious);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(6000 * 1e6, excessClaimProofInvestor5);
    }

    /* ========== CLAIM TOKEN ALLOCATION TESTS ========== */

    /**
     * @notice Test case: Successfully claim tokens after the sale, lockup period, and sale results have been published
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        // Assert
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(_investorPosition.vestingAddress), 9000 * 1e17);
    }

    /**
     * @notice Test case: Attempt to claim tokens before the lockup period is over
     */
    function test_claimTokenAllocation_revertsIfLockupPeriodHasNotEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim more tokens than allocated
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(2000 * 1e18, claimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim tokens if investor has not invested capital
     */
    function test_claimTokenAllocation_revertsIfNoCapitalIsInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        bytes32[] memory claimProofInvestor5 = new bytes32[](2);

        claimProofInvestor5[0] = bytes32(0xab15bf46a7b5a0fed230b26afe212fe8303fc537eb6e007370eabeaf0b869955);
        claimProofInvestor5[1] = bytes32(0xbe76d3200dd468b9512ea8ec335a3149f5aa5d0d975c3de3cd37afb777182abc);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            distributeMerkleRootMalicious, 4000 * 1e18, address(askToken), 0
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(4000 * 1e18, claimProofInvestor5);
    }

    /**
     * @notice Test case: Attempt to claim tokens second time
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim tokens if the sale is canceled
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim tokens if sale results have not been published
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @notice Test case: Attempt to claim tokens if askToken is not available
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /* ========== RELEASE VESTED TOKENS TESTS ========== */

    /**
     * @notice Test case: Successfully release tokens from investor vesting contract after vesting distribution
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken), 0
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        vm.warp(lockupEndTime() + Constants.ONE_HOUR + 1);

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();

        // Assert
        assertEq(MockToken(askToken).balanceOf(investor2), 198_732_933_789_954_337_899);
    }

    /**
     * @notice Test case: Attempt to release tokens if an investor does not have deployed vesting contract
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();
    }

    /**
     * @notice Test case: Attempt to release tokens if askToken is not available
     */
    function test_releaseVestedTokens_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams, testConfig.vestingInitParams);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();
    }

    /* ========== SYNC LEGION ADDRESSES TESTS ========== */

    /**
     * @notice Test case: Successfully sync Legion addresses from LegionAddressRegistry by Legion
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert
        vm.expectEmit();
        emit ILegionSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Test case: Attempt to sync Legion addresses from LegionAddressRegistry by non-Legion admin
     */
    function test_syncLegionAddresses_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).syncLegionAddresses();
    }
}
