// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Test, console2, Vm} from "forge-std/Test.sol";

import {ECIES, Point} from "../src/lib/ECIES.sol";
import {ILegionBaseSale} from "../src/interfaces/ILegionBaseSale.sol";
import {ILegionSealedBidAuction} from "../src/interfaces/ILegionSealedBidAuction.sol";
import {ILegionSaleFactory} from "../src/interfaces/ILegionSaleFactory.sol";
import {LegionAddressRegistry} from "../src/LegionAddressRegistry.sol";
import {LegionAccessControl} from "../src/LegionAccessControl.sol";
import {LegionSealedBidAuction} from "../src/LegionSealedBidAuction.sol";
import {LegionSaleFactory} from "../src/LegionSaleFactory.sol";
import {LegionVestingFactory} from "../src/LegionVestingFactory.sol";
import {MockAskToken} from "../src/mocks/MockAskToken.sol";
import {MockBidToken} from "../src/mocks/MockBidToken.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract LegionSealedBidAuctionTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    ILegionSealedBidAuction.SealedBidAuctionConfig saleConfig;

    LegionSealedBidAuction sealedBidAuctionTemplate;

    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockBidToken bidToken;
    MockAskToken askToken;

    address legionSealedBidAuctionInstance;

    address legionEOA = address(0x01);
    address awsBroadcaster = address(0x10);
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

    bytes sealedBidDataInvestor1;
    bytes sealedBidDataInvestor2;
    bytes sealedBidDataInvestor3;
    bytes sealedBidDataInvestor4;

    bytes invalidSealedBidData;
    bytes invalidSealedBidData1;

    uint256 encryptedAmountInvestort1;
    uint256 encryptedAmountInvestort2;
    uint256 encryptedAmountInvestort3;
    uint256 encryptedAmountInvestort4;

    uint256 constant SALE_PERIOD_SECONDS = 3600;
    uint256 constant REFUND_PERIOD_SECONDS = 1209600;
    uint256 constant LOCKUP_PERIOD_SECONDS = 3456000;
    uint256 constant VESTING_DURATION_SECONDS = 31536000;
    uint256 constant VESTING_CLIFF_DURATION_SECONDS = 3600;
    uint256 constant LEGION_FEE_CAPITAL_RAISED_BPS = 250;
    uint256 constant LEGION_FEE_TOKENS_SOLD_BPS = 250;
    uint256 constant MINIMUM_PLEDGE_AMOUNT = 1 * 1e6;
    uint256 constant PRIVATE_KEY = 69;

    uint256 constant ONE_HOUR = 3600;
    uint256 constant TWO_WEEKS = 1209600;
    uint256 constant THREE_MONTHS = 7776000;
    uint256 constant SIX_MONTHS = 15780000;

    Point PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY);

    Point INVALID_PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY + 1);

    Point INVALID_PUBLIC_KEY_1 = Point(1, 1);

    function setUp() public {
        sealedBidAuctionTemplate = new LegionSealedBidAuction();
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockBidToken("USD Coin", "USDC");
        askToken = new MockAskToken("LFG Coin", "LFG");
        prepareLegionAddressRegistry();
    }

    /**
     * @dev Helper method to set the sealed bid auction configuration
     */
    function setSaleConfig(ILegionSealedBidAuction.SealedBidAuctionConfig memory _saleConfig) public {
        saleConfig = ILegionSealedBidAuction.SealedBidAuctionConfig({
            salePeriodSeconds: _saleConfig.salePeriodSeconds,
            refundPeriodSeconds: _saleConfig.refundPeriodSeconds,
            lockupPeriodSeconds: _saleConfig.lockupPeriodSeconds,
            vestingDurationSeconds: _saleConfig.vestingDurationSeconds,
            vestingCliffDurationSeconds: _saleConfig.vestingCliffDurationSeconds,
            legionFeeOnCapitalRaisedBps: _saleConfig.legionFeeOnCapitalRaisedBps,
            legionFeeOnTokensSoldBps: _saleConfig.legionFeeOnTokensSoldBps,
            minimumPledgeAmount: _saleConfig.minimumPledgeAmount,
            publicKey: _saleConfig.publicKey,
            bidToken: _saleConfig.bidToken,
            askToken: _saleConfig.askToken,
            projectAdmin: _saleConfig.projectAdmin,
            addressRegistry: _saleConfig.addressRegistry
        });
    }

    /**
     * @dev Helper method to create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /**
     * @dev Helper method to mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.prank(legionBouncer);
        MockBidToken(bidToken).mint(investor1, 1000 * 1e6);
        MockBidToken(bidToken).mint(investor2, 2000 * 1e6);
        MockBidToken(bidToken).mint(investor3, 3000 * 1e6);
        MockBidToken(bidToken).mint(investor4, 4000 * 1e6);

        vm.prank(investor1);
        MockBidToken(bidToken).approve(legionSealedBidAuctionInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockBidToken(bidToken).approve(legionSealedBidAuctionInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockBidToken(bidToken).approve(legionSealedBidAuctionInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockBidToken(bidToken).approve(legionSealedBidAuctionInstance, 4000 * 1e6);
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

        bytes32 digest1 = keccak256(abi.encodePacked(investor1, legionSealedBidAuctionInstance, block.chainid))
            .toEthSignedMessageHash();
        bytes32 digest2 = keccak256(abi.encodePacked(investor2, legionSealedBidAuctionInstance, block.chainid))
            .toEthSignedMessageHash();
        bytes32 digest3 = keccak256(abi.encodePacked(investor3, legionSealedBidAuctionInstance, block.chainid))
            .toEthSignedMessageHash();
        bytes32 digest4 = keccak256(abi.encodePacked(investor4, legionSealedBidAuctionInstance, block.chainid))
            .toEthSignedMessageHash();

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

        bytes32 digest5 = keccak256(abi.encodePacked(investor1, legionSealedBidAuctionInstance, block.chainid))
            .toEthSignedMessageHash();

        (v, r, s) = vm.sign(nonLegionSignerPK, digest5);
        invalidSignature = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @dev Helper method to pledge capital from all investors
     */
    function preparePledgedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            2000 * 1e6, sealedBidDataInvestor2, signatureInv2
        );

        vm.prank(investor3);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            3000 * 1e6, sealedBidDataInvestor3, signatureInv3
        );

        vm.prank(investor4);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            4000 * 1e6, sealedBidDataInvestor4, signatureInv4
        );
    }

    /**
     * @dev Helper method to prepare sealed bid data for investor
     */
    function prepareSealedBidData() public {
        (uint256 encryptedAmountOut1,) =
            ECIES.encrypt(1000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor1)));
        (uint256 encryptedAmountOut2,) =
            ECIES.encrypt(2000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor2)));
        (uint256 encryptedAmountOut3,) =
            ECIES.encrypt(3000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor3)));
        (uint256 encryptedAmountOut4,) =
            ECIES.encrypt(4000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor4)));

        sealedBidDataInvestor1 = abi.encode(encryptedAmountOut1, uint256(uint160(investor1)), PUBLIC_KEY);
        sealedBidDataInvestor2 = abi.encode(encryptedAmountOut2, uint256(uint160(investor2)), PUBLIC_KEY);
        sealedBidDataInvestor3 = abi.encode(encryptedAmountOut3, uint256(uint160(investor3)), PUBLIC_KEY);
        sealedBidDataInvestor4 = abi.encode(encryptedAmountOut4, uint256(uint160(investor4)), PUBLIC_KEY);

        invalidSealedBidData = abi.encode(encryptedAmountOut1, uint256(uint160(investor1)), INVALID_PUBLIC_KEY);
        invalidSealedBidData1 = abi.encode(encryptedAmountOut1, uint256(uint160(investor1)), INVALID_PUBLIC_KEY_1);

        encryptedAmountInvestort1 = encryptedAmountOut1;
        encryptedAmountInvestort2 = encryptedAmountOut2;
        encryptedAmountInvestort3 = encryptedAmountOut3;
        encryptedAmountInvestort4 = encryptedAmountOut4;
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
     * @dev Helper method to encrypt bid
     */
    function encryptBid(uint256 amount, uint256 salt) public view returns (uint256 _encryptedAmountOut) {
        (_encryptedAmountOut,) = ECIES.encrypt(amount, PUBLIC_KEY, PRIVATE_KEY, salt);
    }

    /**
     * @dev Helper method to get sale start time
     */
    function startTime() public view returns (uint256) {
        ILegionSealedBidAuction.SealedBidAuctionStatus memory saleStatus =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleStatus();
        return saleStatus.startTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function endTime() public view returns (uint256) {
        ILegionSealedBidAuction.SealedBidAuctionStatus memory saleStatus =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleStatus();
        return saleStatus.endTime;
    }

    /**
     * @dev Helper method to get the refund end time
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSealedBidAuction.SealedBidAuctionStatus memory saleStatus =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleStatus();
        return saleStatus.refundEndTime;
    }

    /**
     * @dev Helper method to get the lockup end time
     */
    function lockupEndTime() public view returns (uint256) {
        ILegionSealedBidAuction.SealedBidAuctionStatus memory saleStatus =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleStatus();
        return saleStatus.lockupEndTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function capitalRaised() public view returns (uint256) {
        ILegionSealedBidAuction.SealedBidAuctionStatus memory saleStatus =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleStatus();
        return saleStatus.totalCapitalRaised;
    }
    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize the contract with valid parameters.
     */
    function test_createSealedBidAuction_successfullyDeployedWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();
        LegionSealedBidAuction.SealedBidAuctionConfig memory sealedBidAuctionConfig =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).saleConfiguration();

        // Assert
        assertEq(sealedBidAuctionConfig.salePeriodSeconds, SALE_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfig.refundPeriodSeconds, REFUND_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfig.lockupPeriodSeconds, LOCKUP_PERIOD_SECONDS);
        assertEq(sealedBidAuctionConfig.vestingDurationSeconds, VESTING_DURATION_SECONDS);
        assertEq(sealedBidAuctionConfig.vestingCliffDurationSeconds, VESTING_CLIFF_DURATION_SECONDS);
        assertEq(sealedBidAuctionConfig.legionFeeOnCapitalRaisedBps, LEGION_FEE_CAPITAL_RAISED_BPS);
        assertEq(sealedBidAuctionConfig.legionFeeOnTokensSoldBps, LEGION_FEE_TOKENS_SOLD_BPS);

        assertEq(sealedBidAuctionConfig.bidToken, address(bidToken));
        assertEq(sealedBidAuctionConfig.askToken, address(askToken));
        assertEq(sealedBidAuctionConfig.projectAdmin, projectAdmin);
        assertEq(sealedBidAuctionConfig.addressRegistry, address(legionAddressRegistry));
    }

    /**
     * @dev Test Case: Attempt to re-initialize the contract
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert();

        // Act
        LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionSealedBidAuction` implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        address sealedBidAuctionImplementation = legionSaleFactory.sealedBidAuctionTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuction(payable(sealedBidAuctionImplementation)).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionSealedBidAuction` template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuction(sealedBidAuctionTemplate).initialize(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
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
        legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                vestingDurationSeconds: 0,
                vestingCliffDurationSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                publicKey: Point(0, 0),
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
        legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too long)
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: THREE_MONTHS + 1,
                refundPeriodSeconds: TWO_WEEKS + 1,
                lockupPeriodSeconds: SIX_MONTHS + 1,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
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
        legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too short)
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: ONE_HOUR - 1,
                refundPeriodSeconds: ONE_HOUR - 1,
                lockupPeriodSeconds: ONE_HOUR - 1,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
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
        legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /**
     * @dev Test Case: Initialize with invalid public key
     */
    function test_createSealedBidAuction_revertsWithInvalidPublicKey() public {
        // Arrange
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: INVALID_PUBLIC_KEY_1,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.InvalidBidPublicKey.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(saleConfig);
    }

    /* ========== PLEDGE CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully pledge capital within the active sale period.
     */
    function test_pledgeCapital_successfullyEmitsCapitalPledged() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuction.CapitalPledged(
            1000 * 1e6, encryptedAmountInvestort1, uint256(uint160(investor1)), investor1, startTime() + 1
        );

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital after the sale has ended
     */
    function test_pledgeCapital_revertsIfSaleHasEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital with different public key
     */
    function test_pledgeCapital_revertsIfDifferentPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital with invalid public key
     */
    function test_pledgeCapital_revertsIfInvalidPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, invalidSealedBidData1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital with invalid public key
     */
    function test_pledgeCapital_revertsIfInvalidSalt() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        (uint256 encryptedAmountOut2,) =
            ECIES.encrypt(1000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor2)));
        invalidSealedBidData = abi.encode(encryptedAmountOut2, uint256(uint160(investor2)), INVALID_PUBLIC_KEY);

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.InvalidSalt.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e16, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital with amount less than the minimum amount
     */
    function test_pledgeCapital_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidPledgeAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1 * 1e5, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital when the sale is canceled
     */
    function test_pledgeCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e16, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Pledge capital with invalid signature
     */
    function test_pledgeCapital_revertsIfInvalidSignature() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, invalidSignature
        );
    }

    /* ========== EMERGENCY WITHDRAW TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw funds through emergencyWithdraw method.
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @dev Test Case: Attempt to withdraw by address other than the Legion admin.
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
    }

    /* ========== REQUEST REFUND TESTS ========== */

    /**
     * @dev Test Case: Successfully request a refund within the refund period.
     */
    function test_requestRefund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalRefunded(1000 * 1e6, investor1);

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).requestRefund();

        uint256 investor1Balance = MockBidToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @dev Test Case: Request a refund after the refund period has ended
     */
    function test_requestRefund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund when the sale is canceled and within the refund period
     */
    function test_requestRefund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund with no capital pledged
     */
    function test_requestRefund_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).requestRefund();
    }

    /**
     * @dev Test Case: Request a refund before the sale has ended
     */
    function test_requestRefund_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(block.timestamp + 30 minutes);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasNotEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).requestRefund();
        uint256 investor1Balance = MockBidToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 0);
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the ongoing sale by the project admin before results are published
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(block.timestamp + 7 days);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if it has already been canceled
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if results are published
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Assert
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale by non project admin
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Assert
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime());

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale if cancel is locked
     */
    function test_cancelSale_revertsIfCancelIsLocked() public {
        // Assert
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime());

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.CancelLocked.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();
    }

    /* ========== CLAIM BACK CANCELED SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully claim back capital if the sale has been canceled.
     */
    function test_claimBackCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimBackCapitalIfCanceled();

        // Assert
        assertEq(MockBidToken(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to claim back capital when the sale is not canceled
     */
    function test_claimBackCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(block.timestamp + 7 days);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimBackCapitalIfCanceled();
    }

    /**
     * @dev Test Case: Attempt to claim back capital when no capital was pledged
     */
    function test_claimBackCapitalIfCanceled_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 7 days);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidClaimAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimBackCapitalIfCanceled();
    }

    /* ========== PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish sale results by the Legion admin.
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuction.SaleResultsPublished(claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if the sale has been canceled.
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1 weeks);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results by non-Legion admin.
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if cancel is not locked.
     */
    function test_publishSaleResults_revertsIfCancelNotLocked() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.CancelNotLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if private key is already published.
     */
    function test_publishSaleResults_revertsIfPrivateKeyAlreadyPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.PrivateKeyAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if private key is invalid.
     */
    function test_publishSaleResults_revertsIfInvalidPrivateKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.InvalidBidPrivateKey.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY - 1
        );
    }

    /* ========== INITIALIZE PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize publish sale results by the Legion admin.
     */
    function test_initializePublishSaleResults_successfullyEmitsPublishSaleResultsInitialized() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuction.PublishSaleResultsInitialized();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if the sale is canceled.
     */
    function test_initializePublishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if cancel is locked.
     */
    function test_initializePublishSaleResults_revertsIfCancelIsLocked() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.CancelLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if cancel is locked.
     */
    function test_initializePublishSaleResults_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if refund period is not over.
     */
    function test_initializePublishSaleResults_revertsIfRefunPeriodIsNotOver() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /* ========== PUBLISH EXCESS CAPITAL RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish excess capital results by the Legion admin.
     */
    function test_publishExcessCapitalResults_successfullyEmitsExcessCapitalResultsPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.ExcessCapitalResultsPublished(excessCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Attempt to publish excess capital results by non-Legion admin.
     */
    function test_publishExcessCapitalResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish results when excess capital results are already set
     */
    function test_publishExcessCapitalResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                ILegionBaseSale.ExcessCapitalResultsAlreadyPublished.selector, excessCapitalMerkleRoot
            )
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish results before the sale is over
     */
    function test_publishExcessCapitalResults_revertsIfSaleIsNotOver() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleHasNotEnded.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Publish excess capital results if the sale has been canceled
     */
    function test_publishExcessCapitalResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1 weeks);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
    }

    /* ========== SUPPLY TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully supply tokens for distribution by the project admin
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Supply tokens with incorrect fee amount
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4090 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4090 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 90 * 1e18);
    }

    /**
     * @dev Test Case: Successfully supply tokens with Legion fee 0
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: 0,
                minimumPledgeAmount: 0,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);

        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4000 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4000 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 0);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 0);
    }

    /**
     * @dev Test Case: Attempt to supply tokens by non-admin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(nonProjectAdmin);
        MockAskToken(askToken).mint(nonProjectAdmin, 10250 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 10250 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(10000 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens when the sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens with incorrect amount
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 10240 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 10240 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.InvalidTokenAmountSupplied.selector, 9990 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(9990 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if sale results are not published
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 10250 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 10250 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(10000 * 1e18, 250 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens twice
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 8200 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 8200 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if `askToken` is unavailable
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
    }

    /* ========== CANCEL EXPIRED SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the sale if the lockup period is over and no tokens have been supplied
     */
    function test_cancelExpiredSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when tokens have been supplied
     */
    function test_cancelExpiredSale_revertsIfTokensSupplied() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 40100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 40100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensAlreadySupplied.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the sale has already been canceled
     */
    function test_cancelExpiredSale_revertsIfAlreadyCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the lockup period is not over
     */
    function test_cancelExpiredSale_revertsIfLockupPeriodNotOver() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when `askToken` is unavailable and results are published
     */
    function test_cancelExpiredSale_revertsIfAskTokenUnavailableAndResultsPublished() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Cancel when `askToken` is unavailable and results are not published
     */
    function test_cancelExpiredSale_successfullyCancelIfAskTokenUnavailableAndResultsNotPublished() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /* ========== WITHDRAW CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw capital by the project admin after results are published and tokens are supplied.
     */
    function test_withdrawCapital_successfullyEmitsCapitalWithdraw() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Successfully withdraw capital if the Legion fee is 0
     */
    function test_withdrawCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);

        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdrawal by someone other than the project admin
     */
    function test_withdrawCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        vm.stopPrank();

        vm.expectEmit();
        emit ILegionBaseSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18);
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdrawal when tokens have not been supplied
     */
    function test_withdrawCapital_revertsIfNoTokensSupplied() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when sale results have not been published
     */
    function test_withdrawCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the refund period has not ended
     */
    function test_withdrawCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled by the project
     */
    function test_withdrawCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled after expiration
     */
    function test_withdrawCapital_revertsIfExpiredSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /**
     * @dev Test Case: Attempt to withdraw raised capital after capital already withdrawn
     */
    function test_withdrawCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.startPrank(legionBouncer);

        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
        
        vm.stopPrank();

        vm.startPrank(projectAdmin);

        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();   

        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
    }

    /* ========== CLAIM EXCESS CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully claim excess capital to investor after the sale has ended.
     */
    function test_claimExcessCapital_successfullyTransfersBackExcessCapitalTokens() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Assert

        (,, bool hasClaimedExcess,) =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).investorPositions(investor2);

        assertEq(hasClaimedExcess, true);
        assertEq(MockBidToken(bidToken).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if the sale has not ended
     */
    function test_claimExcessCapital_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
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
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if sale is canceled.
     */
    function test_claimExcessCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital with incorrect merkle proof.
     */
    function test_claimExcessCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0xe6ec166fcb24e8b45dbf44e2137a36706ae07288095a733f7439bb2f81a94052);
        excessClaimProofInvestor2[1] = bytes32(0x61c19f281f94212e62b60d017ca806d139d4f0da454abbc73e9533e0d99f398c);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.CannotClaimExcessCapital.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if excess capital has already been claimed.
     */
    function test_claimExcessCapital_revertsIfExcessCapitalAlreadyReturned() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(excessCapitalMerkleRoot);
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if no capital has been pledged.
     */
    function test_claimExcessCapital_revertsIfNoCapitalPledged() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);

        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishExcessCapitalResults(
            excessCapitalMerkleRootMalicious
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NoCapitalPledged.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimExcessCapital(
            6000 * 1e6, excessClaimProofInvestor5
        );
    }

    /* ========== CLAIM TOKEN ALLOCATION TESTS ========== */

    /**
     * @dev Test Case: Successfully distribute tokens after the sale, lockup period, and sale results have been published.
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        (, bool hasSettled,, address vestingAddress) =
            LegionSealedBidAuction(payable(legionSealedBidAuctionInstance)).investorPositions(investor2);

        assertEq(hasSettled, true);
        assertEq(MockAskToken(askToken).balanceOf(vestingAddress), 1000 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens before the lockup period is over.
     */
    function test_claimTokenAllocation_revertsIfLockupPeriodHasNotEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute more tokens than allocated.
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(2000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if investor has not pledged capital
     */
    function test_claimTokenAllocation_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor5 = new bytes32[](2);

        claimProofInvestor5[0] = bytes32(0xab15bf46a7b5a0fed230b26afe212fe8303fc537eb6e007370eabeaf0b869955);
        claimProofInvestor5[1] = bytes32(0xbe76d3200dd468b9512ea8ec335a3149f5aa5d0d975c3de3cd37afb777182abc);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            distributeMerkleRootMalicious, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NoCapitalPledged.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(4000 * 1e18, claimProofInvestor5);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if already distributed once
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyDistributed() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens when the sale is canceled
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if sale results have not been published
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
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
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if `askToken` is not available
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);
    }

    /* ========== RELEASE VESTED TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully release tokens from investor vesting contract after vesting distribution.
     */
    function test_releaseTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).claimTokenAllocation(1000 * 1e18, claimProofInvestor2);

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).releaseTokens();

        // Assert
        assertEq(MockAskToken(askToken).balanceOf(investor2), 114186960933536276);
    }

    /**
     * @dev Test Case: Attempt to release tokens if an investor does not have deployed vesting contract
     */
    function test_releaseTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.startPrank(projectAdmin);
        MockAskToken(askToken).mint(projectAdmin, 4100 * 1e18);
        MockAskToken(askToken).approve(legionSealedBidAuctionInstance, 4100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).withdrawCapital();
        vm.stopPrank();

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).releaseTokens();
    }

    /**
     * @dev Test Case: Attempt to release tokens if `askToken` is not available
     */
    function test_releaseTokens_revertsIfAskTokenNotAvailable() public {
        // Arrange
        prepareSealedBidData();
        setSaleConfig(
            ILegionSealedBidAuction.SealedBidAuctionConfig({
                salePeriodSeconds: SALE_PERIOD_SECONDS,
                refundPeriodSeconds: REFUND_PERIOD_SECONDS,
                lockupPeriodSeconds: LOCKUP_PERIOD_SECONDS,
                vestingDurationSeconds: VESTING_DURATION_SECONDS,
                vestingCliffDurationSeconds: VESTING_CLIFF_DURATION_SECONDS,
                legionFeeOnCapitalRaisedBps: LEGION_FEE_CAPITAL_RAISED_BPS,
                legionFeeOnTokensSoldBps: LEGION_FEE_TOKENS_SOLD_BPS,
                minimumPledgeAmount: MINIMUM_PLEDGE_AMOUNT,
                publicKey: PUBLIC_KEY,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(saleConfig);
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        preparePledgedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + VESTING_CLIFF_DURATION_SECONDS + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).releaseTokens();
    }

    /* ========== DECRYPT SEALED BID TESTS ========== */

    /**
     * @dev Test Case: Successfully decrypt sealed bid after results are published
     */
    function test_decryptSealedBid_successfullyDecryptSealedBid() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(investor2);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            2000 * 1e6, sealedBidDataInvestor2, signatureInv2
        );

        vm.prank(investor3);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            3000 * 1e6, sealedBidDataInvestor3, signatureInv3
        );

        vm.prank(investor4);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            4000 * 1e6, sealedBidDataInvestor4, signatureInv4
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Act
        uint256 decryptedBidInvestor1 = ILegionSealedBidAuction(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort1, uint256(uint160(investor1))
        );
        uint256 decryptedBidInvestor2 = ILegionSealedBidAuction(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort2, uint256(uint160(investor2))
        );
        uint256 decryptedBidInvestor3 = ILegionSealedBidAuction(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort3, uint256(uint160(investor3))
        );
        uint256 decryptedBidInvestor4 = ILegionSealedBidAuction(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort4, uint256(uint160(investor4))
        );

        // Assert
        assertEq(decryptedBidInvestor1, 1000 * 1e18);
        assertEq(decryptedBidInvestor2, 2000 * 1e18);
        assertEq(decryptedBidInvestor3, 3000 * 1e18);
        assertEq(decryptedBidInvestor4, 4000 * 1e18);
    }

    /**
     * @dev Test Case: Try to decrypt sealed bid before private key is published
     */
    function test_decryptSealedBid_revertsIfPrivateKeyNotPublished() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).pledgeCapital(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionSealedBidAuction.PrivateKeyNotPublished.selector));

        // Act
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort1, uint256(uint160(investor1))
        );
    }

    /* ========== SYNC LEGION ADDRESSES TESTS ========== */

    /**
     * @dev Test Case: Successfully sync Legion addresses from `LegionAddressRegistry.sol` by Legion
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert
        vm.expectEmit();
        emit ILegionBaseSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).syncLegionAddresses();
    }

    /**
     * @dev Test Case: Attempt to sync Legion addresses from `LegionAddressRegistry.sol` by non Legion admin
     */
    function test_syncLegionAddresses_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert
        vm.expectRevert(abi.encodeWithSelector(ILegionBaseSale.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuction(legionSealedBidAuctionInstance).syncLegionAddresses();
    }
}
