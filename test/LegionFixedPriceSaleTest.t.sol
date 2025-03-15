// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Test, Vm } from "forge-std/Test.sol";

import { Errors } from "../src/utils/Errors.sol";

import { ILegionFixedPriceSale } from "../src/interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionSale } from "../src/interfaces/sales/ILegionSale.sol";
import { ILegionVestingManager } from "../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../src/access/LegionBouncer.sol";
import { LegionFixedPriceSale } from "../src/sales/LegionFixedPriceSale.sol";
import { LegionFixedPriceSaleFactory } from "../src/factories/LegionFixedPriceSaleFactory.sol";
import { LegionVestingFactory } from "../src/factories/LegionVestingFactory.sol";
import { MockToken } from "../src/mocks/MockToken.sol";

/**
 * @title Legion Fixed Price Sale Test
 * @author Legion
 * @notice Test suite for the LegionFixedPriceSale contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionFixedPriceSaleTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                   STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct to hold sale test configuration
    struct SaleTestConfig {
        ILegionSale.LegionSaleInitializationParams saleInitParams;
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Vesting configuration for investors
    ILegionVestingManager.LegionInvestorVestingConfig investorVestingConfig;

    /// @notice Configuration for the sale test
    SaleTestConfig testConfig;

    /// @notice Template instance of the LegionFixedPriceSale contract
    LegionFixedPriceSale public fixedPriceSaleTemplate;

    /// @notice Instance of the LegionAddressRegistry contract for address management
    LegionAddressRegistry public legionAddressRegistry;

    /// @notice Instance of the LegionFixedPriceSaleFactory contract for sale creation
    LegionFixedPriceSaleFactory public legionSaleFactory;

    /// @notice Instance of the LegionVestingFactory contract for vesting management
    LegionVestingFactory public legionVestingFactory;

    /// @notice Mock token used as the bid token (e.g., USDC)
    MockToken public bidToken;

    /// @notice Mock token used as the ask token (e.g., LFG)
    MockToken public askToken;

    /// @notice Decimals of the ask token
    uint8 askTokenDecimals;

    /// @notice Address of the deployed LegionFixedPriceSale instance
    address legionSaleInstance;

    /// @notice Address representing the AWS broadcaster
    address awsBroadcaster = address(0x10);

    /// @notice Address representing the Legion EOA (External Owned Account)
    address legionEOA = address(0x01);

    /// @notice Address of the deployed LegionBouncer contract
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing the project admin
    address projectAdmin = address(0x02);

    /// @notice Test investor addresses
    address investor1 = address(0x03);
    address investor2 = address(0x04);
    address investor3 = address(0x05);
    address investor4 = address(0x06);
    address investor5 = address(0x07);

    /// @notice Address representing a non-Legion admin
    address nonLegionAdmin = address(0x08);

    /// @notice Address representing a non-project admin
    address nonProjectAdmin = address(0x09);

    /// @notice Address representing the Legion fee receiver
    address legionFeeReceiver = address(0x10);

    /// @notice Signatures for investors
    bytes signatureInv1;
    bytes signatureInv2;
    bytes signatureInv3;
    bytes signatureInv4;
    bytes invalidSignature;

    /// @notice Private key for generating the Legion signer address
    uint256 legionSignerPK = 1234;

    /// @notice Private key for generating an invalid signer address
    uint256 nonLegionSignerPK = 12_345;

    /// @notice Merkle roots for testing
    bytes32 claimTokensMerkleRoot = 0xf1497b122b0d3850e93c6e95a35163a5f7715ca75ec6a031abe96622b46a6ee2;
    bytes32 acceptedCapitalMerkleRoot = 0x54c416133cce27821e67f6c475e59fcdafb30c065ea8feaac86970c532db0202;
    bytes32 acceptedCapitalMerkleRootMalicious = 0x04169dca2cf842bea9fcf4df22c9372c6d6f04410bfa446585e287aa1c834974;

    /*//////////////////////////////////////////////////////////////////////////
                                  SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets up the test environment by deploying necessary contracts
     * @dev Deploys factory, vesting factory, registry, tokens, and configures registry and vesting
     */
    function setUp() public {
        fixedPriceSaleTemplate = new LegionFixedPriceSale();
        legionSaleFactory = new LegionFixedPriceSaleFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockToken("USD Coin", "USDC", 6);
        askToken = new MockToken("LFG Coin", "LFG", 18);
        askTokenDecimals = uint8(askToken.decimals());
        prepareLegionAddressRegistry();
        prepareInvestorVestingConfig();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Configures the sale parameters for testing
     * @dev Sets the sale and fixed price sale initialization parameters in the testConfig struct
     * @param _saleInitParams General sale initialization parameters
     * @param _fixedPriceSaleInitParams Fixed price sale-specific initialization parameters
     */
    function setSaleParams(
        ILegionSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory _fixedPriceSaleInitParams
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

        testConfig.fixedPriceSaleInitParams = ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
            prefundPeriodSeconds: _fixedPriceSaleInitParams.prefundPeriodSeconds,
            prefundAllocationPeriodSeconds: _fixedPriceSaleInitParams.prefundAllocationPeriodSeconds,
            tokenPrice: _fixedPriceSaleInitParams.tokenPrice
        });
    }

    /**
     * @notice Creates and initializes a LegionFixedPriceSale instance for testing
     * @dev Sets default parameters and deploys a sale instance as legionBouncer
     */
    function prepareCreateLegionFixedPriceSale() public {
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: nonLegionAdmin
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Mints tokens to investors and approves the sale instance
     * @dev Prepares investors with bid tokens and approves spending by the sale contract
     */
    function prepareMintAndApproveInvestorTokens() public {
        vm.startPrank(legionBouncer);
        bidToken.mint(investor1, 1000 * 1e6);
        bidToken.mint(investor2, 2000 * 1e6);
        bidToken.mint(investor3, 3000 * 1e6);
        bidToken.mint(investor4, 4000 * 1e6);
        vm.stopPrank();

        vm.prank(investor1);
        bidToken.approve(legionSaleInstance, 1000 * 1e6);

        vm.prank(investor2);
        bidToken.approve(legionSaleInstance, 2000 * 1e6);

        vm.prank(investor3);
        bidToken.approve(legionSaleInstance, 3000 * 1e6);

        vm.prank(investor4);
        bidToken.approve(legionSaleInstance, 4000 * 1e6);
    }

    /**
     * @notice Mints tokens to the project admin and approves the sale instance
     * @dev Prepares the project with ask tokens and approves spending by the sale contract
     */
    function prepareMintAndApproveProjectTokens() public {
        vm.startPrank(projectAdmin);
        askToken.mint(projectAdmin, 10_000 * 1e18);
        askToken.approve(legionSaleInstance, 10_000 * 1e18);
        vm.stopPrank();
    }

    /**
     * @notice Generates investor signatures for authentication
     * @dev Creates valid and invalid signatures using legionSignerPK and nonLegionSignerPK
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
     * @notice Invests capital from all test investors
     * @dev Simulates investments by investors using their signatures
     */
    function prepareInvestedCapitalFromAllInvestors() public {
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.prank(investor3);
        ILegionFixedPriceSale(legionSaleInstance).invest(3000 * 1e6, signatureInv3);

        vm.prank(investor4);
        ILegionFixedPriceSale(legionSaleInstance).invest(4000 * 1e6, signatureInv4);
    }

    /**
     * @notice Configures the LegionAddressRegistry with necessary addresses
     * @dev Sets bouncer, signer, fee receiver, and vesting factory addresses as legionBouncer
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
     * @dev Configures a linear vesting schedule with predefined parameters
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 31_536_000, 3600, 0, 0, 1e17
        );
    }

    /**
     * @notice Retrieves the sale start time
     * @dev Fetches the start time from the sale configuration
     * @return uint256 The sale start time in seconds
     */
    function startTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Fetches the end time from the sale configuration
     * @return uint256 The sale end time in seconds
     */
    function endTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund period end time
     * @dev Fetches the refund end time from the sale configuration
     * @return uint256 The refund period end time in seconds
     */
    function refundEndTime() public view returns (uint256) {
        ILegionSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Fetches the total capital raised from the sale status
     * @return saleTotalCapitalRaised The total capital raised in bid tokens
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionSale.LegionSaleStatus memory _saleStatusDetails =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatusDetails();
        return _saleStatusDetails.totalCapitalRaised;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that the sale is deployed with valid parameters
     * @dev Verifies token price and vesting factory configuration after deployment
     */
    function test_createFixedPriceSale_successfullyDeployedWithValidParameters() public {
        prepareCreateLegionFixedPriceSale();

        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).vestingConfiguration();
        ILegionFixedPriceSale.FixedPriceSaleConfiguration memory _fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).fixedPriceSaleConfiguration();

        assertEq(_fixedPriceSaleConfig.tokenPrice, 1e6);
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
    }

    /**
     * @notice Tests that re-initialization of an already initialized sale reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        prepareCreateLegionFixedPriceSale();

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        LegionFixedPriceSale(payable(legionSaleInstance)).initialize(
            testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        address fixedPriceSaleImplementation = legionSaleFactory.fixedPriceSaleTemplate();

        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        LegionFixedPriceSale(payable(fixedPriceSaleImplementation)).initialize(
            testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));
        fixedPriceSaleTemplate.initialize(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address parameters reverts
     * @dev Expects ZeroAddressProvided revert when addresses are zero
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 1 hours,
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
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value parameters reverts
     * @dev Expects ZeroValueProvided revert when testConfig is uninitialized
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroValueProvided.selector));

        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with periods exceeding maximum reverts
     * @dev Expects InvalidPeriodConfig revert for periods longer than allowed
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooLong() public {
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 12 weeks + 1, // 12 weeks + 1
                refundPeriodSeconds: 2 weeks + 1,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: nonLegionAdmin
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 12 weeks + 1, // 12 weeks + 1
                prefundAllocationPeriodSeconds: 2 weeks + 1,
                tokenPrice: 1e6
            })
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with periods below minimum reverts
     * @dev Expects InvalidPeriodConfig revert for periods shorter than allowed
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooShort() public {
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: nonLegionAdmin
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours - 1,
                prefundAllocationPeriodSeconds: 1 hours - 1,
                tokenPrice: 1e6
            })
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidPeriodConfig.selector));

        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that the sale can be paused by the Legion admin
     * @dev Expects a Paused event emission when paused by legionBouncer
     */
    function test_pauseSale_successfullyPauseTheSale() public {
        prepareCreateLegionFixedPriceSale();

        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pauseSale();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_pauseSale_revertsIfCalledByNonLegionAdmin() public {
        prepareCreateLegionFixedPriceSale();

        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).pauseSale();
    }

    /**
     * @notice Tests that the sale can be unpaused by the Legion admin
     * @dev Expects an Unpaused event emission after pausing and unpausing
     */
    function test_unpauseSale_successfullyUnpauseTheSale() public {
        prepareCreateLegionFixedPriceSale();

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pauseSale();

        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).unpauseSale();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_unpauseSale_revertsIfNotCalledByLegionAdmin() public {
        prepareCreateLegionFixedPriceSale();

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pauseSale();

        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).unpauseSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that investing during the active sale period succeeds
     * @dev Expects CapitalInvested event with prefund=false after sale start
     */
    function test_invest_successfullyEmitsCapitalInvestedNotPrefund() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);

        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalInvested(1000 * 1e6, investor1, false, startTime() + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing during prefund allocation period reverts
     * @dev Expects PrefundAllocationPeriodNotEnded revert before sale start
     */
    function test_invest_revertsIfPrefundAllocationPeriodNotEnded() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() - 1);

        vm.expectRevert(abi.encodeWithSelector(Errors.PrefundAllocationPeriodNotEnded.selector, (startTime() - 1)));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing during prefund period succeeds
     * @dev Expects CapitalInvested event with prefund=true before sale start
     */
    function test_invest_successfullyEmitsCapitalInvestedPrefund() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalInvested(1000 * 1e6, investor1, true, block.timestamp);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing after the sale ends reverts
     * @dev Expects SaleHasEnded revert after endTime
     */
    function test_invest_revertsIfSaleHasEnded() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector, (endTime() + 1)));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing below the minimum amount reverts
     * @dev Expects InvalidInvestAmount revert for amount less than 1e6
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidInvestAmount.selector, 1 * 1e5));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1 * 1e5, signatureInv1);
    }

    /**
     * @notice Tests that investing in a canceled sale reverts
     * @dev Expects SaleIsCanceled revert after cancellation
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects InvalidSignature revert with a non-Legion signer signature
     */
    function test_invest_revertsIfInvalidSignature() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidSignature.selector, invalidSignature));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, invalidSignature);
    }

    /**
     * @notice Tests that reinvesting after refunding reverts
     * @dev Expects InvestorHasRefunded revert after investor refunds
     */
    function test_invest_revertsIfInvestorHasRefunded() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that reinvesting after claiming excess capital reverts
     * @dev Expects InvestorHasClaimedExcess revert after excess withdrawal
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = 0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188;
        excessClaimProofInvestor2[1] = 0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708;

        vm.warp(endTime() - 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasClaimedExcess.selector, investor2));
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EMERGENCY WITHDRAW TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that emergency withdrawal by Legion admin succeeds
     * @dev Expects EmergencyWithdraw event and verifies funds are transferred to legionBouncer
     */
    function test_emergencyWithdraw_successfullyWithdrawByLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Tests that emergency withdrawal by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect revert with NotCalledByLegion error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    REFUND TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that refunding during the refund period succeeds
     * @dev Expects CapitalRefunded event and verifies investor balance after refund
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.CapitalRefunded(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        // Assert
        uint256 investor1Balance = bidToken.balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @notice Tests that refunding after the refund period ends reverts
     * @dev Expects RefundPeriodIsOver revert when called after refundEndTime
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Expect revert with RefundPeriodIsOver error
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsOver.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding from a canceled sale reverts
     * @dev Expects SaleIsCanceled revert after sale cancellation
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding with no invested capital reverts
     * @dev Expects InvalidRefundAmount revert when investor has not invested
     */
    function test_refund_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Expect revert with InvalidRefundAmount error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRefundAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding after already refunded reverts
     * @dev Expects InvestorHasRefunded revert when investor attempts second refund
     */
    function test_refund_revertsIfInvestorHasRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(endTime() + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        // Expect revert with InvestorHasRefunded error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CANCEL SALE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that canceling the sale by project admin before results are published succeeds
     * @dev Expects SaleCanceled event when called by projectAdmin before results publication
     */
    function test_cancelSale_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects SaleIsCanceled revert when attempting to cancel twice
     */
    function test_cancelSale_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling after results are published reverts
     * @dev Expects SaleResultsAlreadyPublished revert after results are set
     */
    function test_cancelSale_revertsIfResultsArePublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with SaleResultsAlreadyPublished error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects NotCalledByProject revert when called by investor1
     */
    function test_cancelSale_revertsIfCalledByNonProjectAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect revert with NotCalledByProject error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();
    }

    /*//////////////////////////////////////////////////////////////////////////
                  WITHDRAW INVESTED CAPITAL IF CANCELED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that withdrawing invested capital after cancellation succeeds
     * @dev Expects CapitalRefundedAfterCancel event and verifies investor balance
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Assert
        assertEq(bidToken.balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing invested capital without cancellation reverts
     * @dev Expects SaleIsNotCanceled revert when sale is active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect revert with SaleIsNotCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing with no invested capital after cancellation reverts
     * @dev Expects InvalidWithdrawAmount revert when investor has not invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with InvalidWithdrawAmount error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidWithdrawAmount.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLISH SALE RESULTS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that publishing sale results by Legion admin succeeds
     * @dev Expects SaleResultsPublished event after refund period ends
     */
    function test_publishSaleResults_successfullyEmitsSaleResultsPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Expect event emission
        vm.expectEmit();
        emit ILegionFixedPriceSale.SaleResultsPublished(claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_publishSaleResults_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect revert with NotCalledByLegion error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results a second time reverts
     * @dev Expects TokensAlreadyAllocated revert when results are already published
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with TokensAlreadyAllocated error
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadyAllocated.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results before refund period ends reverts
     * @dev Expects RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_publishSaleResults_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() - 1);

        // Expect revert with RefundPeriodIsNotOver error
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results after cancellation reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SET ACCEPTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that setting accepted capital by Legion admin succeeds
     * @dev Expects AcceptedCapitalSet event before sale ends
     */
    function test_setAcceptedCapital_successfullyEmitsExcessInvestedCapitalSet() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(endTime() - 1);

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by nonLegionAdmin
     */
    function test_setAcceptedCapital_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(endTime() + 1);

        // Expect revert with NotCalledByLegion error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital after refund period reverts
     * @dev Expects SaleHasEnded revert when called after refundEndTime
     */
    function test_setAcceptedCapital_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        // Expect revert with SaleHasEnded error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleHasEnded.selector, (refundEndTime() + 1)));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital after cancellation reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that supplying tokens by project admin succeeds
     * @dev Expects TokensSuppliedForDistribution event after results are published
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect Legion fee reverts
     * @dev Expects InvalidFeeAmount revert when Legion fee is less than expected
     */
    function test_supplyTokens_revertsIfLegionFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with InvalidFeeAmount error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect referrer fee reverts
     * @dev Expects InvalidFeeAmount revert when referrer fee is less than expected
     */
    function test_supplyTokens_revertsIfReferrerFeeIsIncorrect() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with InvalidFeeAmount error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidFeeAmount.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 39 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with zero Legion fee succeeds
     * @dev Expects TokensSuppliedForDistribution event with zero Legion fee
     */
    function test_supplyTokens_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
        setSaleParams(
            ILegionSale.LegionSaleInitializationParams({
                salePeriodSeconds: 1 hours,
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                legionFeeOnTokensSoldBps: 0,
                referrerFeeOnCapitalRaisedBps: 100,
                referrerFeeOnTokensSoldBps: 100,
                minimumInvestAmount: 1e6,
                bidToken: address(bidToken),
                askToken: address(askToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: nonLegionAdmin
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);

        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by non-project admin reverts
     * @dev Expects NotCalledByProject revert when called by nonProjectAdmin
     */
    function test_supplyTokens_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with NotCalledByProject error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens after cancellation reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect amount reverts
     * @dev Expects InvalidTokenAmountSupplied revert when amount mismatches allocation
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with InvalidTokenAmountSupplied error
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidTokenAmountSupplied.selector, 9990 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens before results are published reverts
     * @dev Expects TokensNotAllocated revert when results are not set
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect revert with TokensNotAllocated error
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens a second time reverts
     * @dev Expects TokensAlreadySupplied revert when tokens are already supplied
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveProjectTokens();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect revert with TokensAlreadySupplied error
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with unavailable askToken reverts
     * @dev Expects AskTokenUnavailable revert when askToken is address(0)
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: nonLegionAdmin
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with AskTokenUnavailable error
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            WITHDRAW RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that withdrawing capital by project admin succeeds after results and token supply
     * @dev Expects CapitalWithdrawn event and verifies balance after fees are deducted
     */
    function test_withdrawRaisedCapital_successfullyEmitsCapitalWithdraw() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        assertEq(
            bidToken.balanceOf(projectAdmin),
            capitalRaised() - capitalRaised() * 250 / 10_000 - capitalRaised() * 100 / 10_000
        );
    }

    /**
     * @notice Tests that withdrawing capital succeeds when Legion fee is zero
     * @dev Expects CapitalWithdrawn event and verifies balance with only referrer fee deducted
     */
    function test_withdrawRaisedCapital_successfullyEmitsIfLegionFeeIsZero() public {
        // Arrange
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
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);

        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.expectEmit();
        emit ILegionSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.CapitalWithdrawn(capitalRaised(), projectAdmin);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @notice Tests that withdrawing capital by non-project admin reverts
     * @dev Expects NotCalledByProject revert when called by nonProjectAdmin
     */
    function test_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        // Expect revert with NotCalledByProject error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital without supplied tokens reverts
     * @dev Expects TokensNotSupplied revert when tokens are not supplied
     */
    function test_withdrawRaisedCapital_revertsIfNoTokensSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with TokensNotSupplied error
        vm.expectRevert(abi.encodeWithSelector(Errors.TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before results are published reverts
     * @dev Expects SaleResultsNotPublished revert when results are not set
     */
    function test_withdrawRaisedCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        // Expect revert with SaleResultsNotPublished error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before refund period ends reverts
     * @dev Expects RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() - 1);

        // Expect revert with RefundPeriodIsNotOver error
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital after sale cancellation reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Expects CapitalAlreadyWithdrawn revert when capital is already withdrawn
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.startPrank(projectAdmin);

        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();

        vm.stopPrank();

        // Expect revert with CapitalAlreadyWithdrawn error
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital with no raised amount reverts
     * @dev Expects CapitalNotRaised revert when no capital is available
     */
    function test_withdrawRaisedCapital_revertsIfNoCapitalRaised() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 1, askTokenDecimals
        );

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(1, 0, 0);

        // Expect revert with CapitalNotRaised error
        vm.expectRevert(abi.encodeWithSelector(Errors.CapitalNotRaised.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                    WITHDRAW EXCESS INVESTED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that withdrawing excess invested capital succeeds
     * @dev Verifies excess capital transfer and investor position update with valid proof
     */
    function test_withdrawExcessInvestedCapital_successfullyTransfersBackExcessCapital() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPositionDetails(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true);
        assertEq(bidToken.balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing excess capital from a canceled sale reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled before withdrawal
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        vm.warp(endTime() + 1);

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital with invalid proof reverts
     * @dev Expects CannotWithdrawExcessInvestedCapital revert with incorrect Merkle proof
     */
    function test_withdrawExcessInvestedCapital_revertsWithIncorrectProof() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612707);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Expect revert with CannotWithdrawExcessInvestedCapital error
        vm.expectRevert(abi.encodeWithSelector(Errors.CannotWithdrawExcessInvestedCapital.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Expects AlreadyClaimedExcess revert when excess is already claimed
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor2[1] = bytes32(0xcbe43c4b6aafb4df43acc0bebce3220a96e982592e3c306730bf73681c612708);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.warp(endTime() + 1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Expect revert with AlreadyClaimedExcess error
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital without investment reverts
     * @dev Expects NoCapitalInvested revert for an investor with no prior investment
     */
    function test_withdrawExcessInvestedCapital_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        bytes32[] memory excessClaimProofInvestor5 = new bytes32[](3);
        excessClaimProofInvestor5[0] = bytes32(0x048605503187722f63911ca26b8cca1d0a2afc10509c8be7f963371fec52b188);
        excessClaimProofInvestor5[1] = bytes32(0xe3d631b26859e467c1b67a022155b59ea1d0c431074ce3cc5b424d06e598ce5b);
        excessClaimProofInvestor5[2] = bytes32(0xe2c834aa6df188c7ae16c529aafb5e7588aa06afcced782a044b70652cadbdc3);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRootMalicious);

        // Expect revert with NoCapitalInvested error
        vm.expectRevert(abi.encodeWithSelector(Errors.NoCapitalInvested.selector, investor5));

        // Act
        vm.prank(investor5);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(6000 * 1e6, excessClaimProofInvestor5);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM TOKEN ALLOCATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that claiming tokens after sale completion succeeds
     * @dev Verifies token transfer to vesting contract and investor position update
     */
    function test_claimTokenAllocation_successfullyTransfersTokensToVestingContract() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Assert
        ILegionSale.InvestorPosition memory _investorPosition =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPositionDetails(investor2);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorVestingStatus(investor2);

        assertEq(_investorPosition.hasSettled, true);
        assertEq(askToken.balanceOf(_investorPosition.vestingAddress), 9000 * 1e17);

        assertEq(vestingStatus.start, 0);
        assertEq(vestingStatus.end, 31_536_000);
        assertEq(vestingStatus.cliffEnd, 3600);
        assertEq(vestingStatus.duration, 31_536_000);
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 34_828_824_200_913_242_009);
        assertEq(vestingStatus.vestedAmount, 34_828_824_200_913_242_009);
    }

    /**
     * @notice Tests that claiming tokens before refund period ends reverts
     * @dev Expects RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_claimTokenAllocation_revertsIfRefundPeriodHasNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(refundEndTime() - 1);

        // Expect revert with RefundPeriodIsNotOver error
        vm.expectRevert(abi.encodeWithSelector(Errors.RefundPeriodIsNotOver.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming more tokens than allocated reverts
     * @dev Expects NotInClaimWhitelist revert with invalid token amount or proof
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect revert with NotInClaimWhitelist error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            2000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens twice reverts
     * @dev Expects AlreadySettled revert when tokens are already claimed
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyClaimed() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        // Expect revert with AlreadySettled error
        vm.expectRevert(abi.encodeWithSelector(Errors.AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens from a canceled sale reverts
     * @dev Expects SaleIsCanceled revert when sale is canceled
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancelSale();

        // Expect revert with SaleIsCanceled error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens before results are published reverts
     * @dev Expects SaleResultsNotPublished revert when results are not set
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        // Expect revert with SaleResultsNotPublished error
        vm.expectRevert(abi.encodeWithSelector(Errors.SaleResultsNotPublished.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens with unavailable ask token reverts
     * @dev Expects AskTokenUnavailable revert when askToken is address(0)
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
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        // Expect revert with AskTokenUnavailable error
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        RELEASE VESTED TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that releasing vested tokens succeeds after vesting starts
     * @dev Verifies token release from vesting contract to investor after time passes
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x4287a77f3e3d040f42dcb9539e336d83d166ff810eb9d5d74bc440a2bdac5dae);
        claimProofInvestor2[1] = bytes32(0xda52deea919ca150a57325de782da41cffff19ec1bdf5d9747c1d6aa28b7639c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );

        vm.warp(refundEndTime() + 1 hours + 1);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).releaseVestedTokens();

        // Assert
        assertEq(askToken.balanceOf(investor2), 134_931_563_926_940_639_269);
    }

    /**
     * @notice Tests that releasing tokens without a vesting contract reverts
     * @dev Expects ZeroAddressProvided revert when no vesting contract exists
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect revert with ZeroAddressProvided error
        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).releaseVestedTokens();
    }

    /**
     * @notice Tests that releasing tokens with unavailable ask token reverts
     * @dev Expects AskTokenUnavailable revert when askToken is address(0)
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
                referrerFeeReceiver: address(nonLegionAdmin)
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        vm.prank(legionBouncer);
        legionSaleInstance =
            legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);

        // Expect revert with AskTokenUnavailable error
        vm.expectRevert(abi.encodeWithSelector(Errors.AskTokenUnavailable.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).releaseVestedTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that syncing Legion addresses by Legion admin succeeds
     * @dev Expects LegionAddressesSynced event with updated addresses from registry
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect event emission
        vm.expectEmit();
        emit ILegionSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory)
        );

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by non-Legion admin reverts
     * @dev Expects NotCalledByLegion revert when called by projectAdmin
     */
    function test_syncLegionAddresses_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect revert with NotCalledByLegion error
        vm.expectRevert(abi.encodeWithSelector(Errors.NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).syncLegionAddresses();
    }
}
