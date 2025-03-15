// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../src/utils/Constants.sol";
import { Errors } from "../src/utils/Errors.sol";

import { ILegionPreLiquidSaleV2 } from "../src/interfaces/sales/ILegionPreLiquidSaleV2.sol";
import { ILegionPreLiquidSaleV2Factory } from "../src/interfaces/factories/ILegionPreLiquidSaleV2Factory.sol";
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/access/LegionBouncer.sol";
import { LegionPreLiquidSaleV2 } from "../src/sales/LegionPreLiquidSaleV2.sol";
import { LegionPreLiquidSaleV2Factory } from "../src/factories/LegionPreLiquidSaleV2Factory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

/**
 * @title Legion Pre-Liquid Sale V2 Test
 * @author Legion
 * @notice Test suite for the LegionPreLiquidSaleV2 contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionPreLiquidSaleV2Test is Test {
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
        ILegionSale.LegionSaleInitializationParams saleInitParams; // Sale initialization parameters
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
     * @notice Template instance of the LegionPreLiquidSaleV2 contract for cloning
     * @dev Used as the base for creating new sale instances
     */
    LegionPreLiquidSaleV2 public preLiquidSaleV2Template;

    /**
     * @notice Registry for Legion-related addresses
     * @dev Manages addresses for Legion contracts and roles
     */
    LegionAddressRegistry public legionAddressRegistry;

    /**
     * @notice Factory contract for creating pre-liquid sale V2 instances
     * @dev Deploys new instances of LegionPreLiquidSaleV2
     */
    LegionPreLiquidSaleV2Factory public legionSaleFactory;

    /**
     * @notice Factory contract for creating vesting instances
     * @dev Deploys vesting contracts for token allocations
     */
    LegionVestingFactory public legionVestingFactory;

    /**
     * @notice Mock token used as the bidding currency
     * @dev Represents the token used for investments (e.g., USDC)
     */
    MockToken public bidToken;

    /**
     * @notice Mock token used as the sale token
     * @dev Represents the token being sold (e.g., LFG)
     */
    MockToken public askToken;

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
     * @notice Address representing a non-Legion admin
     * @dev Set to 0x08, used for unauthorized access tests
     */
    address public nonLegionAdmin = address(0x08);

    /**
     * @notice Address representing a non-project admin
     * @dev Set to 0x09, used for unauthorized access tests
     */
    address public nonProjectAdmin = address(0x09);

    /**
     * @notice Address representing the Legion fee receiver
     * @dev Set to 0x10, receives Legion fees
     */
    address public legionFeeReceiver = address(0x10);

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
    bytes32 public claimTokensMerkleRoot = 0xf1497b122b0d3850e93c6e95a35163a5f7715ca75ec6a031abe96622b46a6ee2;

    /**
     * @notice Merkle root for accepted capital
     * @dev Precomputed root for verifying accepted capital claims
     */
    bytes32 public acceptedCapitalMerkleRoot = 0x54c416133cce27821e67f6c475e59fcdafb30c065ea8feaac86970c532db0202;

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
        preLiquidSaleV2Template = new LegionPreLiquidSaleV2();
        legionSaleFactory = new LegionPreLiquidSaleV2Factory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
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
    function setSaleParams(ILegionSale.LegionSaleInitializationParams memory _saleInitParams) public {
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
    }

    /**
     * @notice Creates and initializes a LegionPreLiquidSaleV2 instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionPreLiquidSale() public {
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
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);
    }

    /**
     * @notice Mints tokens to investors and approves the sale instance contract
     * @dev Prepares bid tokens for investors to participate in the sale
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
     * @notice Mints tokens to the project and approves the sale instance contract
     * @dev Prepares ask tokens for the project admin to supply to the sale
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);

        MockToken(askToken).mint(projectAdmin, 10_000 * 1e18);
        MockToken(askToken).approve(legionSaleInstance, 10_000 * 1e18);

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
     * @notice Invests capital from all investors
     * @dev Simulates investments from all predefined investors
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
     * @notice Initializes the LegionAddressRegistry with required addresses
     * @dev Sets Legion bouncer, signer, fee receiver, and vesting factory addresses
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
     * @notice Prepares the investor vesting configuration
     * @dev Sets up a linear vesting schedule with predefined parameters
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 31_536_000, 3600, 0, 0, 1e17
        );
    }

    /**
     * @notice Retrieves the sale start time
     * @dev Queries the sale configuration for the start timestamp
     * @return uint256 The start time of the sale
     */
    function startTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Queries the sale configuration for the end timestamp
     * @return uint256 The end time of the sale
     */
    function endTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund end time
     * @dev Queries the sale configuration for the refund end timestamp
     * @return uint256 The end time of the refund period
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Queries the sale status for the total capital raised
     * @return saleTotalCapitalRaised The total capital raised in the sale
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionSale.LegionSaleStatus memory _saleStatusDetails =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).saleStatusDetails();
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
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).vestingConfiguration();

        // Assert
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV2(payable(legionSaleInstance)).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address fixedPriceSaleImplementation = legionSaleFactory.preLiquidSaleV2Template();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV2(payable(fixedPriceSaleImplementation)).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Assert
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionPreLiquidSaleV2(preLiquidSaleV2Template).initialize(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address configurations reverts
     * @dev Expects ZeroAddressProvided revert when addresses are zero
     */
    function test_createPreLiquidSale_revertsWithZeroAddressProvided() public {
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
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value configurations reverts
     * @dev Expects ZeroValueProvided revert when key parameters are zero
     */
    function test_createPreLiquidSale_revertsWithZeroValueProvided() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with an overly long period configuration reverts
     * @dev Expects InvalidPeriodConfig revert when periods exceed limits
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooLong() public {
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
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);
    }

    /**
     * @notice Tests that creating a sale with an overly short period configuration reverts
     * @dev Expects InvalidPeriodConfig revert when periods are below minimum
     */
    function test_createPreLiquidSale_revertsWithInvalidPeriodConfigTooShort() public {
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
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by Legion admin
     * @dev Expects Paused event emission when paused by legionBouncer
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
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
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
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
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
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
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

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.CapitalInvested(1000 * 1e6, investor1, startTime() + 1);

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing after the sale has ended reverts
     * @dev Expects SaleHasEnded revert when sale is no longer active
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
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing with an amount less than the minimum reverts
     * @dev Expects InvalidInvestAmount revert when investment is below threshold
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
     * @notice Tests that investing when the sale is canceled reverts
     * @dev Expects SaleIsCanceled revert when sale has been canceled
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
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects InvalidSignature revert when signature is not valid
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, invalidSignature);
    }

    /**
     * @notice Tests that investing after refunding reverts
     * @dev Expects InvestorHasRefunded revert when investor has already refunded
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

    /**
     * @notice Tests that investing after claiming excess capital reverts
     * @dev Expects InvestorHasClaimedExcess revert when excess capital is claimed
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);

        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(2000 * 1e6, signatureInv2);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               END SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful ending of the sale by project admin
     * @dev Expects SaleEnded event emission with correct timestamp
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
     * @notice Tests that ending the sale by non-project or non-Legion admin reverts
     * @dev Expects NotCalledByLegionOrProject revert when called by nonProjectAdmin
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
     * @notice Tests that ending the sale when paused reverts
     * @dev Expects EnforcedPause revert when sale is paused
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
     * @notice Tests that ending the sale when canceled reverts
     * @dev Expects SaleIsCanceled revert when sale is already canceled
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
     * @notice Tests that ending an already ended sale reverts
     * @dev Expects SaleHasEnded revert when sale is already ended
     */
    function test_endSale_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful publishing of capital raised and accepted capital merkle root
     * @dev Expects CapitalRaisedPublished event emission with correct parameters
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
     * @notice Tests that publishing capital raised by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
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
     * @notice Tests that publishing capital raised when sale is canceled reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
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
     * @notice Tests that publishing capital raised before sale ends reverts
     * @dev Expects SaleHasNotEnded revert when sale is still active
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
     * @notice Tests that publishing capital raised before refund period ends reverts
     * @dev Expects RefundPeriodIsNotOver revert when refund period is active
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
     * @notice Tests that publishing capital raised twice reverts
     * @dev Expects CapitalRaisedAlreadyPublished revert when already published
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
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        vm.expectEmit();
        emit ILegionSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Tests that emergency withdrawal by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by projectAdmin
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
     * @notice Tests that refunding after the refund period ends reverts
     * @dev Expects RefundPeriodIsOver revert when refund period has expired
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
     * @notice Tests that refunding when the sale is canceled reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
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
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects InvalidRefundAmount revert when no investment exists
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
     * @notice Tests that refunding twice reverts
     * @dev Expects InvestorHasRefunded revert when investor has already refunded
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

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful cancellation of the sale by project admin before results are published
     * @dev Expects SaleCanceled event emission
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
     * @notice Tests successful cancellation and capital return by project admin
     * @dev Verifies SaleCanceled event and capital return to sale contract
     */
    function test_cancelSale_successfullyCancelsIfCapitalToReturn() public {
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

        vm.startPrank(projectAdmin);
        MockToken(bidToken).mint(projectAdmin, 350 * 1e6);
        MockToken(bidToken).approve(legionSaleInstance, 10_000 * 1e6);
        vm.stopPrank();

        // Assert
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert
        assertEq(bidToken.balanceOf(legionSaleInstance), 10_000 * 1e6);
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects SaleIsCanceled revert when sale is already canceled
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
     * @notice Tests that canceling a sale after tokens are supplied reverts
     * @dev Expects TokensAlreadySupplied revert when tokens are supplied
     */
    function test_cancelSale_revertsIfTokensSupplied() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling a sale by non-project admin reverts
     * @dev Expects NotCalledByProject revert when called by investor1
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();
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
     * @notice Tests that withdrawing invested capital when sale is not canceled reverts
     * @dev Expects SaleIsNotCanceled revert when sale is still active
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
     * @notice Tests that withdrawing invested capital with no investment reverts
     * @dev Expects InvalidWithdrawAmount revert when no capital is invested
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
        ILegionPreLiquidSaleV2(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        // Assert
        vm.expectEmit();
        emit ILegionPreLiquidSaleV2.SaleResultsPublished(claimTokensMerkleRoot, 4000 * 1e18, address(askToken));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results twice reverts
     * @dev Expects TokensAlreadyAllocated revert when results are already published
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results before refund period ends reverts
     * @dev Expects RefundPeriodIsNotOver revert when refund period is active
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
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );
    }

    /**
     * @notice Tests that publishing sale results when sale is canceled reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
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

        // Assert
        vm.expectEmit();
        emit ILegionSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_setAcceptedCapital_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionPreLiquidSale();

        vm.warp(endTime() + 1);

        // Assert
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital when sale is canceled reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
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

    /*//////////////////////////////////////////////////////////////////////////
                           SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token supply for distribution by the project admin
     * @dev Verifies that supplying tokens after sale results are published emits the TokensSuppliedForDistribution
     * event with correct amounts (4000 LFG, 100 LFG Legion fee, 40 LFG referrer fee).
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange: Set up the sale and mint tokens for the project admin
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        // End the sale as project admin
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results as Legion bouncer
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect the TokensSuppliedForDistribution event with specified amounts
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act: Supply tokens as project admin
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect Legion fee amount reverts
     * @dev Ensures the contract rejects a supply attempt where the Legion fee (90 LFG) does not match the expected
     * amount based on the fee basis points (250 bps of 4000 LFG = 100 LFG).
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange: Set up the sale and mint tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        // End the sale as Legion bouncer (to allow publishing results)
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect revert due to incorrect Legion fee (90e18 instead of 100e18)
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act: Attempt to supply tokens with incorrect Legion fee
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect referrer fee amount reverts
     * @dev Ensures the contract rejects a supply attempt where the referrer fee (39 LFG) does not match the expected
     * amount based on the fee basis points (100 bps of 4000 LFG = 40 LFG).
     */
    function test_supplyTokens_revertsIfReferrerFeeIsIncorrect() public {
        // Arrange: Set up the sale and mint tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        // End the sale as Legion bouncer
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect revert due to incorrect referrer fee (39e18 instead of 40e18)
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act: Attempt to supply tokens with incorrect referrer fee
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 39 * 1e18);
    }

    /**
     * @notice Tests successful token supply when the Legion fee is set to zero
     * @dev Verifies that supplying tokens with a zero Legion fee (due to 0 bps) emits the correct event and works as
     * expected.
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange: Configure sale with zero Legion fee on tokens sold
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0, // Zero Legion fee on tokens sold
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Create the sale instance
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);

        // Mint and approve tokens for the project admin
        prepareMintAndApproveProjectTokens();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect event with zero Legion fee
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act: Supply tokens with zero Legion fee
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by a non-project admin reverts
     * @dev Ensures only the project admin can supply tokens, expecting a NotCalledByProject revert.
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale as project admin
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect revert due to non-project admin caller
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act: Attempt to supply tokens as non-project admin
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens when the sale is canceled reverts
     * @dev Ensures token supply is blocked after cancellation, expecting a SaleIsCanceled revert.
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Cancel the sale
        vm.warp(refundEndTime() + 1);
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert: Expect revert due to canceled sale
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act: Attempt to supply tokens after cancellation
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an incorrect amount reverts
     * @dev Ensures the supplied token amount matches the published result, expecting an InvalidTokenAmountSupplied
     * revert.
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results with 4000 LFG tokens
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect revert due to incorrect token amount (9990 LFG instead of 4000 LFG)
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 9990 * 1e18, 4000 * 1e18));

        // Act: Attempt to supply incorrect token amount
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens before sale results are published reverts
     * @dev Ensures tokens cannot be supplied without prior allocation, expecting a TokensNotAllocated revert.
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange: Set up the sale without publishing results
        prepareCreateLegionPreLiquidSale();

        // Assert: Expect revert due to missing sale results
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotAllocated.selector));

        // Act: Attempt to supply tokens before publishing results
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens a second time reverts
     * @dev Ensures tokens can only be supplied once, expecting a TokensAlreadySupplied revert.
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange: Set up the sale and mint tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveProjectTokens();

        // End the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Supply tokens once
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Assert: Expect revert due to tokens already being supplied
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act: Attempt to supply tokens again
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with an unavailable askToken reverts
     * @dev Ensures the contract rejects supply attempts when the askToken is not set, expecting an AskTokenUnavailable
     * revert.
     */
    function test_supplyTokens_revertsIfAskTokenUnavailable() public {
        // Arrange: Configure sale with no askToken
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
                askToken: address(0), // No askToken set
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Create the sale instance
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish sale results with no askToken
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(claimTokensMerkleRoot, 4000 * 1e18, address(0));

        // Assert: Expect revert due to unavailable askToken
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act: Attempt to supply tokens
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
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
        // Arrange: Set up the sale with investors and project tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        // Have all investors invest (total 10,000 USDC bid tokens)
        prepareInvestedCapitalFromAllInvestors();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish capital raised (10,000 USDC) with accepted capital merkle root
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Assert: Expect the CapitalWithdrawn event with total capital raised
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act: Withdraw raised capital as project admin
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert: Verify project admin receives capital minus fees
        // Fees: Legion = 250 bps (2.5%), Referrer = 100 bps (1%)
        // Total fees = 3.5% of 10,000 USDC = 350 USDC, so project admin gets 9,650 USDC
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
        // Arrange: Configure sale with zero Legion fee on capital raised
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 0, // No Legion fee on capital
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Create the sale instance
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);

        // Set up investors and project tokens, then invest
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Total 10,000 USDC bid tokens

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish capital raised
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Assert: Expect the CapitalWithdrawn event
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act: Withdraw raised capital
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert: Verify project admin receives capital minus referrer fee only
        // Referrer fee = 100 bps (1%) of 10,000 USDC = 100 USDC, so project admin gets 9,900 USDC
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @notice Tests that withdrawing capital by a non-project admin reverts
     * @dev Ensures only the project admin can withdraw capital, expecting a NotCalledByProject revert.
     */
    function test_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // Warp to after a hypothetical refund period (no capital raised yet)
        vm.warp(refundEndTime() + 1);

        // Assert: Expect revert due to non-project admin caller
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act: Attempt withdrawal as non-project admin
        vm.prank(nonProjectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before results are published reverts
     * @dev Ensures capital cannot be withdrawn without publishing results, expecting a CapitalRaisedNotPublished
     * revert.
     */
    function test_withdrawRaisedCapital_revertsIfCapitalRaisedNotPublished() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Assert: Expect revert due to unpublished capital raised
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalRaisedNotPublished.selector));

        // Act: Attempt withdrawal without publishing results
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before the refund period ends reverts
     * @dev Ensures withdrawal is blocked during the refund period, expecting a RefundPeriodIsNotOver revert.
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to before the refund period ends
        vm.warp(refundEndTime() - 1);

        // Assert: Expect revert due to active refund period
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act: Attempt withdrawal during refund period
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital after the sale is canceled reverts
     * @dev Ensures withdrawal is blocked when the sale is canceled, expecting a SaleIsCanceled revert.
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // End the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Cancel the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert: Expect revert due to canceled sale
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act: Attempt withdrawal after cancellation
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Ensures capital can only be withdrawn once, expecting a CapitalAlreadyWithdrawn revert on the second
     * attempt.
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange: Set up the sale with investors and project tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        // Have all investors invest (10,000e6 bid tokens)
        prepareInvestedCapitalFromAllInvestors();

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        vm.warp(refundEndTime() + 1);

        // Publish capital raised
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishCapitalRaised(10_000 * 1e6, acceptedCapitalMerkleRoot);

        // Withdraw capital once
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();

        // Assert: Expect revert due to capital already withdrawn
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalAlreadyWithdrawn.selector));

        // Act: Attempt second withdrawal
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawRaisedCapital();
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
        // Arrange: Set up the sale with investor contributions
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC

        // Define Merkle proof for investor2's excess claim (1000 USDC excess out of 2000 USDC invested)
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        // Warp to after the sale ends
        vm.warp(endTime() + 1);

        // Set the accepted capital Merkle root
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act: Investor2 withdraws excess capital
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert: Verify investor position and balance
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true); // Excess claim flag updated
        assertEq(MockToken(bidToken).balanceOf(investor2), 1000 * 1e6); // Excess returned (2000 USDC - 1000 USDC
            // accepted)
    }

    /**
     * @notice Tests that withdrawing excess capital reverts if the sale is canceled
     * @dev Ensures excess withdrawal is blocked when the sale is canceled, expecting a SaleIsCanceled revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // Define a Merkle proof for investor2
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        // Cancel the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Warp to after the sale would have ended
        vm.warp(endTime() + 1);

        // Assert: Expect revert due to canceled sale
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act: Attempt to withdraw excess capital
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital with an incorrect Merkle proof reverts
     * @dev Ensures the contract rejects an invalid proof for investor2, expecting a CannotWithdrawExcessInvestedCapital
     * revert.
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange: Set up the sale with investor contributions
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC

        // Define an incorrect Merkle proof for investor2 (last byte altered: 708 -> 707)
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612707);

        // Set the accepted capital Merkle root
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Assert: Expect revert due to invalid Merkle proof
        vm.expectRevert(
            abi.encodeWithSelector(Errors.CannotWithdrawExcessInvestedCapital.selector, investor2, 1000 * 1e6)
        );

        // Act: Attempt withdrawal with incorrect proof
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Ensures an investor cannot claim excess capital more than once, expecting an AlreadyClaimedExcess revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange: Set up the sale with investor contributions
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC

        // Define Merkle proof for investor2's excess claim
        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        // Warp to after the sale ends
        vm.warp(endTime() + 1);

        // Set the accepted capital Merkle root
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // First withdrawal of excess capital
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert: Expect revert due to excess already claimed
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyClaimedExcess.selector, investor2));

        // Act: Attempt second withdrawal
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital with no prior investment reverts
     * @dev Ensures an investor who didn’t invest cannot claim excess, expecting a NoCapitalInvested revert.
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange: Set up the sale without investor5 investing
        prepareCreateLegionPreLiquidSale();

        // Define Merkle proof for investor5 (who didn’t invest)
        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);
        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        // Warp to after the sale ends
        vm.warp(endTime() + 1);

        // Set a malicious excess capital Merkle root (for testing purposes)
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).setAcceptedCapital(excessCapitalMerkleRootMalicious);

        // Assert: Expect revert due to no capital invested by investor5
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act: Attempt withdrawal by investor5
        vm.prank(investor5);
        ILegionPreLiquidSaleV2(legionSaleInstance).withdrawExcessInvestedCapital(6000 * 1e6, excessClaimProofInvestor5);
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
        // Arrange: Set up the sale with investor contributions and project tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC bid tokens

        // Define Merkle proof for investor2's token claim (1000 LFG tokens)
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        // Publish sale results (total tokens: 4000 LFG)
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Supply tokens for distribution (4000 USDC + fees)
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act: Investor2 claims their token allocation
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Assert: Verify investor position and vesting details
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).investorPositionDetails(investor2);
        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionPreLiquidSaleV2(payable(legionSaleInstance)).investorVestingStatus(investor2);

        assertEq(_investorPosition.hasSettled, true); // Investor has claimed tokens
        assertEq(MockToken(askToken).balanceOf(_investorPosition.vestingAddress), 9000 * 1e17); // 900 LFG tokens

        // Vesting config: Linear, 0 start, 1 year duration (31,536,000s), 1 hour cliff (3600s), 10% initial release
        // (1e17)
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
     * @dev Ensures token claims are blocked during the refund period, expecting a RefundPeriodIsNotOver revert.
     */
    function test_claimTokenAllocation_revertsIfRefundPeriodHasNotEnded() public {
        // Arrange: Set up the sale with investor contributions
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        // Define Merkle proof for investor2
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after refund period for publishing results
        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Warp back to within refund period
        vm.warp(refundEndTime() - 1);

        // Assert: Expect revert due to active refund period
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act: Attempt to claim tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming more tokens than allocated reverts
     * @dev Ensures investor2 cannot claim 2000 LFG when only 1000 LFG is allocated, expecting a NotInClaimWhitelist
     * revert.
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // Define Merkle proof for investor2 (valid for 1000 LFG)
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after refund period and publish results
        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Assert: Expect revert due to claiming more than allocated (2000 LFG > 1000 LFG)
        vm.expectRevert(abi.encodeWithSelector(Errors.NotInClaimWhitelist.selector, investor2));

        // Act: Attempt to claim excess tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            2000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens twice reverts
     * @dev Ensures investor2 cannot claim again after a successful claim, expecting an AlreadySettled revert.
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyClaimed() public {
        // Arrange: Set up the sale with investor contributions and project tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        // Define Merkle proof for investor2
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale and set up for claiming
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // First claim by investor2
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Assert: Expect revert due to already claimed tokens
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor2));

        // Act: Attempt second claim
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens when the sale is canceled reverts
     * @dev Ensures token claims are blocked after cancellation, expecting a SaleIsCanceled revert.
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange: Set up the sale with investor contributions
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        // Define Merkle proof for investor2
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale and publish results
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        // Cancel the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).cancelSale();

        // Assert: Expect revert due to canceled sale
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act: Attempt to claim tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens before sale results are published reverts
     * @dev Ensures token claims are blocked without published results, expecting a SaleResultsNotPublished revert.
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange: Set up the sale without publishing results
        prepareCreateLegionPreLiquidSale();

        // Define Merkle proof for investor2
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // Warp to after refund period
        vm.warp(refundEndTime() + 1);

        // Assert: Expect revert due to unpublished sale results
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act: Attempt to claim tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens with an unavailable askToken reverts
     * @dev Ensures token claims fail when no askToken is set, expecting an AskTokenUnavailable revert.
     */
    function test_claimTokenAllocation_revertsIfAskTokenNotAvailable() public {
        // Arrange: Configure sale with no askToken
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
                askToken: address(0), // No askToken
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Create the sale instance
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);

        // Define Merkle proof for investor2
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // Assert: Expect revert due to unavailable askToken
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act: Attempt to claim tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
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
        // Arrange: Set up the sale with investor contributions and project tokens
        prepareCreateLegionPreLiquidSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors(); // Investor2 invests 2000 USDC bid tokens

        // Define Merkle proof for investor2's token claim (1000 LFG tokens)
        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        // End the sale
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).endSale();

        // Warp to after the refund period
        uint256 refundEnd = refundEndTime();
        vm.warp(refundEnd + 1);

        // Publish sale results and supply tokens
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, 4000 * 1e18, address(askToken)
        );

        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Investor2 claims their allocation
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Act: Investor2 releases vested tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();

        // Assert: Verify tokens released to investor2
        assertEq(MockToken(askToken).balanceOf(investor2), 134_520_605_022_831_050_228);
    }

    /**
     * @notice Tests that releasing vested tokens without a vesting contract reverts
     * @dev Ensures an investor without a deployed vesting contract cannot release tokens, expecting a
     * ZeroAddressProvided revert.
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange: Set up the sale without investor2 claiming tokens
        prepareCreateLegionPreLiquidSale();

        // Assert: Expect revert due to no vesting contract (zero address)
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act: Attempt to release vested tokens
        vm.prank(investor2);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();
    }

    /**
     * @notice Tests that releasing vested tokens with an unavailable askToken reverts
     * @dev Ensures token release fails when no askToken is set, expecting an AskTokenUnavailable revert.
     */
    function test_releaseVestedTokens_revertsIfAskTokenNotAvailable() public {
        // Arrange: Configure sale with no askToken
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
                askToken: address(0), // No askToken
                projectAdmin: address(projectAdmin),
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: address(nonLegionAdmin)
            })
        );

        // Create the sale instance
        vm.prank(legionBouncer);
        legionSaleInstance = legionSaleFactory.createPreLiquidSaleV2(testConfig.saleInitParams);

        // Assert: Expect revert due to unavailable askToken
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act: Attempt to release vested tokens
        vm.prank(investor1);
        ILegionPreLiquidSaleV2(legionSaleInstance).releaseVestedTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                    SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful synchronization of Legion addresses by a Legion admin
     * @dev Verifies that syncing updates the contract’s Legion addresses from the registry, emitting
     * LegionAddressesSynced
     *      with the updated fee receiver (address(1)).
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // Update the Legion fee receiver in the registry
        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Assert: Expect the LegionAddressesSynced event with updated addresses
        vm.expectEmit();
        emit ILegionSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act: Sync Legion addresses as Legion bouncer
        vm.prank(legionBouncer);
        ILegionPreLiquidSaleV2(legionSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by a non-Legion admin reverts
     * @dev Ensures only Legion admins can sync addresses, expecting a NotCalledByLegion revert when called by
     * projectAdmin.
     */
    function test_syncLegionAddresses_revertsIfNotCalledByLegion() public {
        // Arrange: Set up the sale
        prepareCreateLegionPreLiquidSale();

        // Assert: Expect revert due to non-Legion caller
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act: Attempt to sync addresses as project admin
        vm.prank(projectAdmin);
        ILegionPreLiquidSaleV2(legionSaleInstance).syncLegionAddresses();
    }
}
