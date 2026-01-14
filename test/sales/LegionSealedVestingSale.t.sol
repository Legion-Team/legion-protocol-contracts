// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721 } from "@solady/src/tokens/ERC721.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { ECIES, Point } from "../../src/lib/ECIES.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionSealedVestingSale } from "../../src/interfaces/sales/ILegionSealedVestingSale.sol";
import { ILegionSealedVestingSaleFactory } from "../../src/interfaces/factories/ILegionSealedVestingSaleFactory.sol";
import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionSealedVestingSale } from "../../src/sales/LegionSealedVestingSale.sol";
import { LegionSealedVestingSaleFactory } from "../../src/factories/LegionSealedVestingSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Test
 * @author Legion
 * @notice Test suite for the LegionSealedVestingSale contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionSealedVestingSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Holds initialization parameters for the pre-liquid sale
     */
    struct SaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams;
        ILegionSealedVestingSale.PreLiquidSaleInitializationParams sealedVestingOpenApplicationSaleInitParams;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Vesting configuration for investors
     * @dev Defines linear vesting schedule parameters for token allocations
     */
    ILegionVestingManager.LegionInvestorVestingConfig public investorVestingConfig;

    /**
     * @notice Test configuration for sale-related tests
     * @dev Stores the sale configuration used across test cases
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Template instance of the LegionSealedVestingSale contract for cloning
     * @dev Used as the base for creating new sale instances
     */
    LegionSealedVestingSale public preLiquidOpenApplicationSaleTemplate;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating pre-liquid sale V2 instances
     * @dev Deploys new instances of LegionSealedVestingSale
     */
    LegionSealedVestingSaleFactory public legionSaleFactory;

    /**
     * @notice Factory contract for creating vesting instances
     * @dev Deploys vesting contracts for token allocations
     */
    LegionVestingFactory public legionVestingFactory;

    /**
     * @notice Mock token used as the bidding currency
     * @dev Represents the token used for investments (e.g., USDC)
     */
    MockERC20 public bidToken;

    /**
     * @notice Address of the deployed pre-liquid sale instance
     * @dev Points to the active sale contract being tested
     */
    address public legionSaleInstance;

    /**
     * @notice Address representing an AWS broadcaster
     * @dev Set to 0x10, used in LegionBouncer configuration
     */
    address public awsBroadcaster = address(0x10);

    /**
     * @notice Address representing a Legion EOA
     * @dev Set to 0x01, used in LegionBouncer configuration
     */
    address public legionEOA = address(0x01);

    /**
     * @notice Address of the LegionBouncer contract
     * @dev Initialized with legionEOA and awsBroadcaster for access control
     */
    address public legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /**
     * @notice Address representing the vesting contract controller, set to 0x99
     */
    address public legionVestingController = address(0x99);

    /**
     * @notice Address representing the project admin
     * @dev Set to 0x02, manages sale operations
     */
    address public projectAdmin = address(0x02);

    /**
     * @notice Address representing investor 1
     * @dev Set to 0x03, participates in the sale
     */
    address public investor1 = address(0x03);

    /**
     * @notice Address representing investor 2
     * @dev Set to 0x04, participates in the sale
     */
    address public investor2 = address(0x04);

    /**
     * @notice Address representing investor 3
     * @dev Set to 0x05, participates in the sale
     */
    address public investor3 = address(0x05);

    /**
     * @notice Address representing investor 4
     * @dev Set to 0x06, participates in the sale
     */
    address public investor4 = address(0x06);

    /**
     * @notice Address representing investor 5
     * @dev Set to 0x07, used for testing non-invested scenarios
     */
    address public investor5 = address(0x07);

    /**
     * @notice Address representing the referrer fee receiver
     * @dev Set to 0x08, receives referrer fees
     */
    address public referrerFeeReceiver = address(0x08);

    /**
     * @notice Address representing the Legion fee receiver
     * @dev Set to 0x09, receives Legion fees
     */
    address public legionFeeReceiver = address(0x09);

    /// @notice Signature for investor1's transfer to investor2
    bytes signatureInv1Transfer;

    /// @notice Signature for investor2's transfer to investor1
    bytes signatureInv2Transfer;

    /**
     * @notice Signature for investor1's investment
     * @dev Generated for authenticating investor1's investment action
     */
    bytes public signatureInv1;

    /**
     * @notice Signature for investor2's investment
     * @dev Generated for authenticating investor2's investment action
     */
    bytes public signatureInv2;

    /**
     * @notice Signature for investor3's investment
     * @dev Generated for authenticating investor3's investment action
     */
    bytes public signatureInv3;

    /**
     * @notice Signature for investor4's investment
     * @dev Generated for authenticating investor4's investment action
     */
    bytes public signatureInv4;

    /**
     * @notice Invalid signature for testing invalid cases
     * @dev Generated by a non-Legion signer for testing signature validation
     */
    bytes public invalidSignature;

    /**
     * @notice Private key for the Legion signer
     * @dev Set to 1234, used for generating valid signatures
     */
    uint256 public legionSignerPK = 1234;

    /**
     * @notice Private key for a non-Legion signer
     * @dev Set to 12_345, used for generating invalid signatures
     */
    uint256 public nonLegionSignerPK = 12_345;

    /// @notice Signatures for excess withdrawal tests
    bytes signatureInv1ExcessWithdrawal;
    bytes signatureInv2ExcessWithdrawal;
    bytes signatureInv3ExcessWithdrawal;

    /**
     * @notice Sealed bid data for investors and invalid cases
     * @dev Encoded encrypted amounts, salts, and public keys for testing
     */
    bytes public sealedVestingDataInvestor1;
    bytes public sealedVestingDataInvestor2;
    bytes public sealedVestingDataInvestor3;
    bytes public sealedVestingDataInvestor4;
    bytes public invalidSealedVestingData;
    bytes public invalidSealedVestingData1;

    /**
     * @notice Encrypted bid amounts for investors
     * @dev Stored for use in decryption tests
     */
    uint256 public encryptedVestingInvestor1;
    uint256 public encryptedVestingInvestor2;
    uint256 public encryptedVestingInvestor3;
    uint256 public encryptedVestingInvestor4;

    /**
     * @notice Private key for encryption/decryption
     * @dev Set to 69, used to generate PUBLIC_KEY
     */
    uint256 public PRIVATE_KEY = 69;

    /**
     * @notice Fixed salt value for bid encryption
     */
    uint256 public FIXED_SALT = 420;

    /**
     * @notice Public keys for encryption/decryption
     * @dev PUBLIC_KEY is valid, INVALID_PUBLIC_KEY and INVALID_PUBLIC_KEY_1 are for testing invalid scenarios
     */
    Point public PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY);
    Point public INVALID_PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY + 1);
    Point public INVALID_PUBLIC_KEY_1 = Point(1, 1);

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     * @dev Initializes sale template, factory, vesting factory, registry, tokens, and vesting config
     */
    function setUp() public {
        preLiquidOpenApplicationSaleTemplate = new LegionSealedVestingSale();
        legionSaleFactory = new LegionSealedVestingSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        prepareLegionAddressRegistry();
        prepareInvestorVestingConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs common setup operations for most tests
     * @dev Creates sale instance, mints tokens, approves spending, and prepares signatures
     */
    function prepareStandardTestSetup() public {
        prepareSealedVestingData();
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
    }

    /**
     * @notice Performs common setup operations for tests requiring project tokens
     * @dev Creates sale instance, mints all tokens, approves spending, and prepares signatures
     */
    function prepareFullTestSetup() public {
        prepareSealedVestingData();
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
    }

    /**
     * @notice Performs setup for transfer position tests
     * @dev Creates sale instance, mints tokens, approves spending, and prepares both investment and transfer signatures
     */
    function prepareTransferTestSetup() public {
        prepareSealedVestingData();
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();
    }

    /**
     * @notice Performs setup for excess withdrawal tests
     * @dev Creates sale instance, mints tokens, approves spending, invests from all investors, and prepares excess
     * withdrawal signatures
     */
    function prepareExcessWithdrawalTestSetup() public {
        prepareSealedVestingData();
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();
        prepareExcessWithdrawalSignatures();
    }

    /**
     * @notice Sets the pre-liquid sale configuration parameters
     * @dev Updates the testConfig with provided initialization parameters
     * @param _saleInitParams Parameters for initializing a pre-liquid sale
     */
    function setSaleParams(
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedVestingSale.PreLiquidSaleInitializationParams memory _sealedVestingOpenApplicationSaleInitParams
    )
        public
    {
        testConfig.saleInitParams = ILegionAbstractSale.LegionSaleInitializationParams({
            refundPeriodSeconds: _saleInitParams.refundPeriodSeconds,
            legionFeeOnCapitalRaisedBps: _saleInitParams.legionFeeOnCapitalRaisedBps,
            referrerFeeOnCapitalRaisedBps: _saleInitParams.referrerFeeOnCapitalRaisedBps,
            minimumInvestAmount: _saleInitParams.minimumInvestAmount,
            legionOpsFeeInWei: _saleInitParams.legionOpsFeeInWei,
            bidTokenDecimals: _saleInitParams.bidTokenDecimals,
            bidToken: _saleInitParams.bidToken,
            projectAdmin: _saleInitParams.projectAdmin,
            addressRegistry: _saleInitParams.addressRegistry,
            referrerFeeReceiver: _saleInitParams.referrerFeeReceiver
        });

        testConfig.sealedVestingOpenApplicationSaleInitParams = ILegionSealedVestingSale
            .PreLiquidSaleInitializationParams({ publicKey: _sealedVestingOpenApplicationSaleInitParams.publicKey });
    }

    /**
     * @notice Creates and initializes a LegionSealedVestingSale instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleParams(
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
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Mints tokens to investors and approves the sale instance contract
     * @dev Prepares bid tokens for investors to participate in the sale
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.startPrank(legionBouncer);

        MockERC20(bidToken).mint(investor1, 1000 * 1e6);
        MockERC20(bidToken).mint(investor2, 2000 * 1e6);
        MockERC20(bidToken).mint(investor3, 3000 * 1e6);
        MockERC20(bidToken).mint(investor4, 4000 * 1e6);

        vm.stopPrank();

        vm.prank(investor1);
        MockERC20(bidToken).approve(legionSaleInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockERC20(bidToken).approve(legionSaleInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockERC20(bidToken).approve(legionSaleInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockERC20(bidToken).approve(legionSaleInstance, 4000 * 1e6);
    }

    /**
     * @notice Prepares investor signatures for authentication
     * @dev Generates signatures for investment actions using Legion and non-Legion signers
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
                legionSaleInstance,
                block.chainid,
                uint256(1000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest2 = keccak256(
            abi.encodePacked(
                investor2,
                legionSaleInstance,
                block.chainid,
                uint256(2000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest3 = keccak256(
            abi.encodePacked(
                investor3,
                legionSaleInstance,
                block.chainid,
                uint256(3000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest4 = keccak256(
            abi.encodePacked(
                investor4,
                legionSaleInstance,
                block.chainid,
                uint256(4000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();

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
     * @notice Prepares transfer signatures for investor1 and investor2
     * @dev Generates signatures for transferring positions between investors
     */
    function prepareTransferSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1Transfer = keccak256(
            abi.encodePacked(investor1, investor2, uint256(1), investor1, legionSaleInstance, block.chainid)
        ).toEthSignedMessageHash();

        bytes32 digest2Transfer = keccak256(
            abi.encodePacked(investor1, investor2, uint256(2), investor1, legionSaleInstance, block.chainid)
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1Transfer);
        signatureInv1Transfer = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2Transfer);
        signatureInv2Transfer = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Prepares excess withdrawal signatures
     * @dev Generates signatures for withdrawing excess capital between investors
     */
    function prepareExcessWithdrawalSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1ExcessWithdrawal = keccak256(
            abi.encodePacked(
                investor1,
                legionSaleInstance,
                block.chainid,
                uint256(0),
                ILegionAbstractSale.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest2ExcessWithdrawal = keccak256(
            abi.encodePacked(
                investor2,
                legionSaleInstance,
                block.chainid,
                uint256(1000 * 1e6),
                ILegionAbstractSale.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest3ExcessWithdrawal =
            keccak256(abi.encodePacked(investor3, legionSaleInstance, block.chainid)).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1ExcessWithdrawal);
        signatureInv1ExcessWithdrawal = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2ExcessWithdrawal);
        signatureInv2ExcessWithdrawal = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest3ExcessWithdrawal);
        signatureInv3ExcessWithdrawal = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Invests capital from all investors
     * @dev Simulates investments from all predefined investors
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            2000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor2, signatureInv2
        );

        vm.prank(investor3);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            3000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor3, signatureInv3
        );

        vm.prank(investor4);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            4000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor4, signatureInv4
        );
    }

    /**
     * @notice Prepares sealed vesting data for investors
     * @dev Encrypts vesting durations (6, 9, 12 and 18 months in seconds) and encodes with salts and public keys
     */
    function prepareSealedVestingData() public {
        (uint256 encryptedAmountOut1,) = ECIES.encrypt(
            15_552_000, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor1, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut2,) = ECIES.encrypt(
            23_328_000, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor2, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut3,) = ECIES.encrypt(
            31_104_000, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor3, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut4,) = ECIES.encrypt(
            46_656_000, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor4, FIXED_SALT)))
        );

        sealedVestingDataInvestor1 = abi.encode(encryptedAmountOut1, PUBLIC_KEY);
        sealedVestingDataInvestor2 = abi.encode(encryptedAmountOut2, PUBLIC_KEY);
        sealedVestingDataInvestor3 = abi.encode(encryptedAmountOut3, PUBLIC_KEY);
        sealedVestingDataInvestor4 = abi.encode(encryptedAmountOut4, PUBLIC_KEY);

        invalidSealedVestingData = abi.encode(encryptedAmountOut1, INVALID_PUBLIC_KEY);
        invalidSealedVestingData1 = abi.encode(encryptedAmountOut1, INVALID_PUBLIC_KEY_1);

        encryptedVestingInvestor1 = encryptedAmountOut1;
        encryptedVestingInvestor2 = encryptedAmountOut2;
        encryptedVestingInvestor3 = encryptedAmountOut3;
        encryptedVestingInvestor4 = encryptedAmountOut4;
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
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_CONTROLLER"), legionVestingController);

        vm.stopPrank();
    }

    /**
     * @notice Prepares the investor vesting configuration
     * @dev Sets up a linear vesting schedule with predefined parameters
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            0, 31_536_000, 3600, ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 0, 1e17
        );
    }

    /**
     * @notice Retrieves the sale start time
     * @dev Queries the sale configuration for the start timestamp
     * @return uint256 The start time of the sale
     */
    function startTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedVestingSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Queries the sale configuration for the end timestamp
     * @return uint256 The end time of the sale
     */
    function endTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedVestingSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund end time
     * @dev Queries the sale configuration for the refund end timestamp
     * @return uint256 The end time of the refund period
     */
    function refundEndTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedVestingSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Queries the sale status for the total capital raised
     * @return saleTotalCapitalRaised The total capital raised in the sale
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionAbstractSale.LegionSaleStatus memory _saleStatusDetails =
            LegionSealedVestingSale(payable(legionSaleInstance)).saleStatus();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful deployment with valid parameters
     * @dev Verifies vesting configuration setup post-creation
     */
    function test_createPreLiquidSale_successfullyDeployedWithValidParameters() public {
        // Arrange & Act
        prepareCreateLegionPreLiquidSale();

        ILegionSealedVestingSale.PreLiquidSaleConfiguration memory _preLiquidSaleConfig =
            LegionSealedVestingSale(payable(legionSaleInstance)).preLiquidSaleConfiguration();

        // Expect
        assertEq(_preLiquidSaleConfig.refundPeriodSeconds, 2 weeks);
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
        LegionSealedVestingSale(payable(legionSaleInstance)).initialize(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address fixedPriceSaleImplementation = legionSaleFactory.i_sealedVestingOpenApplicationSaleTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedVestingSale(payable(fixedPriceSaleImplementation)).initialize(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedVestingSale(preLiquidOpenApplicationSaleTemplate).initialize(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                minimumInvestAmount: 1e6,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(0),
                projectAdmin: address(0),
                addressRegistry: address(0),
                referrerFeeReceiver: address(0)
            }),
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when key parameters are zero
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 0,
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
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with an overly long period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when periods exceed limits
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 2 weeks + 1,
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
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with an overly short period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when periods are below minimum
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 1 hours - 1,
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
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /**
     * @notice Tests that creating a sale with an invalid public key configuration reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when public key is invalid
     */
    function test_createPreLiquidSale_revertsWithInvalidPublicKey() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 1 hours,
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
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: INVALID_PUBLIC_KEY_1 })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by Legion admin
     * @dev Expects Paused event emission when paused by legionBouncer
     */
    function test_pause_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).pause();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).unpause();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).unpause();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful investment within the active sale period
     * @dev Expects CapitalInvested event emission with correct parameters
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.CapitalInvested(1000 * 1e6, encryptedVestingInvestor1, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale is no longer active
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with a different public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when using INVALID_PUBLIC_KEY
     */
    function test_invest_revertsIfDifferentPublicKey() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), invalidSealedVestingData, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when using INVALID_PUBLIC_KEY_1
     */
    function test_invest_revertsIfInvalidPublicKey() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), invalidSealedVestingData1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an amount less than the minimum reverts
     * @dev Expects LegionSale__InvalidInvestAmount revert when investment is below threshold
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1 * 1e5, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale has been canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert when signature is not valid
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, invalidSignature
        );
    }

    /**
     * @notice Tests that investing after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor has already refunded
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert when excess capital is claimed
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareStandardTestSetup();
        prepareInvestedCapitalFromAllInvestors();
        prepareExcessWithdrawalSignatures();

        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            2000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor2, signatureInv2
        );
    }

    /**
     * @notice Tests that investing after the deadline reverts
     * @dev Expects LegionSale__SignatureExpired revert when deadline has passed
     */
    function test_invest_revertsIfSignatureDeadlineHasExpired() public {
        // Arrange
        prepareStandardTestSetup();

        vm.warp(102);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SignatureExpired.selector, 102, 101));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(1000 * 1e6, 101, sealedVestingDataInvestor1, signatureInv1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        UPDATE SEALED VESTING OPTION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful updating of sealed vesting option
     * @dev Expects SealedVestingOptionUpdated event emission with correct parameters
     */
    function test_updateSealedVestingOption_successfullyEmitsSealedVestingOptionUpdated() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.SealedVestingOptionUpdated(investor1, encryptedVestingInvestor2);

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).updateSealedVestingOption(sealedVestingDataInvestor2);
    }

    /**
     * @notice Tests that updating sealed vesting option after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale is no longer active
     */
    function test_updateSealedVestingOption_revertsIfSaleHasEnded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).updateSealedVestingOption(sealedVestingDataInvestor1);
    }

    /**
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale has been canceled
     */
    function test_updateSealedVestingOption_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).updateSealedVestingOption(sealedVestingDataInvestor1);
    }

    /**
     * @notice Tests that investing after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor has already refunded
     */
    function test_updateSealedVestingOption_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).updateSealedVestingOption(sealedVestingDataInvestor1);
    }

    /**
     * @notice Tests that investing after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert when excess capital is claimed
     */
    function test_updateSealedVestingOption_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareStandardTestSetup();
        prepareInvestedCapitalFromAllInvestors();
        prepareExcessWithdrawalSignatures();

        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).updateSealedVestingOption(sealedVestingDataInvestor2);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               END SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful ending of the sale by project admin
     * @dev Expects SaleEnded event emission with correct timestamp
     */
    function test_end_successfullyEmitsSaleEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.SaleEnded();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending the sale by non-project or non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegionOrProject revert when called by nonProjectOrLegionAdmin
     */
    function testFuzz_end_revertsIfNotCalledByLegionOrProject(address nonProjectOrLegionAdmin) public {
        // Arrange
        vm.assume(nonProjectOrLegionAdmin != projectAdmin && nonProjectOrLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegionOrProject.selector));

        // Act
        vm.prank(nonProjectOrLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending the sale when paused reverts
     * @dev Expects EnforcedPause revert when sale is paused
     */
    function test_end_revertsIfSaleIsPaused() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending the sale when canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is already canceled
     */
    function test_end_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending an already ended sale reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale is already ended
     */
    function test_end_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of capital raised and accepted capital merkle root
     * @dev Expects CapitalRaisedPublished event emission with correct parameters
     */
    function test_publishRaisedCapital_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishRaisedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_publishRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised before sale ends reverts
     * @dev Expects LegionSale__SaleHasNotEnded revert when sale is still active
     */
    function test_publishRaisedCapital_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasNotEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is active
     */
    function test_publishRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised twice reverts
     * @dev Expects LegionSale__CapitalRaisedAlreadyPublished revert when already published
     */
    function test_publishRaisedCapital_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
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
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Tests that emergency withdrawal by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                REFUND TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful refund within the refund period
     * @dev Expects CapitalRefunded event emission and verifies investor balance
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefunded(1000 * 1e6, investor1);

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();

        uint256 investor1Balance = MockERC20(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @notice Tests that refunding after the refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when refund period has expired
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsOver.selector, (refundEndTime() + 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert when no investment exists
     */
    function test_refund_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor has already refunded
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful cancellation of the sale by project admin before results are published
     * @dev Expects SaleCanceled event emission
     */
    function test_cancel_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests successful cancellation and capital return by project admin
     * @dev Verifies SaleCanceled event and capital return to sale contract
     */
    function test_cancel_successfullyCancelsIfCapitalToReturn() public {
        // Arrange
        prepareFullTestSetup();

        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();

        vm.startPrank(projectAdmin);
        MockERC20(bidToken).mint(projectAdmin, 350 * 1e6);
        MockERC20(bidToken).approve(legionSaleInstance, 10_000 * 1e6);
        vm.stopPrank();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        assertEq(bidToken.balanceOf(legionSaleInstance), 10_000 * 1e6);
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is already canceled
     */
    function test_cancel_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling a sale by non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by investor1
     */
    function test_cancel_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).cancel();
    }

    /*//////////////////////////////////////////////////////////////////////////
                  WITHDRAW INVESTED CAPITAL IF CANCELED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of invested capital after cancellation
     * @dev Expects CapitalRefundedAfterCancel event and verifies investor balance
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        assertEq(MockERC20(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing invested capital when sale is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when sale is still active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing invested capital with no investment reverts
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when no capital is invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital after cancellation reverts if the investor has already withdrawn
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor1 tries to withdraw again
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfInvestorHasAlreadyWithdrawnInvestedCapital() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedVestingDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedVestingSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    REVEAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of sale results by the Legion admin
     * @dev Verifies that the SaleResultsPublished event is emitted with correct parameters
     */
    function test_reveal_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.Revealed(PRIVATE_KEY, FIXED_SALT);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_reveal_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_reveal_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results without locking cancel reverts
     * @dev Expects LegionSale__CancelNotLocked revert when initializeReveal is not called
     */
    function test_reveal_revertsIfCancelNotLocked() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelNotLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that republishing results reverts
     * @dev Expects LegionSale__PrivateKeyAlreadyPublished revert after initial publication
     */
    function test_reveal_revertsIfPrivateKeyAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing with an invalid private key reverts
     * @dev Expects LegionSale__InvalidBidPrivateKey revert when using an incorrect private key
     */
    function test_reveal_revertsIfInvalidPrivateKey() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPrivateKey.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY - 1, FIXED_SALT);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INITIALIZE REVEAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization of publish sale results by the Legion admin
     * @dev Verifies that the PublishSaleResultsInitialized event is emitted
     */
    function test_initializeReveal_successfullyEmitsPublishSaleResultsInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionSealedVestingSale.RevealInitialized();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_initializeReveal_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that reinitializing publish sale results reverts
     * @dev Expects LegionSale__CancelLocked revert after initial initialization
     */
    function test_initializeReveal_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_initializeReveal_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_initializeReveal_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of raised capital by the project admin after results are published
     * @dev Verifies that withdrawing capital post-sale emits the CapitalWithdrawn event and correctly transfers funds
     * to the project admin, accounting for Legion (250 bps) and referrer (100 bps) fees.
     */
    function test_withdrawRaisedCapital_successfullyEmitsCapitalWithdraw() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();

        // Expect
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - capitalRaised() * 250 / 10_000 - capitalRaised() * 100 / 10_000
        );
    }

    /**
     * @notice Tests successful withdrawal of raised capital when the Legion fee is zero
     * @dev Ensures withdrawal works correctly with a 0 bps Legion fee, emitting CapitalWithdrawn and transferring funds
     * minus only the referrer fee (100 bps).
     */
    function test_withdrawRaisedCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                minimumInvestAmount: 1e6,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedVestingSale.PreLiquidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createSealedVestingOpenApplicationSale(
            testConfig.saleInitParams, testConfig.sealedVestingOpenApplicationSaleInitParams
        );

        prepareSealedVestingData();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();

        // Expect
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @notice Tests that withdrawing capital by a non-project admin reverts
     * @dev Ensures only the project admin can withdraw capital, expecting a LegionSale__NotCalledByProject revert.
     */
    function testFuzz_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionPreLiquidSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before results are published reverts
     * @dev Ensures capital cannot be withdrawn without publishing results, expecting a
     * LegionSale__CapitalRaisedNotPublished
     * revert.
     */
    function test_withdrawRaisedCapital_revertsIfCapitalRaisedNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before the refund period ends reverts
     * @dev Ensures withdrawal is blocked during the refund period, expecting a LegionSale__RefundPeriodIsNotOver
     * revert.
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital after the sale is canceled reverts
     * @dev Ensures withdrawal is blocked when the sale is canceled, expecting a LegionSale__SaleIsCanceled revert.
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Ensures capital can only be withdrawn once, expecting a LegionSale__CapitalAlreadyWithdrawn revert on the
     * second
     * attempt.
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                    WITHDRAW EXCESS INVESTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of excess invested capital by an investor after the sale ends
     * @dev Verifies that investor2 can withdraw 1000 USDC excess capital using a valid Merkle proof, updates their
     * position, and transfers the correct amount of bid tokens back to them.
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapital() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.warp(endTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionSealedVestingSale(payable(legionSaleInstance)).investorPosition(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true);
        assertEq(MockERC20(bidToken).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing excess capital reverts if the sale is canceled
     * @dev Ensures excess withdrawal is blocked when the sale is canceled, expecting a LegionSale__SaleIsCanceled
     * revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedVestingSale(legionSaleInstance).cancel();

        vm.warp(endTime() + 1);

        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert with invalid signature
     */
    function test_withdrawExcessInvestedCapital_revertsWithInvalidSignature() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv3ExcessWithdrawal)
        );

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv3ExcessWithdrawal
        );
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Ensures an investor cannot claim excess capital more than once, expecting an
     * LegionSale__AlreadyClaimedExcess revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.warp(endTime() + 1);

        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with no prior investment reverts
     * @dev Ensures an investor who didn’t invest cannot claim excess, expecting a
     * LegionSale__InvestorPositionDoesNotExist revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareExcessWithdrawalSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1ExcessWithdrawal)
        );

        // Act
        vm.prank(investor5);
        ILegionSealedVestingSale(legionSaleInstance).withdrawExcessInvestedCapital(
            6000 * 1e6, signatureInv1ExcessWithdrawal
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        DECRYPT SEALED VESTING OPTION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful decryption of sealed vesting options after private key publication
     * @dev Verifies that encrypted bids are correctly decrypted to expected values
     */
    function test_decryptSealedVestingOption_successfullyDecryptSealedBid() public {
        // Arrange
        prepareSealedVestingData();
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).initializeReveal();

        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);

        // Act
        uint256 decryptedVestingInvestor1 = ILegionSealedVestingSale(legionSaleInstance).decryptSealedVestingOption(
            encryptedVestingInvestor1, investor1
        );
        uint256 decryptedVestingInvestor2 = ILegionSealedVestingSale(legionSaleInstance).decryptSealedVestingOption(
            encryptedVestingInvestor2, investor2
        );
        uint256 decryptedVestingInvestor3 = ILegionSealedVestingSale(legionSaleInstance).decryptSealedVestingOption(
            encryptedVestingInvestor3, investor3
        );
        uint256 decryptedVestingInvestor4 = ILegionSealedVestingSale(legionSaleInstance).decryptSealedVestingOption(
            encryptedVestingInvestor4, investor4
        );

        // Expect
        assertEq(decryptedVestingInvestor1, 15_552_000, "Investor1 bid should decrypt to 1000 LFG");
        assertEq(decryptedVestingInvestor2, 23_328_000, "Investor2 bid should decrypt to 2000 LFG");
        assertEq(decryptedVestingInvestor3, 31_104_000, "Investor3 bid should decrypt to 3000 LFG");
        assertEq(decryptedVestingInvestor4, 46_656_000, "Investor4 bid should decrypt to 4000 LFG");
    }

    /**
     * @notice Tests that decrypting sealed vesting options before private key publication reverts
     * @dev Expects LegionSale__PrivateKeyNotPublished revert when attempting decryption without published key
     */
    function test_decryptSealedVestingOption_revertsIfPrivateKeyNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyNotPublished.selector));

        // Act
        ILegionSealedVestingSale(legionSaleInstance).decryptSealedVestingOption(encryptedVestingInvestor1, investor1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful synchronization of Legion addresses by a Legion admin
     * @dev Verifies that syncing updates the contract’s Legion addresses from the registry
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.LegionAddressesSynced(legionBouncer, vm.addr(legionSignerPK), address(1));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedVestingSale(legionSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by a non-Legion admin reverts
     * @dev Ensures only Legion admins can sync addresses, expecting a revert when called by non-Legion admin.
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedVestingSale(legionSaleInstance).syncLegionAddresses();
    }
}
