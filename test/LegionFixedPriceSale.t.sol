// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ILegionBaseSale} from "../src/interfaces/ILegionBaseSale.sol";
import {ILegionFixedPriceSale} from "../src/interfaces/ILegionFixedPriceSale.sol";
import {ILegionSaleFactory} from "../src/interfaces/ILegionSaleFactory.sol";
import {LegionAddressRegistry} from "../src/LegionAddressRegistry.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";
import {LegionFixedPriceSale} from "../src/LegionFixedPriceSale.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockAskToken} from "../src/mocks/MockAskToken.sol";
import {MockBidToken} from "../src/mocks/MockBidToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract LegionFixedPriceSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    ILegionFixedPriceSale.FixedPriceSaleConfig saleConfig;
    LegionFixedPriceSale fixedPriceSaleTemplate;

    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockBidToken bidToken;
    MockAskToken askToken;

    uint8 askTokenDecimals;

    address legionSaleInstance;

    address awsBroadcaster = address(0x10);
    address legionEOA = address(0x01);
    address legionBouncer = address(new LegionAccessControl(legionEOA, awsBroadcaster));
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
    uint256 nonLegionSignerPK = 12345;

    bytes32 claimTokensMerkleRoot = 0x15c61ba404fb3c87c5853c85e7d2b741d237461665ee138f71c1041ee193862b;
    bytes32 distributeMerkleRootMalicious = 0x3669cbc540102264b01a429a06da6cc5b37f56b4f4efa289f5f0543609e8f54d;
    bytes32 distributeMerkleRootMalicious2 = 0xb2962bf5c95bc63831e3a68d7cb04b33e9e450adbc6a9847f3697af2a87ea2dc;
    bytes32 excessCapitalMerkleRoot = 0x54c416133cce27821e67f6c475e59fcdafb30c065ea8feaac86970c532db0202;
    bytes32 excessCapitalMerkleRootMalicious = 0x04169dca2cf842bea9fcf4df22c9372c6d6f04410bfa446585e287aa1c834974;

    uint256 constant PREFUND_PERIOD_SECONDS = 3600;
    uint256 constant PREFUND_ALLOCATION_PERIOD_SECONDS = 3600;
    uint256 constant SALE_PERIOD_SECONDS = 3600;
    uint256 constant REFUND_PERIOD_SECONDS = 1209600;
    uint256 constant LOCKUP_PERIOD_SECONDS = 3456000;
    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant VESTING_CLIFF_DURATION_SECONDS = 3600;
    uint256 constant LEGION_FEE_CAPITAL_RAISED_BPS = 250;
    uint256 constant LEGION_FEE_TOKENS_SOLD_BPS = 250;
    uint256 constant MINIMUM_PLEDGE_AMOUNT = 1 * 1e6;
    uint256 constant TOKEN_PRICE = 1 * 1e6;

    uint256 constant ONE_HOUR = 3600;
    uint256 constant TWO_WEEKS = 1209600;
    uint256 constant THREE_MONTHS = 7776000;
    uint256 constant SIX_MONTHS = 15780000;

    function setUp() public {
        fixedPriceSaleTemplate = new LegionFixedPriceSale();
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockBidToken("USD Coin", "USDC");
        askToken = new MockAskToken("LFG Coin", "LFG");
        askTokenDecimals = uint8(askToken.decimals());
        prepareLegionAddressRegistry();
    }

    /**
     * @dev Helper method to set the fixed price sale configuration
     */
    function setSaleConfig(ILegionFixedPriceSale.FixedPriceSaleConfig memory _saleConfig) public {
        saleConfig = ILegionFixedPriceSale.FixedPriceSaleConfig({
            prefundPeriodSeconds: _saleConfig.prefundPeriodSeconds,
            prefundAllocationPeriodSeconds: _saleConfig.prefundAllocationPeriodSeconds,
            salePeriodSeconds: _saleConfig.salePeriodSeconds,
            refundPeriodSeconds: _saleConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _saleConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _saleConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _saleConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _saleConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _saleConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _saleConfig.minimumPledgeAmount,
            tokenPrice: _saleConfig.tokenPrice,
            bidToken: _saleConfig.bidToken,
            askToken: _saleConfig.askToken,
            projectAdmin: _saleConfig.projectAdmin,
            addressRegistry: _saleConfig.addressRegistry
        });
    }

    /**
     * @dev Helper method to create a fixed price sale
     */
    function prepareCreateLegionFixedPriceSale() public {
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
    }

    /**
     * @dev Helper method to mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.startPrank(legionBouncer);
        MockBidToken(bidToken).mint(investor1, 1000 * 1e6);
        MockBidToken(bidToken).mint(investor2, 2000 * 1e6);
        MockBidToken(bidToken).mint(investor3, 3000 * 1e6);
        MockBidToken(bidToken).mint(investor4, 4000 * 1e6);
        vm.stopPrank();

        vm.prank(investor1);
        MockBidToken(bidToken).approve(legionSaleInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockBidToken(bidToken).approve(legionSaleInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockBidToken(bidToken).approve(legionSaleInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockBidToken(bidToken).approve(legionSaleInstance, 4000 * 1e6);
    }

    /**
     * @dev Helper method to prepare investor signatures
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
     * @dev Helper method to pledge capital from all investors
     */
    function preparePledgedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(2000 * 1e6, signatureInv2);

        vm.prank(investor3);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(3000 * 1e6, signatureInv3);

        vm.prank(investor4);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(4000 * 1e6, signatureInv4);
    }

    /**
     * @dev Helper method to prepare LegionAddressRegistry
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
     * @dev Helper method to get sale start time
     */
    function startTime() public view returns (uint256) {
        ILegionFixedPriceSale.FixedPriceSaleStatus memory saleStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
        return saleStatus.startTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function endTime() public view returns (uint256) {
        ILegionFixedPriceSale.FixedPriceSaleStatus memory saleStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
        return saleStatus.endTime;
    }

    /**
     * @dev Helper method to get the refund end time
     */
    function refundEndTime() public view returns (uint256) {
        ILegionFixedPriceSale.FixedPriceSaleStatus memory saleStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
        return saleStatus.refundEndTime;
    }

    /**
     * @dev Helper method to get the lockup end time
     */
    function lockupEndTime() public view returns (uint256) {
        ILegionFixedPriceSale.FixedPriceSaleStatus memory saleStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
        return saleStatus.lockupEndTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function capitalRaised() public view returns (uint256) {
        ILegionFixedPriceSale.FixedPriceSaleStatus memory saleStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
        return saleStatus.totalCapitalRaised;
    }
    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize the contract with valid parameters.
     */
    function test_createFixedPriceSale_successfullyDeployedWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionFixedPriceSale();
        ILegionFixedPriceSale.FixedPriceSaleConfig memory fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();

        // Assert
        assertEq(fixedPriceSaleConfig.prefundPeriodSeconds, PREFUND_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfig.prefundAllocationPeriodSeconds, PREFUND_ALLOCATION_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfig.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfig.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(fixedPriceSaleConfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(fixedPriceSaleConfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(fixedPriceSaleConfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(fixedPriceSaleConfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);
        assertEq(fixedPriceSaleConfig.tokenPrice, TOKEN_PRICE);

        assertEq(fixedPriceSaleConfig.bidToken, address(bidToken));
        assertEq(fixedPriceSaleConfig.askToken, address(askToken));
        assertEq(fixedPriceSaleConfig.projectAdmin, projectAdmin);
        assertEq(fixedPriceSaleConfig.addressRegistry, address(legionAddressRegistry));
    }

    /**
     * @dev Test Case: Attempt to re-initialize the contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Assert
        vm.expectRevert();

        // Act
        LegionFixedPriceSale(payable(legionSaleInstance)).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionFixedPriceSale` implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        address fixedPriceSaleImplementation = legionSaleFactory.fixedPriceSaleTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionFixedPriceSale(payable(fixedPriceSaleImplementation)).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionFixedPriceSale` template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionFixedPriceSale(fixedPriceSaleTemplate).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(0),
                askToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: 0,
                prefundAllocationPeriodSeconds: 0,
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                vestingDurationSeconds: 0,
                vestingCliffDurationSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                tokenPrice: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too long)
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: THREE_MONTHS + 1,
                prefundAllocationPeriodSeconds: TWO_WEEKS + 1,
                salePeriodSeconds: THREE_MONTHS + 1,
                refundPeriodSeconds: TWO_WEEKS + 1,
                lockupPeriodSeconds: SIX_MONTHS + 1,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too short)
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: ONE_HOUR - 1,
                prefundAllocationPeriodSeconds: ONE_HOUR - 1,
                salePeriodSeconds: ONE_HOUR - 1,
                refundPeriodSeconds: ONE_HOUR - 1,
                lockupPeriodSeconds: ONE_HOUR - 1,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(saleConfig);
    }

    /* ========== PLEDGE CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully pledge capital within the active sale period.
     */
    function test_pledgeCapital_successfullyEmitsCapitalPledgedNotPrefund() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalPledged(1000 * 1e6, investor1, false, startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);
    }

    /**
     * @dev Test Case: Attempt to pledge capital within the prefund allocation period.
     */
    function test_pledgeCapital_revertsIfPrefundAllocationPeriodNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionFixedPriceSale.PrefundAllocationPeriodNotEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);
    }

    /**
     * @dev Test Case: Successfully pledge capital within the prefund sale period.
     */
    function test_pledgeCapital_successfullyEmitsCapitalPledgedPrefund() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalPledged(1000 * 1e6, investor1, true, block.timestamp);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);
    }

    /**
     * @dev Test Case: Pledge capital after the sale has ended
     */
    function test_pledgeCapital_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);
    }

    /**
     * @dev Test Case: Pledge capital with amount less than the minimum amount
     */
    function test_pledgeCapital_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidPledgeAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1 * 1e5, signatureInv1);
    }

    /**
     * @dev Test Case: Pledge capital when the sale is canceled
     */
    function test_pledgeCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);
    }

    /**
     * @dev Test Case: Pledge capital with invalid signature
     */
    function test_pledgeCapital_revertsIfInvalidSignature() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, invalidSignature);
    }

    /* ========== EMERGENCY WITHDRAW TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw funds through emergencyWithdraw method.
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to withdraw by address other than the Legion admin.
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
    }

    /* ========== REQUEST REFUND TESTS ========== */

    /**
     * @dev Test Case: Successfully request a refund within the refund period.
     */
    function test_requestRefund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalRefunded(1000 * 1e6, investor1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).requestRefund();

        uint256 investor1Balance = MockBidToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @dev Test Case: Request a refund after the refund period has ended
     */
    function test_requestRefund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund when the sale is canceled and within the refund period
     */
    function test_requestRefund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund with no capital pledged
     */
    function test_requestRefund_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund before the sale has ended
     */
    function test_requestRefund_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 30 minutes);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasNotEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).requestRefund();
        uint256 investor1Balance = MockBidToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 0);
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the ongoing sale by the project admin before results are published
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 7 days);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if it has already been canceled
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if results are published
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Assert
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale by non project admin
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Assert
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime());

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /* ========== CLAIM BACK CANCELED SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully claim back capital if the sale has been canceled.
     */
    function test_claimBackCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).claimBackCapitalIfCanceled();

        // Assert
        assertEq(MockBidToken(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to claim back capital when the sale is not canceled
     */
    function test_claimBackCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 7 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).claimBackCapitalIfCanceled();
    }

    /**
     * @dev Test Case: Attempt to claim back capital when no capital was pledged
     */
    function test_claimBackCapitalIfCanceled_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidClaimAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).claimBackCapitalIfCanceled();
    }

    /* ========== PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish sale results by the Legion admin.
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionFixedPriceSale.SaleResultsPublished(claimTokensMerkleRoot, 4000 * 1e18);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @dev Test Case: Attempt to publish results by non-Legion admin.
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @dev Test Case: Publish results when sale results are already set
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensAlreadyAllocated.selector, 4000 * 1e18));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 3999 * 1e18, askTokenDecimals
        );
    }

    /**
     * @dev Test Case: Publish results before the refund period is over
     */
    function test_publishSaleResults_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @dev Test Case: Publish results if the sale has been canceled
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1 weeks);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /* ========== PUBLISH EXCESS CAPITAL RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish excess capital results by the Legion admin.
     */
    function test_publishExcessCapitalResults_successfullyEmitsExcessCapitalResultsPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.ExcessCapitalResultsPublished(excessCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Attempt to publish excess capital results by non-Legion admin.
     */
    function test_publishExcessCapitalResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish results when excess capital results are already set
     */
    function test_publishExcessCapitalResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                ILegionBaseSale.ExcessCapitalResultsAlreadyPublished.selector, excessCapitalMerkleRoot
            )
        );

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish results before the sale is over
     */
    function test_publishExcessCapitalResults_revertsIfSaleIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasNotEnded.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish excess capital results if the sale has been canceled
     */
    function test_publishExcessCapitalResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1 weeks);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /* ========== SUPPLY TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully supply tokens for distribution by the project admin
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Supply tokens with incorrect fee amount
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4090 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4090 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18);
    }

    /**
     * @dev Test Case: Successfully supply tokens with Legion fee 0
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);

        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4000 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4000 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 0);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 0);
    }

    /**
     * @dev Test Case: Attempt to supply tokens by non-admin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(nonProjectAdmin);
        MockAskToken(askToken).mint(nonProjectAdmin, 10250 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 10250 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10000 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens when the sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens with incorrect amount
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 10240 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 10240 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidTokenAmountSupplied.selector, 9990 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if sale results are not published
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 10250 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 10250 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10000 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens twice
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 8200 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 8200 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if `askToken` is unavailable
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /* ========== CANCEL EXPIRED SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the sale if the lockup period is over and no tokens have been supplied
     */
    function test_cancelExpiredSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when tokens have been supplied
     */
    function test_cancelExpiredSale_revertsIfTokensSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 40100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 40100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensAlreadySupplied.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the sale has already been canceled
     */
    function test_cancelExpiredSale_revertsIfAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the lockup period is not over
     */
    function test_cancelExpiredSale_revertsIfLockupPeriodNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when `askToken` is unavailable and results are published
     */
    function test_cancelExpiredSale_revertsIfAskTokenUnavailableAndResultsPublished() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Cancel when `askToken` is unavailable and results are not published
     */
    function test_cancelExpiredSale_successfullyCancelIfAskTokenUnavailableAndResultsNotPublished() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).pledgeCapital(1000 * 1e6, signatureInv1);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();
    }

    /* ========== WITHDRAW CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw capital by the project admin after results are published and tokens are supplied.
     */
    function test_withdrawCapital_successfullyEmitsCapitalWithdraw() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();

        // Assert
        assertEq(
            bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * LEGION_FEE_CAPITAL_RAISED_BPS / 10000
        );
    }

    /**
     * @dev Test Case: Successfully withdraw capital if the Legion fee is 0
     */
    function test_withdrawCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);

        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();

        // Assert
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised());
    }

    /**
     * @dev Test Case: Attempt withdrawal by someone other than the project admin
     */
    function test_withdrawCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdrawal when tokens have not been supplied
     */
    function test_withdrawCapital_revertsIfNoTokensSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when sale results have not been published
     */
    function test_withdrawCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the refund period has not ended
     */
    function test_withdrawCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled by the project
     */
    function test_withdrawCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled after expiration
     */
    function test_withdrawCapital_revertsIfExpiredSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
    }

    /* ========== CLAIM EXCESS CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully claim excess capital to investor after the sale has ended.
     */
    function test_claimExcessCapital_successfullyTransfersBackExcessCapitalTokens() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert

        (,, bool hasClaimedExcess,) = LegionFixedPriceSale(payable(legionSaleInstance)).investorPositions(investor2);

        assertEq(hasClaimedExcess, true);
        assertEq(MockBidToken(bidToken).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if the sale has not ended
     */
    function test_claimExcessCapital_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasNotEnded.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if sale is canceled.
     */
    function test_claimExcessCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital with incorrect merkle proof.
     */
    function test_claimExcessCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612707);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.CannotClaimExcessCapital.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if excess capital has already been claimed.
     */
    function test_claimExcessCapital_revertsIfExcessCapitalAlreadyReturned() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if no capital has been pledged.
     */
    function test_claimExcessCapital_revertsIfNoCapitalPledged() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);

        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishExcessCapitalResults(excessCapitalMerkleRootMalicious);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NoCapitalPledged.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionFixedPriceSale(legionSaleInstance).claimExcessCapital(6000 * 1e6, excessClaimProofInvestor5);
    }

    /* ========== CLAIM TOKEN ALLOCATION TESTS ========== */

    /**
     * @dev Test Case: Successfully distribute tokens after the sale, lockup period, and sale results have been published.
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        (, bool hasSettled,, address vestingAddress) =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPositions(investor2);

        assertEq(hasSettled, true);
        assertEq(MockAskToken(askToken).balanceOf(vestingAddress), 1000 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens before the lockup period is over.
     */
    function test_claimTokenAllocation_revertsIfLockupPeriodHasNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute more tokens than allocated.
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(2000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if investor has not pledged capital
     */
    function test_claimTokenAllocation_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor5 = new bytes32[](2);

        claimProofInvestor5[0] = bytes32(0xab15bf46a7b5a0fed230b26afe212fe8303fc537eb6e007370eabeaf0b869955);
        claimProofInvestor5[1] = bytes32(0xbe76d3200dd468b9512ea8ec335a3149f5aa5d0d975c3de3cd37afb777182abc);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            distributeMerkleRootMalicious, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NoCapitalPledged.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(4000 * 1e18, claimProofInvestor5);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if already distributed once
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyDistributed() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens when the sale is canceled
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if sale results have not been published
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if `askToken` is not available
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /* ========== RELEASE VESTED TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully release tokens from investor vesting contract after vesting distribution.
     */
    function test_releaseTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).releaseTokens();

        // Assert
        assertEq(MockAskToken(askToken).balanceOf(investor2), 114186960933536276);
    }

    /**
     * @dev Test Case: Attempt to release tokens if an investor does not have deployed vesting contract
     */
    function test_releaseTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSaleInstance, 4100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).releaseTokens();
    }

    /**
     * @dev Test Case: Attempt to release tokens if `askToken` is not available
     */
    function test_releaseTokens_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleConfig(
            ILegionFixedPriceSale.FixedPriceSaleConfig({
                prefundPeriodSeconds: PREFUND_PERIOD_SECONDS,
                prefundAllocationPeriodSeconds: PREFUND_ALLOCATION_PERIOD_SECONDS,
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                tokenPrice: TOKEN_PRICE,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createFixedPriceSale(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).releaseTokens();
    }
}
