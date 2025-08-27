// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721 } from "@solady/src/tokens/ERC721.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Errors } from "../../src/utils/Errors.sol";

import { ILegionFixedPriceSale } from "../../src/interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionAbstractSale } from "../../src/interfaces/sales/ILegionAbstractSale.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionFixedPriceSale } from "../../src/sales/LegionFixedPriceSale.sol";
import { LegionFixedPriceSaleFactory } from "../../src/factories/LegionFixedPriceSaleFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

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
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams;
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
    MockERC20 public bidToken;

    /// @notice Mock token used as the ask token (e.g., LFG)
    MockERC20 public askToken;

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

    /// @notice Address representing the vesting contract controller, set to 0x99
    address public legionVestingController = address(0x99);

    /// @notice Address representing the project admin
    address projectAdmin = address(0x02);

    /// @notice Test investor addresses
    address investor1 = address(0x03);
    address investor2 = address(0x04);
    address investor3 = address(0x05);
    address investor4 = address(0x06);
    address investor5 = address(0x07);

    /// @notice Address representing the Referrer fee receiver
    address referrerFeeReceiver = address(0x08);

    /// @notice Address representing the Legion fee receiver
    address legionFeeReceiver = address(0x10);

    /// @notice Signatures for investors
    bytes signatureInv1;
    bytes signatureInv2;
    bytes signatureInv3;
    bytes signatureInv4;
    bytes invalidSignature;

    /// @notice Signature for investor1's transfer to investor2
    bytes signatureInv1Transfer;

    /// @notice Signature for investor2's transfer to investor1
    bytes signatureInv2Transfer;

    /// @notice Private key for generating the Legion signer address
    uint256 legionSignerPK = 1234;

    /// @notice Private key for generating an invalid signer address
    uint256 nonLegionSignerPK = 12_345;

    /// @notice Merkle roots for testing
    bytes32 claimTokensMerkleRoot = 0x8d7c018c2099eaee9884eb772e1565b75cb717aa61d4caa276dd612273cdd649;
    bytes32 acceptedCapitalMerkleRoot = 0x380f79c2e8e6e4bc37b7fda83ac0f1a33b5abc5d70831c08add80068b2d564cf;
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

        bidToken = new MockERC20("USD Coin", "USDC", 6);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
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
        ILegionAbstractSale.LegionSaleInitializationParams memory _saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory _fixedPriceSaleInitParams
    )
        public
    {
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
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
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_CONTROLLER"), legionVestingController);
        vm.stopPrank();
    }

    /**
     * @notice Sets up the investor vesting configuration
     * @dev Configures a linear vesting schedule with predefined parameters
     */
    function prepareInvestorVestingConfig() public {
        investorVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            0, 31_536_000, 3600, ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 0, 1e17
        );
    }

    /**
     * @notice Retrieves the sale start time
     * @dev Fetches the start time from the sale configuration
     * @return uint256 The sale start time in seconds
     */
    function startTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.startTime;
    }

    /**
     * @notice Retrieves the sale end time
     * @dev Fetches the end time from the sale configuration
     * @return uint256 The sale end time in seconds
     */
    function endTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.endTime;
    }

    /**
     * @notice Retrieves the refund period end time
     * @dev Fetches the refund end time from the sale configuration
     * @return uint256 The refund period end time in seconds
     */
    function refundEndTime() public view returns (uint256) {
        ILegionAbstractSale.LegionSaleConfiguration memory _saleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleConfiguration();
        return _saleConfig.refundEndTime;
    }

    /**
     * @notice Retrieves the total capital raised in the sale
     * @dev Fetches the total capital raised from the sale status
     * @return saleTotalCapitalRaised The total capital raised in bid tokens
     */
    function capitalRaised() public view returns (uint256 saleTotalCapitalRaised) {
        ILegionAbstractSale.LegionSaleStatus memory _saleStatusDetails =
            LegionFixedPriceSale(payable(legionSaleInstance)).saleStatus();
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
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Act
        ILegionVestingManager.LegionVestingConfig memory _vestingConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).vestingConfiguration();
        ILegionFixedPriceSale.FixedPriceSaleConfiguration memory _fixedPriceSaleConfig =
            LegionFixedPriceSale(payable(legionSaleInstance)).fixedPriceSaleConfiguration();

        // Expect
        assertEq(_fixedPriceSaleConfig.tokenPrice, 1e6);
        assertEq(_vestingConfig.vestingFactory, address(legionVestingFactory));
    }

    /**
     * @notice Tests that re-initialization of an already initialized sale reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionFixedPriceSale(payable(legionSaleInstance)).initialize(
            testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams
        );
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        address fixedPriceSaleImplementation = legionSaleFactory.i_fixedPriceSaleTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionFixedPriceSale(payable(fixedPriceSaleImplementation)).initialize(
            testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams
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
        fixedPriceSaleTemplate.initialize(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createFixedPriceSale_revertsWithZeroAddressProvided() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: address(0),
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours,
                prefundAllocationPeriodSeconds: 1 hours,
                tokenPrice: 1e6
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value parameters reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when testConfig is uninitialized
     */
    function test_createFixedPriceSale_revertsWithZeroValueProvided() public {
        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with periods exceeding maximum reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert for periods longer than allowed
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooLong() public {
        // Arrange
        setSaleParams(
            ILegionAbstractSale.LegionSaleInitializationParams({
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
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 12 weeks + 1, // 12 weeks + 1
                prefundAllocationPeriodSeconds: 2 weeks + 1,
                tokenPrice: 1e6
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
        vm.prank(legionBouncer);
        legionSaleFactory.createFixedPriceSale(testConfig.saleInitParams, testConfig.fixedPriceSaleInitParams);
    }

    /**
     * @notice Tests that creating a sale with periods below minimum reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert for periods shorter than allowed
     */
    function test_createFixedPriceSale_revertsWithInvalidPeriodConfigTooShort() public {
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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            }),
            ILegionFixedPriceSale.FixedPriceSaleInitializationParams({
                prefundPeriodSeconds: 1 hours - 1,
                prefundAllocationPeriodSeconds: 1 hours - 1,
                tokenPrice: 1e6
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPeriodConfig.selector));

        // Act
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
    function test_pause_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pause();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).pause();
    }

    /**
     * @notice Tests that the sale can be unpaused by the Legion admin
     * @dev Expects an Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).unpause();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionFixedPriceSale();

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        /// Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).unpause();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests that investing during the active sale period succeeds
     * @dev Expects CapitalInvested event with prefund=false after sale start
     */
    function testFuzz_invest_successfullyEmitsCapitalInvestedNotPrefund(
        uint256 saleStartTime,
        uint256 secondsAfterStart
    )
        public
    {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        saleStartTime = bound(saleStartTime, startTime(), endTime());
        secondsAfterStart = bound(secondsAfterStart, 0, 1 hours);
        vm.assume(saleStartTime + secondsAfterStart < (endTime()));

        vm.warp(saleStartTime + secondsAfterStart);

        // Expect
        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalInvested(1000 * 1e6, investor1, false, 1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that successful investment mints an investor position
     * @dev Expects ERC721 balance increase and correct token URI after investment
     */
    function test_invest_successfullyMintsInvestorPosition() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert("ERC721: URI query for nonexistent token");

        vm.prank(investor1);
        LegionFixedPriceSale(payable(legionSaleInstance)).tokenURI(1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Assert
        assertEq(ERC721(legionSaleInstance).balanceOf(investor1), 1);
        assertEq(LegionFixedPriceSale(payable(legionSaleInstance)).tokenURI(1), "https://metadata.legion.cc/1");
    }

    /**
     * @notice Tests that investing during prefund allocation period reverts
     * @dev Expects LegionSale__PrefundAllocationPeriodNotEnded revert before sale start
     */
    function test_invest_revertsIfPrefundAllocationPeriodNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__PrefundAllocationPeriodNotEnded.selector, (startTime() - 1))
        );

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing during prefund period succeeds
     * @dev Expects CapitalInvested event with prefund=true before sale start
     */
    function test_invest_successfullyEmitsCapitalInvestedPrefund() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectEmit();
        emit ILegionFixedPriceSale.CapitalInvested(1000 * 1e6, investor1, true, 1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing after the sale ends reverts
     * @dev Expects LegionSale__SaleHasEnded revert after endTime
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, (endTime() + 1)));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing below the minimum amount reverts
     * @dev Expects LegionSale__InvalidInvestAmount revert for amount less than 1e6
     */
    function test_invest_revertsIfAmountLessThanMinimum() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidInvestAmount.selector, 1 * 1e5));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1 * 1e5, signatureInv1);
    }

    /**
     * @notice Tests that investing in a canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that investing with an invalid signature reverts
     * @dev Expects LegionSale__InvalidSignature revert with a non-Legion signer signature
     */
    function test_invest_revertsIfInvalidSignature() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidSignature));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, invalidSignature);
    }

    /**
     * @notice Tests that reinvesting after refunding reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert after investor refunds
     */
    function test_invest_revertsIfInvestorHasRefunded1() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(startTime() + 1);
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);
    }

    /**
     * @notice Tests that reinvesting after claiming excess capital reverts
     * @dev Expects LegionSale__InvestorHasClaimedExcess revert after excess withdrawal
     */
    function test_invest_revertsIfInvestorHasClaimedExcessCapital() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(endTime() - 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasClaimedExcess.selector, investor2));

        // Act
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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Tests that emergency withdrawal by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefunded(1000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        // Assert
        uint256 investor1Balance = bidToken.balanceOf(investor1);
        assertEq(investor1Balance, 1000 * 1e6);
    }

    /**
     * @notice Tests that refunding after the refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when called after refundEndTime
     */
    function test_refund_revertsIfRefundPeriodHasEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsOver.selector, (refundEndTime() + 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding from a canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after sale cancellation
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding with no invested capital reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert when investor has not invested
     */
    function test_refund_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();
    }

    /**
     * @notice Tests that refunding after already refunded reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when investor attempts second refund
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

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
    function test_cancel_successfullyEmitsSaleCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.SaleCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling an already canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to cancel twice
     */
    function test_cancel_revertsIfSaleAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling after results are published reverts
     * @dev Expects LegionSale__SaleResultsAlreadyPublished revert after results are set
     */
    function test_cancel_revertsIfResultsArePublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by investor1
     */
    function testFuzz_cancel_revertsIfCalledByNonProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();
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
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalRefundedAfterCancel(1000 * 1e6, investor1);

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Assert
        assertEq(bidToken.balanceOf(investor1), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing invested capital without cancellation reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when sale is active
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing with no invested capital after cancellation reverts
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor has not invested
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital after cancellation reverts if the investor has already withdrawn
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor1 tries to withdraw again
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfInvestorHasAlreadyWithdrawnInvestedCapital() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

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

        // Expect
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
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_publishSaleResults_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        vm.assume(nonLegionAdmin != legionBouncer);

        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results a second time reverts
     * @dev Expects LegionSale__TokensAlreadyAllocated revert when results are already published
     */
    function test_publishSaleResults_revertsIfResultsAlreadyPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadyAllocated.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_publishSaleResults_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsNotOver.selector, (refundEndTime() - 1), refundEndTime()
            )
        );

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );
    }

    /**
     * @notice Tests that publishing results after cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_publishSaleResults_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.AcceptedCapitalSet(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_setAcceptedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        vm.assume(nonLegionAdmin != legionBouncer);

        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);
    }

    /**
     * @notice Tests that setting accepted capital after cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_setAcceptedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect Legion fee reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when Legion fee is less than expected
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 90 * 1e18, 100 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 90 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect referrer fee reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when referrer fee is less than expected
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 39 * 1e18, 40 * 1e18));

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
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 0, 40 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 0, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_supplyTokens_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens after cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_supplyTokens_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens with incorrect amount reverts
     * @dev Expects LegionSale__InvalidTokenAmountSupplied revert when amount mismatches allocation
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidTokenAmountSupplied.selector, 9990 * 1e18, 4000 * 1e18)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(9990 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens before results are published reverts
     * @dev Expects LegionSale__TokensNotAllocated revert when results are not set
     */
    function test_supplyTokens_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotAllocated.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(10_000 * 1e18, 250 * 1e18, 40 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens a second time reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert when tokens are already supplied
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

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
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

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
        emit ILegionAbstractSale.TokensSuppliedForDistribution(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.CapitalWithdrawn(capitalRaised());

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();

        // Assert
        assertEq(bidToken.balanceOf(projectAdmin), capitalRaised() - capitalRaised() * 100 / 10_000);
    }

    /**
     * @notice Tests that withdrawing capital by non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital without supplied tokens reverts
     * @dev Expects LegionSale__TokensNotSupplied revert when tokens are not supplied
     */
    function test_withdrawRaisedCapital_revertsIfNoTokensSupplied() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotSupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before results are published reverts
     * @dev Expects LegionSale__SaleResultsNotPublished revert when results are not set
     */
    function test_withdrawRaisedCapital_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsNotPublished.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital before refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsNotOver.selector, (refundEndTime() - 1), refundEndTime()
            )
        );

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital after sale cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        vm.warp(refundEndTime() + 1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital twice reverts
     * @dev Expects LegionSale__CapitalAlreadyWithdrawn revert when capital is already withdrawn
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Tests that withdrawing capital with no raised amount reverts
     * @dev Expects LegionSale__CapitalNotRaised revert when no capital is available
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalNotRaised.selector));

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
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Assert
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2);

        assertEq(_investorPosition.hasClaimedExcess, true);
        assertEq(bidToken.balanceOf(investor2), 1000 * 1e6);
    }

    /**
     * @notice Tests that withdrawing excess capital from a canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled before withdrawal
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        vm.warp(endTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital with invalid proof reverts
     * @dev Expects LegionSale__CannotWithdrawExcessInvestedCapital revert with incorrect Merkle proof
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

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__CannotWithdrawExcessInvestedCapital.selector, investor2, 1000 * 1e6
            )
        );

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital twice reverts
     * @dev Expects LegionSale__AlreadyClaimedExcess revert when excess is already claimed
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory excessClaimProofInvestor2 = new bytes32[](2);
        excessClaimProofInvestor2[0] = bytes32(0x5a967157246c689bfb28b0e8bdd445fe3b05cd751cb10e979ae3dbaf0a02c5c7);
        excessClaimProofInvestor2[1] = bytes32(0x224c3f0b0526195d6161b6c193e3d2f3c63cbc435919720096ad25be50414394);

        vm.warp(endTime() - 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.warp(endTime() + 1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);
    }

    /**
     * @notice Tests that withdrawing excess capital without investment reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert for an investor with no prior investment
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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

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
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

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
        ILegionAbstractSale.InvestorPosition memory _investorPosition =
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2);

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
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refundEndTime
     */
    function test_claimTokenAllocation_revertsIfRefundPeriodHasNotEnded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        vm.warp(refundEndTime() - 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsNotOver.selector, (refundEndTime() - 1), refundEndTime()
            )
        );

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming more tokens than allocated reverts
     * @dev Expects LegionSale__NotInClaimWhitelist revert with invalid token amount or proof
     */
    function test_claimTokenAllocation_revertsIfTokensAreMoreThanAllocatedAmount() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotInClaimWhitelist.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            2000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens twice reverts
     * @dev Expects LegionSale__AlreadySettled revert when tokens are already claimed
     */
    function test_claimTokenAllocation_revertsIfTokensAlreadyClaimed() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

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

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadySettled.selector, investor2));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens from a canceled sale reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when sale is canceled
     */
    function test_claimTokenAllocation_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).claimTokenAllocation(
            1000 * 1e18, investorVestingConfig, claimProofInvestor2
        );
    }

    /**
     * @notice Tests that claiming tokens before results are published reverts
     * @dev Expects LegionSale__SaleResultsNotPublished revert when results are not set
     */
    function test_claimTokenAllocation_revertsIfSaleResultsNotPublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareInvestedCapitalFromAllInvestors();

        bytes32[] memory claimProofInvestor2 = new bytes32[](2);
        claimProofInvestor2[0] = bytes32(0x2054afa66e2c4ccd7ade9889c78d8cf4a46f716980dafb935d11ce1e564fa39c);
        claimProofInvestor2[1] = bytes32(0xa2144e298b31c1e3aa896eab357fd937fb7a574cc7237959b432e96a9423492c);

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsNotPublished.selector));

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
        claimProofInvestor2[0] = bytes32(0xff3d33a8fd9d2fd370071d27191d742338d3c1bdf0ed9e7074156278e31f492d);
        claimProofInvestor2[1] = bytes32(0xe5fecd7e290c6f3102d02b9d4a89172fe2ebf2c44ef3c3699f4f1025adfe63cc);

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
     * @dev Expects LegionSale__ZeroAddressProvided revert when no vesting contract exists
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).releaseVestedTokens();
    }

    /**
     * @notice Test case: Attempt to release tokens without a deployed vesting contract
     * @dev Expects LegionSale__ZeroAddressProvided revert when investor has no vesting contract deployed
     */
    function test_releaseVestedTokens_revertsIfCalledBeforeVestingIsDeployed() public {
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

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).supplyTokens(4000 * 1e18, 100 * 1e18, 40 * 1e18);

        vm.warp(refundEndTime() + 1 hours + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

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

        // Expect
        vm.expectEmit();
        emit ILegionAbstractSale.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory), legionVestingController
        );

        // Act
        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).syncLegionAddresses();
    }

    /**
     * @notice Tests that syncing Legion addresses by non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionFixedPriceSale();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionFixedPriceSale(legionSaleInstance).syncLegionAddresses();
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
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor1);
        assertEq(
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital, 1000 * 1e6
        );
        assertEq(ERC721(legionSaleInstance).ownerOf(1), investor2);
    }

    /**
     * @notice Test case: Successfully transfer investor position to an existing investor by Legion admin
     * @dev Verifies that investor position is transferred correctly and both investors' positions are updated
     */
    function test_transferInvestorPosition_successfullyTransfersInvestorPositionToExistingInvestor() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
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
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionSaleInstance).ownerOf(1);

        assertEq(ERC721(legionSaleInstance).ownerOf(2), investor2);

        assertEq(
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital, 2000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPosition_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.startPrank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);
        ILegionFixedPriceSale(legionSaleInstance).refund();
        vm.stopPrank();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function test_transferInvestorPosition_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPosition_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPosition_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if sale results are already published
     * @dev Expects LegionSale__SaleResultsAlreadyPublished revert when trying to transfer position after sale results
     * are published
     */
    function test_transferInvestorPosition_revertsIfSaleResultsArePublished() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPosition_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPosition_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(legionBouncer);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPosition(investor1, investor2, 1);
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
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        vm.prank(investor1);
        LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor1);

        assertEq(
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital, 1000 * 1e6
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
        prepareCreateLegionFixedPriceSale();
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
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(2000 * 1e6, signatureInv2);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        vm.prank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(1000 * 1e6, excessClaimProofInvestor2);

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionSaleInstance).ownerOf(1);

        assertEq(ERC721(legionSaleInstance).ownerOf(2), investor2);

        assertEq(
            LegionFixedPriceSale(payable(legionSaleInstance)).investorPosition(investor2).investedCapital, 2000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPositionWithSignature_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        bytes32[] memory excessClaimProofInvestor1 = new bytes32[](2);

        excessClaimProofInvestor1[0] = bytes32(0x94092e373061307b4d0adbfbdcdbf2952dd4f9faa4a19e459bf977b439fe7f6c);
        excessClaimProofInvestor1[1] = bytes32(0xd8c305ca65c62aada7dd6b63558219cfac0d5dc314d02aa0cda610cb75656ee7);

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.startPrank(investor2);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv2);
        ILegionFixedPriceSale(legionSaleInstance).refund();
        vm.stopPrank();

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).setAcceptedCapital(acceptedCapitalMerkleRoot);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).withdrawExcessInvestedCapital(0, excessClaimProofInvestor1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position by non-position owner using signature
     * @dev Expects LegionSale__InvalidSignature revert when called by non-Legion admin
     */
    function test_transferInvestorPositionWithSignature_revertsIfNotCalledByPositionOwner() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1Transfer));

        // Act
        vm.prank(investor2);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPositionWithSignature_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(projectAdmin);
        ILegionFixedPriceSale(legionSaleInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPositionWithSignature_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
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
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareMintAndApproveProjectTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).publishSaleResults(
            claimTokensMerkleRoot, acceptedCapitalMerkleRoot, 4000 * 1e18, askTokenDecimals
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleResultsAlreadyPublished.selector));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPositionWithSignature_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.warp(refundEndTime() + 1);

        vm.prank(legionBouncer);
        ILegionFixedPriceSale(legionSaleInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPositionWithSignature_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionFixedPriceSale();
        prepareMintAndApproveInvestorTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).invest(1000 * 1e6, signatureInv1);

        vm.prank(investor1);
        ILegionFixedPriceSale(legionSaleInstance).refund();

        vm.warp(refundEndTime() + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(investor1);
        LegionFixedPriceSale(legionSaleInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }
}
