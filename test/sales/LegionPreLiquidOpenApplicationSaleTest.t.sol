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
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionPreLiquidOpenApplicationSale } from "../../src/interfaces/sales/ILegionPreLiquidOpenApplicationSale.sol";
import { ILegionPreLiquidOpenApplicationSaleFactory } from
    "../../src/interfaces/factories/ILegionPreLiquidOpenApplicationSaleFactory.sol";
import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionPreLiquidOpenApplicationSale } from "../../src/sales/LegionPreLiquidOpenApplicationSale.sol";
import { LegionPreLiquidOpenApplicationSaleFactory } from
    "../../src/factories/LegionPreLiquidOpenApplicationSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Test
 * @author Legion
 * @notice Test suite for the LegionPreLiquidOpenApplicationSale contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionPreLiquidOpenApplicationSaleTest is Test {
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
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams; // Sale initialization parameters
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
     * @notice Template instance of the LegionPreLiquidOpenApplicationSale contract for cloning
     * @dev Used as the base for creating new sale instances
     */
    LegionPreLiquidOpenApplicationSale public preLiquidOpenApplicationSaleTemplate;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating pre-liquid sale V2 instances
     * @dev Deploys new instances of LegionPreLiquidOpenApplicationSale
     */
    LegionPreLiquidOpenApplicationSaleFactory public legionSaleFactory;

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
     * @notice Mock token used as the sale token
     * @dev Represents the token being sold (e.g., LFG)
     */
    MockERC20 public askToken;

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
     * @notice Address representing the Referrer fee receiver
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

    /**
     * @notice Merkle root for claimable tokens
     * @dev Precomputed root for verifying token claims
     */
    bytes32 public claimTokensMerkleRoot = 0x8d7c018c2099eaee9884eb772e1565b75cb717aa61d4caa276dd612273cdd649;

    /**
     * @notice Merkle root for accepted capital
     * @dev Precomputed root for verifying accepted capital claims
     */
    bytes32 public acceptedCapitalMerkleRoot = 0x380f79c2e8e6e4bc37b7fda83ac0f1a33b5abc5d70831c08add80068b2d564cf;

    /**
     * @notice Malicious Merkle root for excess capital
     * @dev Precomputed root for testing invalid excess capital claims
     */
    bytes32 public excessCapitalMerkleRootMalicious = 0x04169dca2cf842bea9fcf4df22c9372c6d6f04410bfa446585e287aa1c834974;

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     * @dev Initializes sale template, factory, vesting factory, registry, tokens, and vesting config
     */
    function setUp() public {
        preLiquidOpenApplicationSaleTemplate = new LegionPreLiquidOpenApplicationSale();
        legionSaleFactory = new LegionPreLiquidOpenApplicationSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
        prepareInvestorVestingConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the pre-liquid sale configuration parameters
     * @dev Updates the testConfig with provided initialization parameters
     * @param _saleInitParams Parameters for initializing a pre-liquid sale
     */
    function setSaleParams(ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams) public {
        testConfig.saleInitParams = ILegionAbstractSale.LegionSaleInitializationParams({
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
            referrerFeeReceiver: _saleInitParams.referrerFeeReceiver,
            saleName: _saleInitParams.saleName,
            saleSymbol: _saleInitParams.saleSymbol,
            saleBaseURI: _saleInitParams.saleBaseURI
        });
    }

    /**
     * @notice Creates and initializes a LegionPreLiquidOpenApplicationSale instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionPreLiquidSale() public {
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);
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
     * @notice Mints tokens to the project and approves the sale instance contract
     * @dev Prepares ask tokens for the project admin to supply to the sale
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);

        MockERC20(askToken).mint(projectAdmin, 10_000 * 1e18);
        MockERC20(askToken).approve(legionSaleInstance, 10_000 * 1e18);

        vm.stopPrank();
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
     * @notice Invests capital from all investors
     * @dev Simulates investments from all predefined investors
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.prank(investor3);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(3000 * 1e6, signatureInv3);

        vm.prank(investor4);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(4000 * 1e6, signatureInv4);
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
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Queries the sale configuration for the end timestamp
     * @return uint256 The end time of the sale
     */
    function endTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund end time
     * @dev Queries the sale configuration for the refund end timestamp
     * @return uint256 The end time of the refund period
     */
    function refundEndTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Queries the sale status for the total capital raised
     * @return saleTotalCapitalRaised The total capital raised in the sale
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionAbstractSale.LegionSaleStatus memory _saleStatusDetails =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).saleStatus();
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

        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).vestingConfiguration();

        // Expect
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
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
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address fixedPriceSaleImplementation = legionSaleFactory.i_preLiquidOpenApplicationSaleTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidOpenApplicationSale(payable(fixedPriceSaleImplementation)).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidOpenApplicationSale(preLiquidOpenApplicationSaleTemplate).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: address(0),
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when key parameters are zero
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                salePeriodSeconds: 0,
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(0),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "",
                saleSymbol: "",
                saleBaseURI: ""
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with an overly long period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when periods exceed limits
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with an overly short period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when periods are below minimum
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooShort() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).unpause();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).unpause();
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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidOpenApplicationSale.CapitalInvested(1000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that successful investment mints an investor position
     * @dev Expects ERC721 balance increase and correct token URI after investment
     */
    function test_invest_successfullyMintsInvestorPosition() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert("ERC721: URI query for nonexistent token");

        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).tokenURI(1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        assertEq(ERC721(legionSaleInstance).balanceOf(investor1), 1);
        assertEq(
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).tokenURI(1), "https://metadata.legion.cc/1"
        );
    }

    /**
     * @notice Tests that investing after the sale has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale is no longer active
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing with an amount less than the minimum reverts
     * @dev Expects LegionSale__InvalidInvestAmount revert when investment is below threshold
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1 * 1e5, signatureInv1);
    }

    /**
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale has been canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert when signature is not valid
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, invalidSignature);
    }

    /**
     * @notice Tests that investing after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor has already refunded
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert when excess capital is claimed
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);
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
        emit ILegionPreLiquidOpenApplicationSale.SaleEnded();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending the sale when paused reverts
     * @dev Expects EnforcedPause revert when sale is paused
     */
    function test_end_revertsIfSaleIsPaused() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending the sale when canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is already canceled
     */
    function test_end_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();
    }

    /**
     * @notice Tests that ending an already ended sale reverts
     * @dev Expects LegionSale__SaleHasEnded revert when sale is already ended
     */
    function test_end_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidOpenApplicationSale.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_publishRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is active
     */
    function test_publishRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Tests that publishing capital raised twice reverts
     * @dev Expects LegionSale__CapitalRaisedAlreadyPublished revert when already published
     */
    function test_publishRaisedCapital_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);
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
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).emergencyWithdraw(
            legionBouncer, address(bidToken), 1000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).emergencyWithdraw(
            projectAdmin, address(bidToken), 1000 * 1e6
        );
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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        // Act & Assert
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefunded(1000 * 1e6, investor1, 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();

        uint256 investor1Balance = MockERC20(bidToken).balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @notice Tests that refunding after the refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when refund period has expired
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsOver.selector, (refundEndTime() + 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding when the sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
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
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor has already refunded
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests successful cancellation and capital return by project admin
     * @dev Verifies SaleCanceled event and capital return to sale contract
     */
    function test_cancel_successfullyCancelsIfCapitalToReturn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();

        vm.startPrank(projectAdmin);
        MockERC20(bidToken).mint(projectAdmin, 350 * 1e6);
        MockERC20(bidToken).approve(legionSaleInstance, 10_000 * 1e6);
        vm.stopPrank();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling a sale after tokens are supplied reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert when tokens are supplied
     */
    function test_cancel_revertsIfTokensSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();
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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        assertEq(MockERC20(bidToken).balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing invested capital when sale is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when sale is still active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing invested capital with no investment reverts
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when no capital is invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital after cancellation reverts if the investor has already withdrawn
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor1 tries to withdraw again
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfInvestorHasAlreadyWithdrawnInvestedCapital() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of sale results by Legion admin
     * @dev Expects SaleResultsPublished event emission with correct parameters
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionPreLiquidOpenApplicationSale.SaleResultsPublished(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishSaleResults_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results twice reverts
     * @dev Expects LegionSale__TokensAlreadyAllocated revert when results are already published
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadyAllocated.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when refund period is active
     */
    function test_publishSaleResults_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        SET ACCEPTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful setting of accepted capital by Legion admin
     * @dev Expects AcceptedCapitalSet event emission with correct merkle root
     */
    function test_setAcceptedCapital_successfullyEmitsAcceptedCapitalSet() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_setAcceptedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionPreLiquidSale();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital when sale is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token supply for distribution by the project admin
     * @dev Verifies that supplying tokens after sale results are published emits the TokensSuppliedForDistribution
     * event with correct amounts (4000 LFG, 100 LFG Legion fee, 40 LFG referrer fee).
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect Legion fee amount reverts
     * @dev Ensures the contract rejects a supply attempt where the Legion fee (90 LFG) does not match the expected
     * amount based on the fee basis points (250 bps of 4000 LFG = 100 LFG).
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 90 * 1e18, 100 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect referrer fee amount reverts
     * @dev Ensures the contract rejects a supply attempt where the referrer fee (39 LFG) does not match the expected
     * amount based on the fee basis points (100 bps of 4000 LFG = 40 LFG).
     */
    function test_supplyTokens_revertsIfReferrerFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 39 * 1e18, 40 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 39 * 1e18);
    }

    /**
     * @notice Tests successful token supply when the Legion fee is set to zero
     * @dev Verifies that supplying tokens with a zero Legion fee (due to 0 bps) emits the correct event and works as
     * expected.
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);

        prepareMintAndApproveProjectTokens();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by a non-project admin reverts
     * @dev Ensures only the project admin can supply tokens, expecting a LegionSale__NotCalledByProject revert.
     */
    function testFuzz_supplyTokens_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens when the sale is canceled reverts
     * @dev Ensures token supply is blocked after cancellation, expecting a LegionSale__SaleIsCanceled revert.
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.warp(refundEndTime() + 1);
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect amount reverts
     * @dev Ensures the supplied token amount matches the published result, expecting an
     * LegionSale__InvalidTokenAmountSupplied
     * revert.
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidTokenAmountSupplied.selector, 9990 * 1e18, 4000 * 1e18)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens before sale results are published reverts
     * @dev Ensures tokens cannot be supplied without prior allocation, expecting a LegionSale__TokensNotAllocated
     * revert.
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens a second time reverts
     * @dev Ensures tokens can only be supplied once, expecting a LegionSale__TokensAlreadySupplied revert.
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();

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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidOpenApplicationSale(testConfig.saleInitParams);

        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();

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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital after the sale is canceled reverts
     * @dev Ensures withdrawal is blocked when the sale is canceled, expecting a LegionSale__SaleIsCanceled revert.
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Ensures capital can only be withdrawn once, expecting a LegionSale__CapitalAlreadyWithdrawn revert on the
     * second
     * attempt.
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawRaisedCapital();
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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Expect
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2);

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
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        vm.warp(endTime() + 1);

        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @notice Tests that withdrawing excess capital with an incorrect Merkle proof reverts
     * @dev Ensures the contract rejects an invalid proof for investor2, expecting a
     * LegionSale__CannotWithdrawExcessInvestedCapital
     * revert.
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612707);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__CannotWithdrawExcessInvestedCapital.selector, investor2, 1000 * 1e6
            )
        );

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Ensures an investor cannot claim excess capital more than once, expecting an
     * LegionSale__AlreadyClaimedExcess revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
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

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);
        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(excessCapitalMerkleRootMalicious);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor5);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            6000 * 1e6, excessClaimProofInvestor5
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM TOKEN ALLOCATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful claiming of token allocation by an investor after sale completion
     * @dev Verifies that investor2 can claim 1000 LFG tokens, which are transferred to a vesting contract with the
     * specified vesting config. Checks investor position and vesting status post-claim.
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Expect
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2);
        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorVestingStatus(investor2);

        assertEq(_investorPosition.hasSettled, true); // Investor has claimed tokens
        assertEq(MockERC20(askToken).balanceOf(_investorPosition.vestingAddress), 9000 * 1e17); // 900 LFG tokens

        assertEq(vestingStatus.start, 0);
        assertEq(vestingStatus.end, 31_536_000);
        assertEq(vestingStatus.cliffEnd, 3600);
        assertEq(vestingStatus.duration, 31_536_000);
        assertEq(vestingStatus.released, 0); // Nothing released yet
        assertEq(vestingStatus.releasable, 34_520_605_022_831_050_228); // Initial releasable amount
        assertEq(vestingStatus.vestedAmount, 34_520_605_022_831_050_228); // Total vested at claim
    }

    /**
     * @notice Tests that claiming tokens before the refund period ends reverts
     * @dev Ensures token claims are blocked during the refund period, expecting a LegionSale__RefundPeriodIsNotOver
     * revert.
     */
    function test_claimTokenAllocation_revertsIfRefundPeriodHasNotEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming more tokens than allocated reverts
     * @dev Ensures investor2 cannot claim 2000 LFG when only 1000 LFG is allocated, expecting a
     * LegionSale__NotInClaimWhitelist
     * revert.
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            2000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens twice reverts
     * @dev Ensures investor2 cannot claim again after a successful claim, expecting an LegionSale__AlreadySettled
     * revert.
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyClaimed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens when the sale is canceled reverts
     * @dev Ensures token claims are blocked after cancellation, expecting a LegionSale__SaleIsCanceled revert.
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens before sale results are published reverts
     * @dev Ensures token claims are blocked without published results, expecting a LegionSale__SaleResultsNotPublished
     * revert.
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        RELEASE VESTED TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful release of vested tokens from an investor's vesting contract
     * @dev Verifies that investor2 can release vested tokens after claiming their allocation and waiting past the cliff
     * period (1 hour), transferring the correct amount of ask tokens to their wallet.
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).releaseVestedTokens();

        // Expect
        assertEq(MockERC20(askToken).balanceOf(investor2), 134_520_605_022_831_050_228);
    }

    /**
     * @notice Tests that releasing vested tokens without a vesting contract reverts
     * @dev Ensures an investor without a deployed vesting contract cannot release tokens, expecting a
     * LegionSale__ZeroAddressProvided revert.
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).releaseVestedTokens();
    }

    /**
     * @notice Test case: Attempt to release tokens without a deployed vesting contract
     * @dev Expects LegionSale__ZeroAddressProvided revert when investor has no vesting contract deployed
     */
    function test_releaseVestedTokens_revertsIfCalledBeforeVestingIsDeployed() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(refundEndTime() + 1 hours + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).releaseVestedTokens();
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
        emit ILegionAbstractSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory), legionVestingController
        );

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).syncLegionAddresses();
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
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).syncLegionAddresses();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        TRANSFER INVESTOR POSITION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully transfer investor position to another investor by Legion
     * @dev Verifies that investor position is transferred correctly and original position no longer exists
     */
    function test_transferInvestorPosition_successfullyTransfersInvestorPosition() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor1);
        assertEq(
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital,
            1000 * 1e6
        );
        assertEq(ERC721(legionSaleInstance).ownerOf(1), investor2);
    }

    /**
     * @notice Test case: Successfully transfer investor position to an existing investor by Legion admin
     * @dev Verifies that investor position is transferred correctly and both investors' positions are updated
     */
    function test_transferInvestorPosition_successfullyTransfersInvestorPositionToExistingInvestor() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionSaleInstance).ownerOf(1);

        assertEq(ERC721(legionSaleInstance).ownerOf(2), investor2);

        assertEq(
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital,
            2000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPosition_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.startPrank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
        vm.stopPrank();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function test_transferInvestorPosition_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPosition_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPosition_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if sale results are published
     * @dev Expects LegionSale__SaleResultsAlreadyPublished revert when trying to transfer position after sale results
     * are published
     */
    function test_transferInvestorPosition_revertsIfSaleResultsArePublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPosition_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPosition_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(legionBouncer);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                   TRANSFER INVESTOR POSITION WITH SIGNATURE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully transfer investor position with signature
     * @dev Verifies that investor position is transferred correctly using a signature
     */
    function test_transferInvestorPositionWithSignature_successfullyTransfersInvestorPosition() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor1);

        assertEq(
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital,
            1000 * 1e6
        );
        assertEq(ERC721(legionSaleInstance).ownerOf(1), investor2);
    }

    /**
     * @notice Test case: Successfully transfer investor position with signature to an existing investor
     * @dev Verifies that investor position is transferred correctly and both investors' positions are updated
     */
    function test_transferInvestorPositionWithSignature_successfullyTransfersInvestorPositionToExistingInvestor()
        public
    {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        vm.prank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, excessClaimProofInvestor2
        );

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionSaleInstance).ownerOf(1);

        assertEq(ERC721(legionSaleInstance).ownerOf(2), investor2);

        assertEq(
            LegionPreLiquidOpenApplicationSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital,
            2000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPositionWithSignature_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.startPrank(investor2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv2);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();
        vm.stopPrank();

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).withdrawExcessInvestedCapital(
            0, excessClaimProofInvestor1
        );

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position by non-position owner using signature
     * @dev Expects LegionSale__InvalidSignature revert when called by non-Legion admin
     */
    function test_transferInvestorPositionWithSignature_revertsIfNotCalledByPositionOwner() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1Transfer));

        // Act
        vm.prank(investor2);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPositionWithSignature_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPositionWithSignature_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if sale results are published
     * @dev Expects LegionSale__SaleResultsAlreadyPublished revert when trying to transfer position after sale results
     * are published
     */
    function test_transferInvestorPositionWithSignature_revertsIfSaleResultsArePublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPositionWithSignature_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPositionWithSignature_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).end();

        vm.prank(investor1);
        ILegionPreLiquidOpenApplicationSale(legionSaleInstance).refund();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(investor1);
        LegionPreLiquidOpenApplicationSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }
}
