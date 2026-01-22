// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721 } from "@solady/src/tokens/ERC721.sol";
import { ERC20 } from "@solady/src/tokens/ERC20.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Test, console2, Vm } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { ECIES, Point } from "../../src/lib/ECIES.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionSealedBidSale } from "../../src/interfaces/sales/ILegionSealedBidSale.sol";
import { ILegionSealedBidSaleFactory } from "../../src/interfaces/factories/ILegionSealedBidSaleFactory.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionSealedBidSale } from "../../src/sales/LegionSealedBidSale.sol";
import { LegionSealedBidSaleFactory } from "../../src/factories/LegionSealedBidSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Sealed Bid Sale Test
 * @author Legion
 * @notice Test suite for the LegionSealedBidSale contract
 * @dev Inherits from Forge's Test contract and uses ECDSA and MessageHashUtils for signature handling
 */
contract LegionSealedBidSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configuration structure for sale tests
     * @dev Combines general sale params with sealed bid sale-specific params
     */
    struct SaleTestConfig {
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams; // General sale initialization params
        ILegionSealedBidSale.SealedBidSaleInitializationParams sealedBidSaleInitParams; // Sealed
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
     * @notice Test configuration for sealed bid sale tests
     * @dev Stores the sale and sale-specific parameters
     */
    SaleTestConfig public testConfig;

    /**
     * @notice Template instance of LegionSealedBidSale for factory deployment
     * @dev Used as the implementation contract for proxy deployments
     */
    LegionSealedBidSale public sealedBidSaleTemplate;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating sealed bid sale instances
     * @dev Deploys new instances of LegionSealedBidSale
     */
    LegionSealedBidSaleFactory public legionSaleFactory;

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
     * @notice Address of the deployed sealed bid sale instance
     * @dev Points to the active sale contract being tested
     */
    address public legionSealedBidSaleInstance;

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
     * @notice Address representing the vesting contract controller, set to 0x99
     */
    address public legionVestingController = address(0x99);

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

    /// @notice Signature for investor1's transfer to investor2
    bytes signatureInv1Transfer;

    /// @notice Signature for investor2's transfer to investor1
    bytes signatureInv2Transfer;

    /**
     * @notice Private keys for Legion and non-Legion signers
     * @dev legionSignerPK (1234) for valid signatures, nonLegionSignerPK (12,345) for invalid ones
     */
    uint256 public legionSignerPK = 1234;
    uint256 public nonLegionSignerPK = 12_345;

    /// @notice Signatures for excess withdrawal tests
    bytes signatureInv1ExcessWithdrawal;
    bytes signatureInv2ExcessWithdrawal;
    bytes signatureInv3ExcessWithdrawal;

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

    /**
     * @notice Sets up the test environment by deploying contracts and configuring initial state
     * @dev Initializes template, factory, registry, tokens, and vesting config
     */
    function setUp() public {
        sealedBidSaleTemplate = new LegionSealedBidSale();
        legionSaleFactory = new LegionSealedBidSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6); // 6 decimals
        prepareLegionAddressRegistry();
        prepareInvestorVestingConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs common setup operations for most tests
     * @dev Creates sale instance, mints tokens, approves spending, prepares sealed bid data and signatures
     */
    function prepareStandardTestSetup() public {
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
    }

    /**
     * @notice Performs common setup operations for tests requiring project tokens
     * @dev Creates sale instance, mints all tokens, approves spending, prepares sealed bid data and signatures
     */
    function prepareFullTestSetup() public {
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
    }

    /**
     * @notice Performs setup for transfer position tests
     * @dev Creates sale instance, mints tokens, approves spending, prepares sealed bid data, investment and transfer
     * signatures
     */
    function prepareTransferTestSetup() public {
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();
    }

    /**
     * @notice Performs setup for excess withdrawal tests
     * @dev Creates sale instance, mints tokens, approves spending, prepares sealed bids, invests from all investors,
     * and prepares excess withdrawal signatures
     */
    function prepareExcessWithdrawalTestSetup() public {
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();
        prepareExcessWithdrawalSignatures();
    }

    /**
     * @notice Sets the sale and sealed bid  parameters
     * @dev Updates testConfig with provided initialization parameters
     * @param _saleInitParams General sale initialization parameters
     * @param _sealedBidSaleInitParams Sealed bid sale-specific initialization parameters
     */
    function setSaleParams(
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionSealedBidSale.SealedBidSaleInitializationParams memory _sealedBidSaleInitParams
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

        testConfig.sealedBidSaleInitParams =
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: _sealedBidSaleInitParams.publicKey });
    }

    /**
     * @notice Creates a sealed bid sale instance
     * @dev Deploys a sale with default parameters (1-hour sale, 2-week refund, 2.5% Legion fee, etc.)
     */
    function prepareCreateLegionSealedBidSale() public {
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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidSaleInstance =
            legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
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
        MockERC20(bidToken).approve(legionSealedBidSaleInstance, 1000 * 1e6);

        vm.prank(investor2);
        MockERC20(bidToken).approve(legionSealedBidSaleInstance, 2000 * 1e6);

        vm.prank(investor3);
        MockERC20(bidToken).approve(legionSealedBidSaleInstance, 3000 * 1e6);

        vm.prank(investor4);
        MockERC20(bidToken).approve(legionSealedBidSaleInstance, 4000 * 1e6);
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

        bytes32 digest1 = keccak256(
            abi.encodePacked(
                investor1,
                legionSealedBidSaleInstance,
                block.chainid,
                uint256(1000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest2 = keccak256(
            abi.encodePacked(
                investor2,
                legionSealedBidSaleInstance,
                block.chainid,
                uint256(2000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest3 = keccak256(
            abi.encodePacked(
                investor3,
                legionSealedBidSaleInstance,
                block.chainid,
                uint256(3000 * 1e6),
                (block.timestamp + 100),
                ILegionAbstractSale.SaleAction.INVEST
            )
        ).toEthSignedMessageHash();
        bytes32 digest4 = keccak256(
            abi.encodePacked(
                investor4,
                legionSealedBidSaleInstance,
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
            keccak256(abi.encodePacked(investor1, legionSealedBidSaleInstance, block.chainid)).toEthSignedMessageHash();

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
            abi.encodePacked(investor1, investor2, uint256(1), investor1, legionSealedBidSaleInstance, block.chainid)
        ).toEthSignedMessageHash();

        bytes32 digest2Transfer = keccak256(
            abi.encodePacked(investor1, investor2, uint256(2), investor1, legionSealedBidSaleInstance, block.chainid)
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
                legionSealedBidSaleInstance,
                block.chainid,
                uint256(0),
                ILegionAbstractSale.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest2ExcessWithdrawal = keccak256(
            abi.encodePacked(
                investor2,
                legionSealedBidSaleInstance,
                block.chainid,
                uint256(1000 * 1e6),
                ILegionAbstractSale.SaleAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest3ExcessWithdrawal =
            keccak256(abi.encodePacked(investor3, legionSealedBidSaleInstance, block.chainid)).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1ExcessWithdrawal);
        signatureInv1ExcessWithdrawal = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2ExcessWithdrawal);
        signatureInv2ExcessWithdrawal = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest3ExcessWithdrawal);
        signatureInv3ExcessWithdrawal = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Simulates investments from all investors
     * @dev Investors 1-4 invest 1000-4000 USDC with their respective sealed bids and signatures
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            2000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor2, signatureInv2
        );

        vm.prank(investor3);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            3000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor3, signatureInv3
        );

        vm.prank(investor4);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            4000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor4, signatureInv4
        );
    }

    /**
     * @notice Prepares sealed bid data for investors
     * @dev Encrypts bid amounts (1000-4000 LFG) and encodes with salts and public keys
     */
    function prepareSealedBidData() public {
        (uint256 encryptedAmountOut1,) = ECIES.encrypt(
            1000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor1, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut2,) = ECIES.encrypt(
            2000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor2, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut3,) = ECIES.encrypt(
            3000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor3, FIXED_SALT)))
        );
        (uint256 encryptedAmountOut4,) = ECIES.encrypt(
            4000 * 1e18, PUBLIC_KEY, PRIVATE_KEY, uint256(keccak256(abi.encodePacked(investor4, FIXED_SALT)))
        );

        sealedBidDataInvestor1 = abi.encode(encryptedAmountOut1, PUBLIC_KEY);
        sealedBidDataInvestor2 = abi.encode(encryptedAmountOut2, PUBLIC_KEY);
        sealedBidDataInvestor3 = abi.encode(encryptedAmountOut3, PUBLIC_KEY);
        sealedBidDataInvestor4 = abi.encode(encryptedAmountOut4, PUBLIC_KEY);

        invalidSealedBidData = abi.encode(encryptedAmountOut1, INVALID_PUBLIC_KEY);
        invalidSealedBidData1 = abi.encode(encryptedAmountOut1, INVALID_PUBLIC_KEY_1);

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
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_CONTROLLER"), legionVestingController);

        vm.stopPrank();
    }

    /**
     * @notice Sets up the investor vesting configuration
     * @dev Configures a linear vesting schedule: 0 start, 1-year duration, 1-hour cliff, 10% initial release
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            0, 31_536_000, 3600, ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 0, 1e17
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
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Queries the sale configuration from the deployed instance
     * @return End time of the sale
     */
    function endTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund end time
     * @dev Queries the sale configuration from the deployed instance
     * @return End time of the refund period
     */
    function refundEndTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Queries the sale status from the deployed instance
     * @return saleTotalCapitalRaised Total capital raised in bid tokens
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionAbstractSale.LegionSaleStatus memory _saleStatusDetails =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).saleStatus();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful deployment of the contract with valid parameters
     * @dev Verifies that the sale instance is initialized with the correct public key and vesting factory
     */
    function test_createSealedBidSale_successfullyDeployedWithValidParameters() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        ILegionSealedBidSale.SealedBidSaleConfiguration memory _sealedBidSaleConfig =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).sealedBidSaleConfiguration();

        // Expect
        assertEq(_sealedBidSaleConfig.publicKey.x, PUBLIC_KEY.x, "Public key x-coordinate mismatch");
        assertEq(_sealedBidSaleConfig.publicKey.y, PUBLIC_KEY.y, "Public key y-coordinate mismatch");

        assertEq(ERC20(payable(legionSealedBidSaleInstance)).name(), "Legion Sale Receipt");
        assertEq(ERC20(payable(legionSealedBidSaleInstance)).symbol(), "LGN-RECEIPT");
        assertEq(ERC20(payable(legionSealedBidSaleInstance)).decimals(), 6);
    }

    /**
     * @notice Tests that reinitializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidSale(payable(legionSealedBidSaleInstance)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the implementation contract directly reverts
     * @dev Expects InvalidInitialization revert from Initializable due to template protection
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address sealedBidSaleImplementation = legionSaleFactory.i_sealedBidSaleTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionSealedBidSale(payable(sealedBidSaleImplementation)).initialize(
            testConfig.saleInitParams, testConfig.sealedBidSaleInitParams
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
        LegionSealedBidSale(sealedBidSaleTemplate).initialize(
            testConfig.saleInitParams, testConfig.sealedBidSaleInitParams
        );
    }

    /**
     * @notice Tests that deployment with zero address configurations reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when key addresses are zero
     */
    function test_createSealedBidSale_revertsWithZeroAddressProvided() public {
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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
    }

    /**
     * @notice Tests that deployment with zero value configurations reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when key parameters are zero
     */
    function test_createSealedBidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 0,
                referrerFeeOnCapitalRaisedBps: 0,
                minimumInvestAmount: 0,
                legionOpsFeeInWei: 0,
                bidTokenDecimals: 6,
                bidToken: address(bidToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver
            }),
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
    }

    /**
     * @notice Tests that deployment with periods that are too long reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when sale or refund periods exceed limits
     */
    function test_createSealedBidSale_revertsWithInvalidPeriodConfigTooLong() public {
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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
    }

    /**
     * @notice Tests that deployment with periods that are too short reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when sale or refund periods are below minimums
     */
    function test_createSealedBidSale_revertsWithInvalidPeriodConfigTooShort() public {
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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
    }

    /**
     * @notice Tests that deployment with an invalid public key reverts
     * @dev Expects LegionSale__InvalidBidPublicKey revert when the public key is invalid (e.g., not on curve)
     */
    function test_createSealedBidSale_revertsWithInvalidPublicKey() public {
        // Arrange
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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: INVALID_PUBLIC_KEY_1 })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPublicKey.selector));

        // Act:
        vm.prank(legionBouncer);
        legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by the Legion admin
     * @dev Verifies that the Paused event is emitted when paused by legionBouncer
     */
    function test_pause_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the sale by the Legion admin
     * @dev Verifies that the Unpaused event is emitted after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).unpause();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).pause();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin after pausing
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).unpause();
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
        prepareStandardTestSetup();

        // Expect
        vm.expectEmit();
        emit ILegionSealedBidSale.CapitalInvested(1000 * 1e6, encryptedAmountInvestort1, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when called after endTime
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
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
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), invalidSealedBidData, signatureInv1
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
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), invalidSealedBidData1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing less than the minimum amount reverts
     * @dev Expects LegionSale__InvalidInvestAmount revert when amount is below 1e6
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1 * 1e5, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e16, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert when using a signature from nonLegionSignerPK
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareStandardTestSetup();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, invalidSignature
        );
    }

    /**
     * @notice Tests that reinvesting after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert after investor1 refunds their investment
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );
    }

    /**
     * @notice Tests that reinvesting after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert after investor2 claims excess
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            2000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor2, signatureInv2
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
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(1000 * 1e6, 101, sealedBidDataInvestor1, signatureInv1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of capital raised and accepted capital merkle root
     * @dev Expects CapitalRaisedPublished event emission with correct parameters
     */
    function test_publishRaisedCapital_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionSealedBidSale.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishRaisedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_publishRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is active
     */
    function test_publishRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised twice reverts
     * @dev Expects LegionSale__CapitalRaisedAlreadyPublished revert when already published
     */
    function test_publishRaisedCapital_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);
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
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
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
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefunded(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();

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
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsOver.selector, (refundEndTime() + 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after projectAdmin cancels the sale
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert when investor1 has not invested
     */
    function test_refund_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(endTime() + 1); // Within refund period

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert after investor1 refunds once
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareStandardTestSetup();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful cancellation of the sale by the project admin
     * @dev Verifies that the SaleCanceled event is emitted before results are published
     */
    function test_cancel_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after initial cancellation
     */
    function test_cancel_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by investor1
     */
    function testFuzz_cancel_revertsIfCalledByNonProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling after cancel is locked reverts
     * @dev Expects LegionSale__CancelLocked revert after initializing publish sale results
     */
    function test_cancel_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelLocked.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();
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
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawInvestedCapitalIfCanceled();

        assertEq(MockERC20(bidToken).balanceOf(investor1), 1000 * 1e6, "Investor1 balance should be 1000 USDC");
    }

    /**
     * @notice Tests that withdrawing invested capital when the sale is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when sale is still active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing invested capital with no investment reverts
     * @dev Expects LegionSale__InvalidAmount revert when investor1 has not invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital after cancellation reverts if the investor has already withdrawn
     * @dev Expects LegionSale__InvalidAmount revert when investor1 tries to withdraw again
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfInvestorHasAlreadyWithdrawnInvestedCapital() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).invest(
            1000 * 1e6, (block.timestamp + 100), sealedBidDataInvestor1, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawInvestedCapitalIfCanceled();
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
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        // Expect
        vm.expectEmit();
        emit ILegionSealedBidSale.Revealed(PRIVATE_KEY, FIXED_SALT);

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_reveal_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_reveal_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing results without locking cancel reverts
     * @dev Expects LegionSale__CancelNotLocked revert when initializeReveal is not called
     */
    function test_reveal_revertsIfCancelNotLocked() public {
        // Arrange
        prepareCreateLegionSealedBidSale();
        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelNotLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that republishing results reverts
     * @dev Expects LegionSale__PrivateKeyAlreadyPublished revert after initial publication
     */
    function test_reveal_revertsIfPrivateKeyAlreadyPublished() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
    }

    /**
     * @notice Tests that publishing with an invalid private key reverts
     * @dev Expects LegionSale__InvalidBidPrivateKey revert when using an incorrect private key
     */
    function test_reveal_revertsIfInvalidPrivateKey() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidBidPrivateKey.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY - 1, FIXED_SALT);
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
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionSealedBidSale.RevealInitialized();

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_initializeReveal_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that reinitializing publish sale results reverts
     * @dev Expects LegionSale__CancelLocked revert after initial initialization
     */
    function test_initializeReveal_revertsIfCancelIsLocked() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CancelLocked.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_initializeReveal_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
    }

    /**
     * @notice Tests that initializing publish sale results before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_initializeReveal_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
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
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();

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
            ILegionSealedBidSale.SealedBidSaleInitializationParams({ publicKey: PUBLIC_KEY })
        );

        vm.prank(legionBouncer);
        legionSealedBidSaleInstance =
            legionSaleFactory.createSealedBidSale(testConfig.saleInitParams, testConfig.sealedBidSaleInitParams);

        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();

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
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal before sale results are published reverts
     * @dev Expects LegionSale__SaleResultsNotPublished revert when results are not yet published
     */
    function test_withdrawRaisedCapital_revertsIfRaisedCapitalNotPublished() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Expects LegionSale__CapitalAlreadyWithdrawn revert after initial withdrawal
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).publishRaisedCapital(10_000 * 1e6);

        vm.startPrank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
        vm.stopPrank();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawal with no capital raised reverts
     * @dev Expects LegionSale__CapitalNotRaised revert when published capital raised is 0
     */
    function test_withdrawRaisedCapital_revertsIfNoCapitalRaised() public {
        // Arrange
        prepareSealedBidData();
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.startPrank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);
        vm.stopPrank();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW EXCESS INVESTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of excess invested capital by an investor
     * @dev Verifies excess capital (1000 USDC) is transferred back to investor2 with valid Merkle proof
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapital() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.warp(endTime() + 1);

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionSealedBidSale(payable(legionSealedBidSaleInstance)).investorPosition(investor2);

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
        prepareExcessWithdrawalTestSetup();

        vm.warp(endTime() + 1);

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
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

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv3ExcessWithdrawal)
        );

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv3ExcessWithdrawal
        );
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Expects LegionSale__AlreadyClaimedExcess revert after investor2 claims excess once
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareFullTestSetup();
        prepareInvestedCapitalFromAllInvestors();
        prepareExcessWithdrawalSignatures();

        vm.warp(endTime() + 1);

        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with no prior investment reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert for investor5 who did not invest
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionSealedBidSale();
        prepareExcessWithdrawalSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1ExcessWithdrawal)
        );

        // Act
        vm.prank(investor5);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            6000 * 1e6, signatureInv1ExcessWithdrawal
        );
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
        prepareCreateLegionSealedBidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1); // After refund period (2 weeks + 1 second)

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).initializeReveal();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).reveal(PRIVATE_KEY, FIXED_SALT);

        // Act
        uint256 decryptedBidInvestor1 =
            ILegionSealedBidSale(legionSealedBidSaleInstance).decryptSealedBid(encryptedAmountInvestort1, investor1);
        uint256 decryptedBidInvestor2 =
            ILegionSealedBidSale(legionSealedBidSaleInstance).decryptSealedBid(encryptedAmountInvestort2, investor2);
        uint256 decryptedBidInvestor3 =
            ILegionSealedBidSale(legionSealedBidSaleInstance).decryptSealedBid(encryptedAmountInvestort3, investor3);
        uint256 decryptedBidInvestor4 =
            ILegionSealedBidSale(legionSealedBidSaleInstance).decryptSealedBid(encryptedAmountInvestort4, investor4);

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
        prepareCreateLegionSealedBidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__PrivateKeyNotPublished.selector));

        // Act
        ILegionSealedBidSale(legionSealedBidSaleInstance).decryptSealedBid(encryptedAmountInvestort1, investor1);
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
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.LegionAddressesSynced(legionBouncer, vm.addr(legionSignerPK), address(1));

        // Act
        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionSealedBidSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).syncLegionAddresses();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CLAIM RECEIPT TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful claiming of receipt tokens after refund period ends
     * @dev Expects ReceiptTokensClaimed event emission and verifies investor's receipt token balance
     */
    function test_claimReceiptTokens_successfullyEmitsReceiptTokensClaimed() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, signatureInv2ExcessWithdrawal
        );

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.ReceiptTokensClaimed(investor2, 1000 * 1e6);

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();

        // Expect
        assertEq(ERC20(legionSealedBidSaleInstance).balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @notice Tests that claiming receipt tokens before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is still active
     */
    function test_claimReceiptTokens_revertsIfCalledBeforeRefundPeriodEnds() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();
    }

    /**
     * @notice Tests that claiming receipt tokens when sale is paused reverts
     * @dev Expects Pausable.EnforcedPause revert when sale is paused
     */
    function test_claimReceiptTokens_revertsIfSaleIsPaused() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.prank(legionBouncer);
        ILegionSealedBidSale(legionSealedBidSaleInstance).pause();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();
    }

    /**
     * @notice Tests that claiming receipt tokens when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_claimReceiptTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).cancel();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();
    }

    /**
     * @notice Tests that claiming receipt tokens reverts if investor has refunded
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is still active
     */
    function test_claimReceiptTokens_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).refund();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();
    }

    /**
     * @notice Tests that claiming receipt tokens reverts if investor has not claimed excess capital
     * @dev Expects LegionSale__InvestorHasNotClaimedExcess revert when investor has not withdrawn excess capital
     */
    function test_claimReceiptTokens_revertsIfInvestorHasNotClaimedExcessCapital() public {
        // Arrange
        prepareExcessWithdrawalTestSetup();

        vm.prank(projectAdmin);
        ILegionSealedBidSale(legionSealedBidSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasNotClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionSealedBidSale(legionSealedBidSaleInstance).claimReceiptTokens();
    }
}
