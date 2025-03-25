// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

// External Libraries (alphabetically by library name)
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

// Project Libraries (alphabetically by library name)
import { Constants } from "../src/utils/Constants.sol";
import { ECIES, Point } from "../src/lib/ECIES.sol";
import { Errors } from "../src/utils/Errors.sol";

// Project Interfaces (alphabetically by interface name)
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../src/interfaces/sales/ILegionSealedBidAuctionSale.sol";
import { ILegionSealedBidAuctionSaleFactory } from "../src/interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";

// Project Contracts (alphabetically by contract name)
import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/access/LegionBouncer.sol";
import { LegionSealedBidAuctionSale } from "../src/sales/LegionSealedBidAuctionSale.sol";
import { LegionSealedBidAuctionSaleFactory } from "../src/factories/LegionSealedBidAuctionSaleFactory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Sealed Bid Auction Sale Test
 * @author Legion
 * @notice Test suite for the LegionSealedBidAuctionSale contract
 * @dev Inherits from Forge's Test contract and uses ECDSA and MessageHashUtils for signature handling
 */
contract LegionSealedBidAuctionSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Combines general sale params with sealed bid auction-specific params
     */
    struct SaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams; // General sale initialization params
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams; // Sealed
            // bid-specific params
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Vesting configuration for investors
     * @dev Defines the vesting schedule (linear, 1-year duration, 1-hour cliff, 10% initial release)
     */
    ILegionVestingManager.LegionInvestorVestingConfig public investorVestingConfig;

    /**
     * @notice Test configuration for sealed bid auction sale tests
     * @dev Stores the sale and auction-specific parameters
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Template instance of LegionSealedBidAuctionSale for factory deployment
     * @dev Used as the implementation contract for proxy deployments
     */
    LegionSealedBidAuctionSale public sealedBidAuctionTemplate;

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
     * @dev Represents USDC with 6 decimals
     */
    MockERC20 public bidToken;

    /**
     * @notice Mock token used as the sale token狂
     * @dev Represents LFG with 18 decimals
     */
    MockERC20 public askToken;

    /**
     * @notice Address of the deployed sealed bid auction sale instance
     * @dev Points to the active sale contract being tested
     */
    address public legionSealedBidAuctionInstance;

    /**
     * @notice Address representing a Legion EOA (external owned account)
     * @dev Set to 0x01, used in LegionBouncer configuration
     */
    address public legionEOA = address(0x01);

    /**
     * @notice Address representing an AWS broadcaster
     * @dev Set to 0x10, used in LegionBouncer configuration
     */
    address public awsBroadcaster = address(0x10);

    /**
     * @notice Address of the Legion bouncer contract (owner)
     * @dev Deployed with legionEOA and awsBroadcaster, controls factory and sale permissions
     */
    address public legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /**
     * @notice Address representing the project admin
     * @dev Set to 0x02, manages sale operations
     */
    address public projectAdmin = address(0x02);

    /**
     * @notice Addresses representing investors
     * @dev Set to 0x03 through 0x07 for testing investment scenarios
     */
    address public investor1 = address(0x03);
    address public investor2 = address(0x04);
    address public investor3 = address(0x05);
    address public investor4 = address(0x06);
    address public investor5 = address(0x07);

    /**
     * @notice Address receiving referrer fees
     * @dev Set to 0x08, receives fee portions from the sale
     */
    address public referrerFeeReceiver = address(0x08);

    /**
     * @notice Address receiving Legion fees
     * @dev Set to 0x09, receives fee portions from the sale
     */
    address public legionFeeReceiver = address(0x09);

    /**
     * @notice Signatures for investors 1-4 and an invalid signature
     * @dev Generated using legionSignerPK and nonLegionSignerPK for testing
     */
    bytes public signatureInv1;
    bytes public signatureInv2;
    bytes public signatureInv3;
    bytes public signatureInv4;
    bytes public invalidSignature;

    /**
     * @notice Private keys for Legion and non-Legion signers
     * @dev legionSignerPK (1234) for valid signatures, nonLegionSignerPK (12,345) for invalid ones
     */
    uint256 public legionSignerPK = 1234;
    uint256 public nonLegionSignerPK = 12_345;

    /**
     * @notice Merkle roots for various sale outcomes
     * @dev Precomputed roots for token claims, capital distribution, and malicious scenarios
     */
    bytes32 public claimTokensMerkleRoot = 0xf1497b122b0d3850e93c6e95a35163a5f7715ca75ec6a031abe96622b46a6ee2;
    bytes32 public acceptedCapitalMerkleRoot = 0x54c416133cce27821e67f6c475e59fcdafb30c065ea8feaac86970c532db0202;
    bytes32 public excessCapitalMerkleRootMalicious = 0x04169dca2cf842bea9fcf4df22c9372c6d6f04410bfa446585e287aa1c834974;

    /**
     * @notice Sealed bid data for investors and invalid cases
     * @dev Encoded encrypted amounts, salts, and public keys for testing
     */
    bytes public sealedBidDataInvestor1;
    bytes public sealedBidDataInvestor2;
    bytes public sealedBidDataInvestor3;
    bytes public sealedBidDataInvestor4;
    bytes public invalidSealedBidData;
    bytes public invalidSealedBidData1;

    /**
     * @notice Encrypted bid amounts for investors
     * @dev Stored for use in decryption tests
     */
    uint256 public encryptedAmountInvestort1;
    uint256 public encryptedAmountInvestort2;
    uint256 public encryptedAmountInvestort3;
    uint256 public encryptedAmountInvestort4;

    /**
     * @notice Private key for encryption/decryption
     * @dev Set to 69, used to generate PUBLIC_KEY
     */
    uint256 public PRIVATE_KEY = 69;

    /**
     * @notice Public keys for encryption/decryption
     * @dev PUBLIC_KEY is valid, INVALID_PUBLIC_KEY and INVALID_PUBLIC_KEY_1 are for testing invalid scenarios
     */
    Point public PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY);
    Point public INVALID_PUBLIC_KEY = ECIES.calcPubKey(Point(1, 2), PRIVATE_KEY + 1);
    Point public INVALID_PUBLIC_KEY_1 = Point(1, 1);

    /**
     * @notice Sets up the test environment by deploying contracts and configuring initial state
     * @dev Initializes template, factory, registry, tokens, and vesting config
     */
    function setUp() public {
        sealedBidAuctionTemplate = new LegionSealedBidAuctionSale();
        legionSaleFactory = new LegionSealedBidAuctionSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6); // 6 decimals
        askToken = new MockERC20("LFG Coin", "LFG", 18); // 18 decimals
        prepareLegionAddressRegistry();
        prepareInvestorVestingConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sale and sealed bid auction parameters
     * @dev Updates testConfig with provided initialization parameters
     * @param _saleInitParams General sale initialization parameters
     * @param _sealedBidAuctionSaleInitParams Sealed bid auction-specific initialization parameters
     */
    function setSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory _sealedBidAuctionSaleInitParams
    )
        public
    {
        testConfig.saleInitParams = ILegionSale.LegionSaleInitializationParams({
            salePeriodSeconds: _saleInitParams.salePeriodSeconds,
            refundPeriodSeconds: _saleInitParams.refundPeriodSeconds,
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
    }

    /**
     * @notice Creates a sealed bid auction sale instance
     * @dev Deploys a sale with default parameters (1-hour sale, 2-week refund, 2.5% Legion fee, etc.)
     */
    function prepareCreateLegionSealedBidAuction() public {
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Mints and approves bid tokens for investors
     * @dev Mints 1000-4000 USDC to investors 1-4 and approves the sale instance
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.prank(legionBouncer);
        MockERC20(bidToken).mint(investor1, 1000 * 1e6);
        MockERC20(bidToken).mint(investor2, 2000 * 1e6);
        MockERC20(bidToken).mint(investor3, 3000 * 1e6);
        MockERC20(bidToken).mint(investor4, 4000 * 1e6);

        vm.prank(investor1);
        MockERC20(bidToken).approve(legionSealedBidAuctionInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockERC20(bidToken).approve(legionSealedBidAuctionInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockERC20(bidToken).approve(legionSealedBidAuctionInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockERC20(bidToken).approve(legionSealedBidAuctionInstance, 4000 * 1e6);
    }

    /**
     * @notice Mints and approves ask tokens for the project admin
     * @dev Mints 10,000 LFG to projectAdmin and approves the sale instance
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);

        MockERC20(askToken).mint(projectAdmin, 10_000 * 1e18);
        MockERC20(askToken).approve(legionSealedBidAuctionInstance, 10_000 * 1e18);

        vm.stopPrank();
    }

    /**
     * @notice Generates signatures for investors
     * @dev Creates valid signatures with legionSignerPK and an invalid one with nonLegionSignerPK
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
     * @notice Simulates investments from all investors
     * @dev Investors 1-4 invest 1000-4000 USDC with their respective sealed bids and signatures
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
     * @notice Prepares sealed bid data for investors
     * @dev Encrypts bid amounts (1000-4000 LFG) and encodes with salts and public keys
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
     * @notice Configures the LegionAddressRegistry with required addresses
     * @dev Sets bouncer, signer, fee receiver, and vesting factory addresses
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
     * @notice Sets up the investor vesting configuration
     * @dev Configures a linear vesting schedule: 0 start, 1-year duration, 1-hour cliff, 10% initial release
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 31_536_000, 3600, 0, 0, 1e17
        );
    }

    /**
     * @notice Encrypts a bid amount with a given salt
     * @dev Uses ECIES to encrypt the amount with PUBLIC_KEY and PRIVATE_KEY
     * @param amount Amount to encrypt
     * @param salt Salt for encryption (typically investor address)
     * @return _encryptedAmountOut Encrypted bid amount
     */
    function encryptBid(uint256 amount, uint256 salt) public view returns (uint256 _encryptedAmountOut) {
        (_encryptedAmountOut,) = ECIES.encrypt(amount, PUBLIC_KEY, PRIVATE_KEY, salt);
    }

    /**
     * @notice Retrieves the sale start time
     * @dev Queries the sale configuration from the deployed instance
     * @return Start time of the sale
     */
    function startTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Queries the sale configuration from the deployed instance
     * @return End time of the sale
     */
    function endTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund end time
     * @dev Queries the sale configuration from the deployed instance
     * @return End time of the refund period
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Queries the sale status from the deployed instance
     * @return saleTotalCapitalRaised Total capital raised in bid tokens
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionSale.LegionSaleStatus memory _saleStatusDetails =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).saleStatusDetails();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful deployment of the contract with valid parameters
     * @dev Verifies that the sale instance is initialized with the correct public key and vesting factory
     */
    function test_createSealedBidAuction_successfullyDeployedWithValidParameters() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        ILegionSealedBidAuctionSale.SealedBidAuctionSaleConfiguration memory _sealedBidAuctionSaleConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).sealedBidAuctionSaleConfiguration();
        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).vestingConfiguration();

        // Expect
        assertEq(_sealedBidAuctionSaleConfig.publicKey.x, PUBLIC_KEY.x, "Public key x-coordinate mismatch");
        assertEq(_sealedBidAuctionSaleConfig.publicKey.y, PUBLIC_KEY.y, "Public key y-coordinate mismatch");
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory), "Vesting factory address mismatch");
    }

    /**
     * @notice Tests that reinitializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the implementation contract directly reverts
     * @dev Expects InvalidInitialization revert from Initializable due to template protection
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address sealedBidAuctionImplementation = legionSaleFactory.i_sealedBidAuctionTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuctionSale(payable(sealedBidAuctionImplementation)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the template contract directly reverts
     * @dev Expects InvalidInitialization revert from Initializable due to template protection
     */
    function test_initialize_revertInitializeTemplate() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidAuctionSale(sealedBidAuctionTemplate).initialize(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );
    }

    /**
     * @notice Tests that deployment with zero address configurations reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when key addresses are zero
     */
    function test_createSealedBidAuction_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
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
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams);
    }

    /**
     * @notice Tests that deployment with zero value configurations reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when key parameters are zero
     */
    function test_createSealedBidAuction_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams);
    }

    /**
     * @notice Tests that deployment with periods that are too long reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when sale or refund periods exceed limits
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 12 weeks + 1,
                refundPeriodSeconds: 2 weeks + 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams);
    }

    /**
     * @notice Tests that deployment with periods that are too short reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when sale or refund periods are below minimums
     */
    function test_createSealedBidAuction_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours - 1,
                refundPeriodSeconds: 1 hours - 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams);
    }

    /**
     * @notice Tests that deployment with an invalid public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when the public key is invalid (e.g., not on curve)
     */
    function test_createSealedBidAuction_revertsWithInvalidPublicKey() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: INVALID_PUBLIC_KEY_1 })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act:
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidAuction(testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by the Legion admin
     * @dev Verifies that the Paused event is emitted when paused by legionBouncer
     */
    function test_pauseSale_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();
    }

    /**
     * @notice Tests successful unpausing of the sale by the Legion admin
     * @dev Verifies that the Unpaused event is emitted after pausing and unpausing
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).unpauseSale();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pauseSale_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin after pausing
     */
    function testFuzz_unpauseSale_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).pauseSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).unpauseSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful investment within the active sale period
     * @dev Verifies that the CapitalInvested event is emitted with correct parameters
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Expect
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
     * @notice Tests that investing after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when called after endTime
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with a different public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when using INVALID_PUBLIC_KEY
     */
    function test_invest_revertsIfDifferentPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when using INVALID_PUBLIC_KEY_1
     */
    function test_invest_revertsIfInvalidPublicKey() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, invalidSealedBidData1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid salt reverts
     * @dev Expects LegionSale__InvalidSalt revert when salt does not match investor address
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSalt.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e16, invalidSealedBidData, signatureInv1
        );
    }

    /**
     * @notice Tests that investing less than the minimum amount reverts
     * @dev Expects LegionSale__InvalidInvestAmount revert when amount is below 1e6
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1 * 1e5, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e16, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert when using a signature from nonLegionSignerPK
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, invalidSignature
        );
    }

    /**
     * @notice Tests that reinvesting after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert after investor1 refunds their investment
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
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
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            1000 * 1e6, sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that reinvesting after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert after investor2 claims excess
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).invest(
            2000 * 1e6, sealedBidDataInvestor2, signatureInv2
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful emergency withdrawal by the Legion admin
     * @dev Verifies that the EmergencyWithdraw event is emitted and funds are withdrawn
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

        // Expect
        vm.expectEmit();
        emit ILegionSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                REFUND TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful refund within the refund period
     * @dev Verifies that the CapitalRefunded event is emitted and investor1's balance is restored
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

        // Expect
        vm.expectEmit();
        emit ILegionSale.CapitalRefunded(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();

        // Expect
        uint256 investor1Balance = MockERC20(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6, "Investor1 balance should be restored to 1000 USDC");
    }

    /**
     * @notice Tests that refunding after the refund period has ended reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when called after refundEndTime
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsOver.selector, (refundEndTime() + 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @notice Tests that refunding when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects LegionSale__InvalidRefundAmount revert when investor1 has not invested
     */
    function test_refund_revertsIfNoCapitalIsInvested() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() + 1); // Within refund period

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidRefundAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert after investor1 refunds once
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful cancellation of the sale by the project admin
     * @dev Verifies that the SaleCanceled event is emitted before results are published
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after initial cancellation
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling after results are published reverts
     * @dev Expects LegionSale__SaleResultsAlreadyPublished revert after publishing results
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by investor1
     */
    function testFuzz_cancelSale_revertsIfCalledByNonProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling after cancel is locked reverts
     * @dev Expects LegionSale__CancelLocked revert after initializing publish sale results
     */
    function test_cancelSale_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelLocked.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                  WITHDRAW INVESTED CAPITAL IF CANCELED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of invested capital after cancellation
     * @dev Verifies that the CapitalRefundedAfterCancel event is emitted and funds are returned
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

        // Expect
        vm.expectEmit();
        emit ILegionSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();

        assertEq(MockERC20(bidToken).balanceOf(investor1), 1000 * 1e6, "Investor1 balance should be 1000 USDC");
    }

    /**
     * @notice Tests that withdrawing invested capital when the sale is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when sale is still active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing invested capital with no investment reverts
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor1 has not invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalIsPledged() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of sale results by the Legion admin
     * @dev Verifies that the SaleResultsPublished event is emitted with correct parameters
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Expect
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
     * @notice Tests that publishing results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @notice Tests that publishing results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishSaleResults_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @notice Tests that publishing results without locking cancel reverts
     * @dev Expects LegionSale__CancelNotLocked revert when initializePublishSaleResults is not called
     */
    function test_publishSaleResults_revertsIfCancelNotLocked() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();
        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelNotLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @notice Tests that republishing results reverts
     * @dev Expects LegionSale__PrivateKeyAlreadyPublished revert after initial publication
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
    }

    /**
     * @notice Tests that publishing with an invalid private key reverts
     * @dev Expects LegionSale__InvalidBidPrivateKey revert when using an incorrect private key
     */
    function test_publishSaleResults_revertsIfInvalidPrivateKey() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPrivateKey.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY - 1
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZE PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization of publish sale results by the Legion admin
     * @dev Verifies that the PublishSaleResultsInitialized event is emitted
     */
    function test_initializePublishSaleResults_successfullyEmitsPublishSaleResultsInitialized() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionSealedBidAuctionSale.PublishSaleResultsInitialized();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @notice Tests that initializing publish sale results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_initializePublishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @notice Tests that reinitializing publish sale results reverts
     * @dev Expects LegionSale__CancelLocked revert after initial initialization
     */
    function test_initializePublishSaleResults_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @notice Tests that initializing publish sale results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_initializePublishSaleResults_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /**
     * @notice Tests that initializing publish sale results before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_initializePublishSaleResults_revertsIfRefunPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        SET ACCEPTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful setting of accepted capital by the Legion admin
     * @dev Verifies that the AcceptedCapitalSet event is emitted with the correct Merkle root during the sale period
     */
    function test_setAcceptedCapital_successfullyEmitsAcceptedCapitalSet() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1); // Within sale period (1 hour - 1 second)

        // Expect
        vm.expectEmit();
        emit ILegionSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by an unauthorized account (nonLegionAdmin)
     */
    function testFuzz_setAcceptedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1); // Within sale period (1 hour - 1 second)

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when called after the refund period ends
     */
    function test_setAcceptedCapital_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (refundEndTime() + 1)));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(endTime() - 1); // Within sale period (1 hour - 1 second)

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token supply with non-zero Legion fee by the project admin
     * @dev Verifies that TokensSuppliedForDistribution event is emitted with correct amounts after sale results are
     * published
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Expect
        // referrer fee
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests successful token supply with zero Legion fee by the project admin
     * @dev Verifies that TokensSuppliedForDistribution event is emitted correctly when Legion fee is configured as 0
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 0,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );

        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Expect
        // referrer fee
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_supplyTokens_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect Legion fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when Legion fee (90 LFG) does not match expected (100 LFG)
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 90 * 1e18, 100 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect referrer fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when referrer fee (39 LFG) does not match expected (40 LFG)
     */
    function test_supplyTokens_revertsIfReferreFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 39 * 1e18, 40 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 39 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect total amount reverts
     * @dev Expects LegionSale__InvalidTokenAmountSupplied revert when supplied amount (9990 LFG) does not match
     * published (4000
     * LFG)
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

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidTokenAmountSupplied.selector, 9990 * 1e18, 4000 * 1e18)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens before sale results are published reverts
     * @dev Expects LegionSale__TokensNotAllocated revert when results are not yet published
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens twice reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert after initial supply
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an unavailable askToken reverts
     * @dev Expects LegionSale__AskTokenUnavailable revert when askToken is set to address(0)
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of raised capital with non-zero Legion fee by project admin
     * @dev Verifies CapitalWithdrawn event and balance update after tokens are supplied and results published
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

        // Expect
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();

        // Expect
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - (capitalRaised() * 250 / 10_000) - (capitalRaised() * 100 / 10_000),
            "Project admin balance should reflect capital minus fees"
        );
    }

    /**
     * @notice Tests successful withdrawal of raised capital with zero Legion fee by project admin
     * @dev Verifies CapitalWithdrawn event and balance update when Legion fee is 0
     */
    function test_withdrawRaisedCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        prepareSealedBidData();
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 0,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
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

        // Expect
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();

        // Expect
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - (capitalRaised() * 100 / 10_000),
            "Project admin balance should reflect capital minus referrer fee"
        );
    }

    /**
     * @notice Tests that withdrawal by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() - 1); // Still within refund period (2 weeks - 1 second)

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal before sale results are published reverts
     * @dev Expects LegionSale__SaleResultsNotPublished revert when results are not yet published
     */
    function test_withdrawRaisedCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal before tokens are supplied reverts
     * @dev Expects LegionSale__TokensNotSupplied revert when tokens have not been supplied
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Expects LegionSale__CapitalAlreadyWithdrawn revert after initial withdrawal
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal with no capital raised reverts
     * @dev Expects LegionSale__CapitalNotRaised revert when published capital raised is 0
     */
    function test_withdrawRaisedCapital_revertsIfNoCapitalRaised() public {
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
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 0, PRIVATE_KEY
        );
        vm.stopPrank();

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalNotRaised.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW EXCESS INVESTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of excess invested capital by an investor
     * @dev Verifies excess capital (1000 USDC) is transferred back to investor2 with valid Merkle proof
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapitalTokens() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // investor2 invests 2000 USDC

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1); // Before sale ends (1 hour - 1 second)

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Expect
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true, "Investor2 should have claimed excess");
        assertEq(
            MockERC20(bidToken).balanceOf(investor2),
            1000 * 1e6,
            "Investor2 balance should be 1000 USDC after withdrawal"
        );
    }

    /**
     * @notice Tests that withdrawing excess capital when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1); // Before sale ends

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with an incorrect Merkle proof reverts
     * @dev Expects LegionSale__CannotWithdrawExcessInvestedCapital revert with invalid proof for investor2
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0xe6ec166fcb24e8b45dbf44e2137a36706ae07288095a733f7439bb2f81a94052); // Invalid
        excessClaimProofInvestor2[1] = bytes32(0x61c19f281f94212e62b60d017ca806d139d4f0da454abbc73e9533e0d99f398c); // Invalid

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__CannotWithdrawExcessInvestedCapital.selector, investor2, 1000 * 1e6
            )
        );

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Expects LegionSale__AlreadyClaimedExcess revert after investor2 claims excess once
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with no prior investment reverts
     * @dev Expects LegionSale__NoCapitalInvested revert for investor5 who did not invest
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).withdrawExcessInvestedCapital(
            6000 * 1e6, excessClaimProofInvestor5
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM TOKEN ALLOCATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token allocation claim by an investor after sale results are published
     * @dev Verifies tokens (900 LFG) are transferred to vesting contract for investor2 and (100 LFG) initial release,
     * with valid proof
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
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Expect
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).investorPositionDetails(investor2);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionSealedBidAuctionSale(payable(legionSealedBidAuctionInstance)).investorVestingStatus(investor2);

        assertEq(_investorPosition.hasSettled, true, "Investor2 should have settled position");
        assertEq(
            MockERC20(askToken).balanceOf(_investorPosition.vestingAddress),
            9000 * 1e17,
            "Vesting contract should hold 900 LFG (90% of 1000 LFG after 10% initial release)"
        );
        assertEq(vestingStatus.start, 0, "Vesting start should be 0");
        assertEq(vestingStatus.end, 31_536_000, "Vesting end should be 1 year (31,536,000 seconds)");
        assertEq(vestingStatus.cliffEnd, 3600, "Vesting cliff should be 1 hour (3600 seconds)");
        assertEq(vestingStatus.duration, 31_536_000, "Vesting duration should be 1 year");
        assertEq(vestingStatus.released, 0, "No tokens should be released yet");
        assertApproxEqAbs(
            vestingStatus.releasable,
            34_623_344_748_858_447_488,
            1e18,
            "Releasable amount should approximate releasable amount"
        );
        assertApproxEqAbs(
            vestingStatus.vestedAmount,
            34_623_344_748_858_447_488,
            1e18,
            "Vested amount should approximate vested amount"
        );
    }

    /**
     * @notice Tests that claiming tokens before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_claimTokenAllocation_revertsIfRefundPeriodHasNotEnded() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.warp(refundEndTime() - 1); // Before refund period ends (2 weeks - 1 second)

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).cancelSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens before sale results are published reverts
     * @dev Expects LegionSale__SaleResultsNotPublished revert when results are not yet published
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);
        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming more tokens than allocated reverts
     * @dev Expects LegionSale__NotInClaimWhitelist revert when investor2 tries to claim 2000 LFG instead of 1000 LFG
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            2000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens twice reverts
     * @dev Expects LegionSale__AlreadySettled revert after investor2 claims allocation once
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
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );
        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens with no askToken reverts
     * @dev Expects LegionSale__AskTokenUnavailable revert when askToken is address(0)
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        RELEASE VESTED TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful release of vested tokens from investor vesting contract
     * @dev Verifies investor2 receives vested tokens (approx. 134.72 LFG) after cliff period
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
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).initializePublishSaleResults();

        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, 4000 * 1e6, PRIVATE_KEY
        );

        vm.prank(projectAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();

        // Expect
        assertApproxEqAbs(
            MockERC20(askToken).balanceOf(investor2),
            134_726_084_474_885_844_748,
            1e18,
            "Investor2 should have approximately 134.72 LFG after release"
        );
    }

    /**
     * @notice Tests that releasing vested tokens without a vesting contract reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when investor2 has no vesting deployed
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();
    }

    /**
     * @notice Tests that releasing vested tokens with no askToken reverts
     * @dev Expects LegionSale__AskTokenUnavailable revert when askToken is address(0)
     */
    function test_releaseVestedTokens_revertsIfAskTokenNotAvailable() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidAuctionInstance = legionSaleFactory.createSealedBidAuction(
            testConfig.saleInitParams, testConfig.sealedBidAuctionSaleInitParams
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).releaseVestedTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        DECRYPT SEALED BID TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful decryption of sealed bids after results are published
     * @dev Verifies bids for investors 1-4 decrypt correctly to 1000-4000 LFG
     */
    function test_decryptSealedBid_successfullyDecryptSealedBid() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidAuction();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

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

        // Expect
        assertEq(decryptedBidInvestor1, 1000 * 1e18, "Investor1 bid should decrypt to 1000 LFG");
        assertEq(decryptedBidInvestor2, 2000 * 1e18, "Investor2 bid should decrypt to 2000 LFG");
        assertEq(decryptedBidInvestor3, 3000 * 1e18, "Investor3 bid should decrypt to 3000 LFG");
        assertEq(decryptedBidInvestor4, 4000 * 1e18, "Investor4 bid should decrypt to 4000 LFG");
    }

    /**
     * @notice Tests that decrypting a sealed bid before private key is published reverts
     * @dev Expects LegionSale__PrivateKeyNotPublished revert when results are not yet published
     */
    function test_decryptSealedBid_revertsIfPrivateKeyNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyNotPublished.selector));

        // Act
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).decryptSealedBid(
            encryptedAmountInvestort1, uint256(uint160(investor1))
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful syncing of Legion addresses by Legion admin
     * @dev Verifies LegionAddressesSynced event with updated fee receiver address
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidAuction();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidAuctionSale(legionSealedBidAuctionInstance).syncLegionAddresses();
    }
}
