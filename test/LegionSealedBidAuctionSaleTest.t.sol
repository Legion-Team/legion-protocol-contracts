// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console2, Vm } from "forge-std/Test.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";
import { Constants } from "../src/utils/Constants.sol";
import { ILegionSale } from "../src/interfaces/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/ILegionSealedBidAuctionSale.sol";
import { ILegionSaleFactory } from "../src/interfaces/ILegionSaleFactory.sol";
import { LegionAddressRegistry } from "../src/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/LegionBouncer.sol";
import { LegionSealedBidAuctionSale } from "../src/LegionSealedBidAuctionSale.sol";
import { LegionSaleFactory } from "../src/LegionSaleFactory.sol";
import { LegionVestingFactory } from "../src/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

contract LegionSealedBidAuctionSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    struct SaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams;
        ILegionSale.LegionVestingInitializationParams vestingInitParams;
    }

    SaleTestConfig testConfig;

    LegionSealedBidAuctionSale sealedBidAuctionTemplate;

    LegionAddressRegistry legionAddressRegistry;
    LegionSaleFactory legionSaleFactory;
    LegionVestingFactory legionVestingFactory;

    MockToken bidToken;
    MockToken askToken;

    address legionSealedBidAuctionInstance;
    address legionEOA = address(0x01);
    address awsBroadcaster = address(0x10);
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

    uint256 PRIVATE_KEY = 69;

    Point PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY);
    Point INVALID_PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY + 1);
    Point INVALID_PUBLIC_KEY_1 = Point(1, 1);

    function setUp() public {
        sealedBidAuctionTemplate = new LegionSealedBidAuctionSale();
        legionSaleFactory = new LegionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
    }

    /**
     * @dev Helper method to set the sealed bid auction params
     */
    function setSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory _sealedBidAuctionSaleInitParams,
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

        testConfig.sealedBidAuctionSaleInitParams = ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({
            publicKey: _sealedBidAuctionSaleInitParams.publicKey
        });

        testConfig.vestingInitParams = ILegionSale.LegionVestingInitializationParams({
            vestingDurationSeconds: _vestingInitParams.vestingDurationSeconds,
            vestingCliffDurationSeconds: _vestingInitParams.vestingCliffDurationSeconds,
            tokenAllocationOnTGERate: _vestingInitParams.tokenAllocationOnTGERate
        });
    }

    /**
     * @dev Helper method to create a sealed bid auction
     */
    function prepareCreateLegionSealedBidAuction() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 100_000_000_000_000_000
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Helper method to mint tokens to investors and approve the sale instance contract
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.prank(legionBouncer);
        MockToken(bidToken).mint(investor1, 1000 * 1e6);
        MockToken(bidToken).mint(investor2, 2000 * 1e6);
        MockToken(bidToken).mint(investor3, 3000 * 1e6);
        MockToken(bidToken).mint(investor4, 4000 * 1e6);

        vm.prank(investor1);
        MockToken(bidToken).approve(legionSealedBidAuctionInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockToken(bidToken).approve(legionSealedBidAuctionInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockToken(bidToken).approve(legionSealedBidAuctionInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockToken(bidToken).approve(legionSealedBidAuctionInstance, 4000 * 1e6);
    }

    /**
     * @dev Helper method to mint tokens to the project and approve the sale instance contract
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);

        MockToken(askToken).mint(projectAdmin, 10_000 * 1e18);
        MockToken(askToken).approve(legionSealedBidAuctionInstance, 10_000 * 1e18);

        vm.stopPrank();
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
     * @dev Helper method to invest capital from all investors
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            2000 * 1e6, sealedBidDataInvestor2, signatureInv2
        );

        vm.prank(investor3);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            3000 * 1e6, sealedBidDataInvestor3, signatureInv3
        );

        vm.prank(investor4);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
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
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function endTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @dev Helper method to get the refund end time
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @dev Helper method to get the lockup end time
     */
    function lockupEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.lockupEndTime;
    }

    /**
     * @dev Helper method to get sale end time
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionSale.LegionSaleStatus memory _saleStatusDetails =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleStatusDetails();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /* ========== INITIALIZATION TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize the contract with valid parameters.
     */
    function test_createSealedBidAuction_successfullyDeployedWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionSealedBidAuction();

        ILegionSealedBidAuctionSale.SealedBidAuctionSaleConfiguration memory _sealedBidAuctionSaleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).sealedBidAuctionSaleConfiguration();

        ILegionSale.LegionVestingConfiguration memory _vestingConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).vestingConfiguration();

        // Assert
        assertEq(_sealedBidAuctionSaleConfig.publicKey.x, PUBLIC_KEY.x);
        assertEq(_sealedBidAuctionSaleConfig.publicKey.y, PUBLIC_KEY.y);

        assertEq(_vestingConfig.vestingDurationSeconds, Constants.ONE_YEAR);
        assertEq(_vestingConfig.vestingCliffDurationSeconds, Constants.ONE_HOUR);
    }

    /**
     * @dev Test Case: Successfully initialize the contract when lockup period is less than refund time.
     */
    function test_createSealedBidAuction_successfullyDeployIfLockupPeriodLessThanRefundTime() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();

        // Assert
        assertEq(_saleConfig.lockupEndTime, _saleConfig.refundEndTime);
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
        LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionSealedBidAuctionSale` implementation contract
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address sealedBidAuctionImplementation = legionSaleFactory.sealedBidAuctionTemplate();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuctionSale(payable(sealedBidAuctionImplementation)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Attempt to initialize the `LegionSealedBidAuctionSale` template contract
     */
    function test_initialize_revertInitializeTemplate() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuctionSale(sealedBidAuctionTemplate).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Initialize with zero address configurations
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
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
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Initialize with zero value configurations
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                lockupPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                referrerFeeOnTokensSoldBps: 0,
                minimumInvestAmount: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
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
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too long)
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooLong() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
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
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Initialize with invalid period configurations (too short)
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooShort() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
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
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test case: Attempt to initialize vesting configuration with invalid values.
     */
    function test_createSealedBidAuction_revertsWithInvalidVestingConfig() public {
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.TEN_YEARS,
                vestingCliffDurationSeconds: Constants.TEN_YEARS + 1,
                tokenAllocationOnTGERate: 1e18 + 1
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /**
     * @dev Test Case: Initialize with invalid public key
     */
    function test_createSealedBidAuction_revertsWithInvalidPublicKey() public {
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
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: INVALID_PUBLIC_KEY_1 }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBidPublicKey.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );
    }

    /* ========== PAUSE TESTS ========== */

    /**
     * @dev Test Case: Successfully pause the sale
     */
    function test_pauseSale_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();
    }

    /**
     * @dev Test Case: Attempt to pause sale by non-legion admin
     */
    function test_pauseSale_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();
    }

    /**
     * @dev Test Case: Successfully unpause the sale
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();

        // Assert
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).unpauseSale();
    }

    /**
     * @dev Test Case: Attempt to unpause the sale by non-legion admin
     */
    function test_unpauseSale_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).unpauseSale();
    }

    /* ========== INVEST CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully inveest capital within the active sale period.
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuctionSale.CapitalInvested(
            1000 * 1e6, encryptedAmountInvestort1, uint256(uint160(investor1)), investor1, startTime() + 1
        );

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital after the sale has ended
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital with different public key
     */
    function test_invest_revertsIfDifferentPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital with invalid public key
     */
    function test_invest_revertsIfInvalidPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, invalidSealedBidData1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital with invalid public key
     */
    function test_invest_revertsIfInvalidSalt() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        (uint256 encryptedAmountOut2,) =
            ECIES.encrypt(1000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(uint160(investor2)));
        invalidSealedBidData = abi.encode(encryptedAmountOut2, uint256(uint160(investor2)), PUBLIC_KEY);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSalt.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e16, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital with amount less than the minimum amount
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1 * 1e5, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital when the sale is canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e16, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @dev Test Case: Attempt to invest capital with invalid signature
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, invalidSignature
        );
    }

    /**
     * @dev Test Case: Attempt to invest when the investor has refunded
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
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
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        // Assert
        vm.expectEmit();
        emit ILegionSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @dev Test Case: Attempt to withdraw by address other than the Legion admin.
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
    }

    /* ========== REFUND TESTS ========== */

    /**
     * @dev Test Case: Successfully refund within the refund period.
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionSale.CapitalRefunded(1000 * 1e6, investor1);

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();

        uint256 investor1Balance = MockToken(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to refund after the refund period has ended
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @dev Test Case: Attempt to refund when the sale is canceled and within the refund period
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @dev Test Case: Attempt to refund with no capital invested
     */
    function test_refund_revertsIfNoCapitalIsInvested() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @dev Test Case: Attempt ot refund if already refunded
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /* ========== CANCEL SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the ongoing sale by the project admin before results are published
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if it has already been canceled
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel the sale if results are published
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Assert
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale by non project admin
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Assert
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @dev Test Case: Attempt to cancel a sale if cancel is locked
     */
    function test_cancelSale_revertsIfCancelIsLocked() public {
        // Assert
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CancelLocked.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /* ========== WITHDRAW INVESTED CAPITAL IF CANCELED TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw invested capital if the sale has been canceled.
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();

        // Assert
        assertEq(MockToken(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to withdraw invested capital when the sale is not canceled
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @dev Test Case: Attempt to claim back capital when no capital was invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();
    }

    /* ========== PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully publish sale results by the Legion admin.
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuctionSale.SaleResultsPublished(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if the sale has been canceled.
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results by non-Legion admin.
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if cancel is not locked.
     */
    function test_publishSaleResults_revertsIfCancelNotLocked() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(Errors.CancelNotLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if private key is already published.
     */
    function test_publishSaleResults_revertsIfPrivateKeyAlreadyPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.PrivateKeyAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @dev Test Case: Attempt to publish results if private key is invalid.
     */
    function test_publishSaleResults_revertsIfInvalidPrivateKey() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidBidPrivateKey.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY - 1
        );
    }

    /* ========== INITIALIZE PUBLISH SALE RESULTS TESTS ========== */

    /**
     * @dev Test Case: Successfully initialize publish sale results by the Legion admin.
     */
    function test_initializePublishSaleResults_successfullyEmitsPublishSaleResultsInitialized() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSealedBidAuctionSale.PublishSaleResultsInitialized();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if the sale is canceled.
     */
    function test_initializePublishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if cancel is locked.
     */
    function test_initializePublishSaleResults_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CancelLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if cancel is locked.
     */
    function test_initializePublishSaleResults_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @dev Test Case: Attempt to initialize publish sale results if refund period is not over.
     */
    function test_initializePublishSaleResults_revertsIfRefunPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /* ========== SET ACCEPTED CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully sets accepted capital by the Legion admin.
     */
    function test_setAcceptedCapital_successfullyEmitsAcceptedCapitalSet() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Attempt to publish accepted capital by non-Legion admin.
     */
    function test_setAcceptedCapital_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1);

        // Arrange
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Attempt to set accepted capital if the sale has ended
     */
    function test_setAcceptedCapital_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @dev Test Case: Set accepteed capital if the sale has been canceled
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /* ========== SUPPLY TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully supply tokens for distribution by the project admin
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens with incorrect fee amount
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Successfully supply tokens with Legion fee 0
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: Constants.ONE_HOUR,
                refundPeriodSeconds: Constants.TWO_WEEKS,
                lockupPeriodSeconds: Constants.FORTY_DAYS,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens by non-admin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens when the sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens with incorrect amount
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 9990 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if sale results are not published
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens twice
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @dev Test Case: Attempt to supply tokens if `askToken` is unavailable
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /* ========== CANCEL EXPIRED SALE TESTS ========== */

    /**
     * @dev Test Case: Successfully cancel the sale if the lockup period is over and no tokens have been supplied
     */
    function test_cancelExpiredSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when tokens have been supplied
     */
    function test_cancelExpiredSale_revertsIfTokensSupplied() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the sale has already been canceled
     */
    function test_cancelExpiredSale_revertsIfAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when the lockup period is not over
     */
    function test_cancelExpiredSale_revertsIfLockupPeriodNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Attempt to cancel when `askToken` is unavailable and results are published
     */
    function test_cancelExpiredSale_revertsIfAskTokenUnavailableAndResultsPublished() public {
        // Arrange
        prepareSealedBidData();

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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /**
     * @dev Test Case: Cancel when `askToken` is unavailable and results are not published
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();
    }

    /* ========== WITHDRAW RAISED CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully withdraw capital by the project admin after results are published and tokens are
     * supplied.
     */
    function test_withdrawRaisedCapital_successfullyEmitsRaisedCapitalWithdrawn() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();

        // Assert
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - capitalRaised() * 250 / 10_000 - capitalRaised() * 100 / 10_000
        );
    }

    /**
     * @dev Test Case: Successfully withdraw capital if the Legion fee is 0
     */
    function test_withdrawRaisedCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();

        // Assert
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @dev Test Case: Attempt withdrawal by someone other than the project admin
     */
    function test_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt withdrawal when tokens have not been supplied
     */
    function test_withdrawRaisedCapital_revertsIfNoTokensSupplied() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when sale results have not been published
     */
    function test_withdrawRaisedCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the refund period has not ended
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled by the project
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt withdraw when the sale has been canceled after expiration
     */
    function test_withdrawRaisedCapital_revertsIfExpiredSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @dev Test Case: Attempt to withdraw raised capital after capital already withdrawn
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.startPrank(legionBouncer);

        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.stopPrank();

        vm.startPrank(projectAdmin);

        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();

        vm.stopPrank();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /* ========== WITHDRAW EXCESS INVESTED CAPITAL TESTS ========== */

    /**
     * @dev Test Case: Successfully claim excess capital to investor after the sale has ended.
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapitalTokens() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Assert
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true);
        assertEq(MockToken(bidToken).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if sale is canceled.
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital with incorrect merkle proof.
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0xe6ec166fcb24e8b45dbf44e2137a36706ae07288095a733f7439bb2f81a94052);
        excessClaimProofInvestor2[1] = bytes32(0x61c19f281f94212e62b60d017ca806d139d4f0da454abbc73e9533e0d99f398c);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.CannotWithdrawExcessInvestedCapital.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if excess capital has already been claimed.
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to claim excess capital if no capital has been invested.
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);

        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(excessCapitalMerkleRootMalicious);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            6000 * 1e6, excessClaimProofInvestor5
        );
    }

    /* ========== CLAIM TOKEN ALLOCATION TESTS ========== */

    /**
     * @dev Test Case: Successfully distribute tokens after the sale, lockup period, and sale results have been
     * published.
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );

        ILegionSale.InvestorPosition memory _investorPosition =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasSettled, true);
        assertEq(MockToken(askToken).balanceOf(_investorPosition.vestingAddress), 9000 * 1e17);
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
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() - 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.LockupPeriodIsNotOver.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );
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
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            2000 * 1e18, claimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if investor has not invested capital
     */
    function test_claimTokenAllocation_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory claimProofInvestor5 = new bytes32[](2);

        claimProofInvestor5[0] = bytes32(0xab15bf46a7b5a0fed230b26afe212fe8303fc537eb6e007370eabeaf0b869955);
        claimProofInvestor5[1] = bytes32(0xbe76d3200dd468b9512ea8ec335a3149f5aa5d0d975c3de3cd37afb777182abc);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            distributeMerkleRootMalicious, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            4000 * 1e18, claimProofInvestor5
        );
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if already distributed once
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyDistributed() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );
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

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(lockupEndTime() + 1);

        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelExpiredSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if sale results have not been published
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(lockupEndTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );
    }

    /**
     * @dev Test Case: Attempt to distribute tokens if `askToken` is not available
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );
    }

    /* ========== RELEASE VESTED TOKENS TESTS ========== */

    /**
     * @dev Test Case: Successfully release tokens from investor vesting contract after vesting distribution.
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);

        claimProofInvestor2[0] = bytes32(0xa840fc41b720079e7bce186d116e4412058ec6b29d3a5722a1f377be1e0d0992);
        claimProofInvestor2[1] = bytes32(0x78158beefdfe129d958b15ef9bd1674f0aa97f179110ab76222f24f31db73155);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(lockupEndTime() + 1);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, claimProofInvestor2
        );

        vm.warp(lockupEndTime() + Constants.ONE_HOUR + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();

        // Assert
        assertEq(MockToken(askToken).balanceOf(investor2), 100_102_768_264_840_182_648);
    }

    /**
     * @dev Test Case: Attempt to release tokens if an investor does not have deployed vesting contract
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();
    }

    /**
     * @dev Test Case: Attempt to release tokens if `askToken` is not available
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY }),
            ILegionSale.LegionVestingInitializationParams({
                vestingDurationSeconds: Constants.ONE_YEAR,
                vestingCliffDurationSeconds: Constants.ONE_HOUR,
                tokenAllocationOnTGERate: 0
            })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams, testConfig.vestingInitParams
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();
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
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Act
        uint256 decryptedBidInvestor1 = ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort1, uint256(uint160(investor1))
        );
        uint256 decryptedBidInvestor2 = ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort2, uint256(uint160(investor2))
        );
        uint256 decryptedBidInvestor3 = ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort3, uint256(uint160(investor3))
        );
        uint256 decryptedBidInvestor4 = ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
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
        prepareCreateLegionSealedBidAuction();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.PrivateKeyNotPublished.selector));

        // Act
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
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
        emit ILegionSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).syncLegionAddresses();
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
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).syncLegionAddresses();
    }
}
