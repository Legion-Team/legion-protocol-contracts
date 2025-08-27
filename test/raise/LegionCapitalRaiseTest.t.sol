// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721 } from "@solady/src/tokens/ERC721.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionCapitalRaise } from "../../src/interfaces/raise/ILegionCapitalRaise.sol";
import { ILegionCapitalRaiseFactory } from "../../src/interfaces/factories/ILegionCapitalRaiseFactory.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionCapitalRaise } from "../../src/raise/LegionCapitalRaise.sol";
import { LegionCapitalRaiseFactory } from "../../src/factories/LegionCapitalRaiseFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Capital Raise Test
 * @author Legion
 * @notice Test suite for the LegionCapitalRaise contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionCapitalRaiseTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the pre-liquid capital raise
    ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Template instance of the LegionCapitalRaise contract for cloning
    LegionCapitalRaise capitalRaiseTemplate;

    /// @notice Factory contract for creating pre-liquid capital raise instances
    LegionCapitalRaiseFactory legionCapitalRaiseFactory;

    /// @notice Mock token used as the bidding currency
    MockERC20 bidToken;

    /// @notice Address of the deployed pre-liquid capital raise instance
    address legionCapitalRaiseInstance;

    /// @notice Address representing an AWS broadcaster, set to 0x10
    address awsBroadcaster = address(0x10);

    /// @notice Address representing a Legion EOA, set to 0x01
    address legionEOA = address(0x01);

    /// @notice Address of the LegionBouncer contract, initialized with legionEOA and awsBroadcaster
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Signature for investor1's investment
    bytes signatureInv1;

    /// @notice Signature for investor1's transfer to investor2
    bytes signatureInv1Transfer;

    /// @notice Signature for investor2's transfer to investor1
    bytes signatureInv2Transfer;

    /// @notice Signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcess;

    /// @notice Updated signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcessUpdated;

    /// @notice Signature for investor1's token allocation claim
    bytes signatureInv1Claim;

    /// @notice Updated signature for investor1's token allocation claim
    bytes signatureInv1Updated2;

    /// @notice Signature for investor2's investment
    bytes signatureInv2;

    /// @notice Signature for investor2's excess capital withdrawal
    bytes signatureInv2WithdrawExcess;

    /// @notice Signature for investor2's token allocation claim
    bytes signatureInv2Claim;

    /// @notice Private key for the Legion signer, set to 1234
    uint256 legionSignerPK = 1234;

    /// @notice Private key for a non-Legion signer, set to 12_345
    uint256 nonLegionSignerPK = 12_345;

    /// @notice Address representing investor1, set to 0x03
    address investor1 = address(0x03);

    /// @notice Address representing investor2, set to 0x04
    address investor2 = address(0x04);

    /// @notice Address representing investor5, set to 0x07
    address investor5 = address(0x07);

    /// @notice Address representing the Referrer fee receiver, set to 0x08
    address referrerFeeReceiver = address(0x08);

    /// @notice Address representing the Legion fee receiver, set to 0x09
    address legionFeeReceiver = address(0x09);

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     * @dev Initializes capital raise template, factory, registry and tokens
     */
    function setUp() public {
        capitalRaiseTemplate = new LegionCapitalRaise();
        legionCapitalRaiseFactory = new LegionCapitalRaiseFactory(legionBouncer);
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        bidToken = new MockERC20("USD Coin", "USDC", 6);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Sets the pre-liquid capital raise configuration parameters
     * @dev Updates the capitalRaiseInitParams with provided initialization parameters
     * @param _capitalRaiseInitParams Parameters for initializing a pre-liquid capital raise
     */
    function setCapitalRaiseConfig(ILegionCapitalRaise.CapitalRaiseInitializationParams memory _capitalRaiseInitParams)
        public
    {
        capitalRaiseInitParams = ILegionCapitalRaise.CapitalRaiseInitializationParams({
            refundPeriodSeconds: _capitalRaiseInitParams.refundPeriodSeconds,
            legionFeeOnCapitalRaisedBps: _capitalRaiseInitParams.legionFeeOnCapitalRaisedBps,
            referrerFeeOnCapitalRaisedBps: _capitalRaiseInitParams.referrerFeeOnCapitalRaisedBps,
            bidToken: _capitalRaiseInitParams.bidToken,
            projectAdmin: _capitalRaiseInitParams.projectAdmin,
            addressRegistry: _capitalRaiseInitParams.addressRegistry,
            referrerFeeReceiver: _capitalRaiseInitParams.referrerFeeReceiver,
            saleName: _capitalRaiseInitParams.saleName,
            saleSymbol: _capitalRaiseInitParams.saleSymbol,
            saleBaseURI: _capitalRaiseInitParams.saleBaseURI
        });
    }

    /**
     * @notice Creates and initializes a LegionCapitalRaise instance
     * @dev Deploys a pre-liquid capital raise with default parameters via the factory
     */
    function prepareCreateLegionCapitalRaise() public {
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc/"
            })
        );
        vm.prank(legionBouncer);
        legionCapitalRaiseInstance = legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /**
     * @notice Mints tokens to investors and approves the capital raise instance
     * @dev Prepares bid and ask tokens for investors and project admin
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(legionBouncer);
        bidToken.mint(investor1, 100_000 * 1e6);
        bidToken.mint(investor2, 100_000 * 1e6);
        vm.stopPrank();

        vm.prank(investor1);
        bidToken.approve(legionCapitalRaiseInstance, 100_000 * 1e6);

        vm.prank(investor2);
        bidToken.approve(legionCapitalRaiseInstance, 100_000 * 1e6);

        vm.startPrank(projectAdmin);
        bidToken.mint(projectAdmin, 1_000_000 * 1e6);
        bidToken.approve(legionCapitalRaiseInstance, 1_000_000 * 1e6);
        vm.stopPrank();
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
        vm.stopPrank();
    }

    /**
     * @notice Prepares investor signatures for authentication
     * @dev Generates signatures for investment, withdrawal, and vesting actions
     */
    function prepareInvestorSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1 = keccak256(
            abi.encodePacked(
                investor1,
                legionCapitalRaiseInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionCapitalRaise.CapitalRaiseAction.INVEST
            )
        ).toEthSignedMessageHash();

        bytes32 digest1WithdrawExcess = keccak256(
            abi.encodePacked(
                investor1,
                legionCapitalRaiseInstance,
                block.chainid,
                uint256(9000 * 1e6),
                uint256(4_000_000_000_000_000),
                ILegionCapitalRaise.CapitalRaiseAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest1WithdrawExcessUpdated = keccak256(
            abi.encodePacked(
                investor1,
                legionCapitalRaiseInstance,
                block.chainid,
                uint256(5000 * 1e6),
                uint256(2_500_000_000_000_000),
                ILegionCapitalRaise.CapitalRaiseAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        bytes32 digest2 = keccak256(
            abi.encodePacked(
                investor2,
                legionCapitalRaiseInstance,
                block.chainid,
                uint256(10_000 * 1e6),
                uint256(5_000_000_000_000_000),
                ILegionCapitalRaise.CapitalRaiseAction.INVEST
            )
        ).toEthSignedMessageHash();

        bytes32 digest2WithdrawExcess = keccak256(
            abi.encodePacked(
                investor2,
                legionCapitalRaiseInstance,
                block.chainid,
                uint256(5000 * 1e6),
                uint256(2_500_000_000_000_000),
                ILegionCapitalRaise.CapitalRaiseAction.WITHDRAW_EXCESS_CAPITAL
            )
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1);
        signatureInv1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1WithdrawExcess);
        signatureInv1WithdrawExcess = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1WithdrawExcessUpdated);
        signatureInv1WithdrawExcessUpdated = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2);
        signatureInv2 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2WithdrawExcess);
        signatureInv2WithdrawExcess = abi.encodePacked(r, s, v);

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
            abi.encodePacked(investor1, investor2, uint256(1), investor1, legionCapitalRaiseInstance, block.chainid)
        ).toEthSignedMessageHash();

        bytes32 digest2Transfer = keccak256(
            abi.encodePacked(investor1, investor2, uint256(2), investor1, legionCapitalRaiseInstance, block.chainid)
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1Transfer);
        signatureInv1Transfer = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2Transfer);
        signatureInv2Transfer = abi.encodePacked(r, s, v);

        vm.stopPrank();
    }

    /**
     * @notice Retrieves the refund period end time
     * @dev Fetches the refund end time from the capital raise configuration
     * @return uint256 The refund period end time in seconds
     */
    function refundEndTime() public view returns (uint256) {
        ILegionCapitalRaise.CapitalRaiseStatus memory _capitalRaiseStatus =
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).saleStatus();
        return _capitalRaiseStatus.refundEndTime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization with valid parameters
     * @dev Verifies capital raise configuration, status, and vesting setup post-creation
     */
    function test_createCapitalRaise_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionCapitalRaise();
        ILegionCapitalRaise.CapitalRaiseConfig memory raiseConfig =
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).saleConfiguration();
        ILegionCapitalRaise.CapitalRaiseStatus memory raiseStatus =
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).saleStatus();

        // Expect
        assertEq(raiseConfig.refundPeriodSeconds, 2 weeks);
        assertEq(raiseConfig.legionFeeOnCapitalRaisedBps, 250);
        assertEq(raiseConfig.bidToken, address(bidToken));
        assertEq(raiseConfig.projectAdmin, projectAdmin);
        assertEq(raiseConfig.addressRegistry, address(legionAddressRegistry));
        assertEq(raiseStatus.totalCapitalInvested, 0);
        assertEq(raiseStatus.totalCapitalWithdrawn, 0);
        assertEq(raiseStatus.isCanceled, false);
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        address capitalRaiseImplementation = legionCapitalRaiseFactory.i_capitalRaiseTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(payable(capitalRaiseImplementation)).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionCapitalRaise(capitalRaiseTemplate).initialize(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createCapitalRaise_revertsWithZeroAddressProvided() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(0),
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
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with zero value parameters reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when refund period is zero
     */
    function test_createCapitalRaise_revertsWithZeroValueProvided() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 0,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
                addressRegistry: address(legionAddressRegistry),
                referrerFeeReceiver: referrerFeeReceiver,
                saleName: "Legion LFG Sale",
                saleSymbol: "LLFGS",
                saleBaseURI: "https://metadata.legion.cc"
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /**
     * @notice Tests that creating a capital raise with invalid period configuration reverts
     * @dev Expects LegionSale__InvalidPeriodConfig revert when refund period is misconfigured
     */
    function test_createCapitalRaise_revertsWithInvalidPeriodConfig() public {
        // Arrange
        setCapitalRaiseConfig(
            ILegionCapitalRaise.CapitalRaiseInitializationParams({
                refundPeriodSeconds: 2 weeks + 1,
                legionFeeOnCapitalRaisedBps: 250,
                referrerFeeOnCapitalRaisedBps: 100,
                bidToken: address(bidToken),
                projectAdmin: projectAdmin,
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
        legionCapitalRaiseFactory.createCapitalRaise(capitalRaiseInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the capital raise by Legion admin
     * @dev Expects Paused event emission when paused by legionBouncer
     */
    function test_pause_successfullyPauseTheSale() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();
    }

    /**
     * @notice Tests that pausing the capital raise by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionCapitalRaise();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the capital raise by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).unpause();
    }

    /**
     * @notice Tests that unpausing the capital raise by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).unpause();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INVEST TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful investment in the capital raise
     * @dev Expects CapitalInvested event emission with correct parameters
     */
    function test_invest_successfullyEmitsCapitalInvested() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalInvested(10_000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        ILegionCapitalRaise.InvestorPosition memory position =
            ILegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor1);

        assertEq(position.investedCapital, 10_000 * 1e6);
    }

    /**
     * @notice Tests that successful investment mints an investor position
     * @dev Expects ERC721 balance increase and correct token URI after investment
     */
    function test_invest_successfullyMintsInvestorPosition() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert("ERC721: URI query for nonexistent token");

        vm.prank(investor1);
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).tokenURI(1);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Assert
        assertEq(ERC721(legionCapitalRaiseInstance).balanceOf(investor1), 1);
        assertEq(LegionCapitalRaise(payable(legionCapitalRaiseInstance)).tokenURI(1), "https://metadata.legion.cc/1");
    }

    /**
     * @notice Tests that investing after capital raise cancellation reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when capital raise is canceled
     */
    function test_invest_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing with a used signature reverts
     * @dev Expects LegionSale__SignatureAlreadyUsed revert when signature is reused
     */
    function test_invest_revertsIfSignatureAlreadyUsed() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SignatureAlreadyUsed.selector, signatureInv1));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing more than allowed amount reverts
     * @dev Expects LegionSale__InvalidPositionAmount revert when exceeding signed amount
     */
    function test_invest_revertsIfInvestingMoreThanAllowed() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            11_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing by a non-whitelisted investor reverts
     * @dev Expects LegionSale__InvalidSignature revert when signature doesn’t match investor
     */
    function test_invest_revertsIfInvestorNotInWhitelist() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1));

        // Act
        vm.prank(investor5);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /**
     * @notice Tests that investing when capital raise has ended reverts
     * @dev Expects LegionSale__SaleHasEnded revert when capital raise has ended
     */
    function test_invest_revertsIfSaleHasEnded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasEnded.selector, 1));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                REFUND TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful refund before refund period ends
     * @dev Expects CapitalRefunded event emission with correct amount
     */
    function test_refund_successfullyEmitsCapitalRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRefunded(10_000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
    }

    /**
     * @notice Tests that refunding when capital raise is canceled reverts
     * @dev Expects LegionSale__SaleIsCanceled revert after cancellation
     */
    function test_refund_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
    }

    /**
     * @notice Tests that refunding after refund period ends reverts
     * @dev Expects LegionSale__RefundPeriodIsOver revert when period expires
     */
    function test_refund_revertsIfRefundPeriodIsOver() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
    }

    /**
     * @notice Tests that refunding twice reverts
     * @dev Expects LegionSale__InvestorHasRefunded revert when already refunded
     */
    function test_refund_revertsIfInvestorHasAlreadyRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 3600);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();

        vm.warp(block.timestamp + 7200);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorHasRefunded.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
    }

    /**
     * @notice Tests that refunding with no capital invested reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert when no investment exists
     */
    function test_refund_revertsIfInvestorHasNoCapitalToRefund() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CANCEL RAISE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful capital raise cancellation with no capital to return
     * @dev Expects SaleCanceled event emission when no capital remains
     */
    function test_cancel_successfullyEmitsSaleCanceledWithNoCapitalToReturn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRaiseCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();
    }

    /**
     * @notice Tests successful capital raise cancellation with capital to return
     * @dev Expects SaleCanceled event emission after capital is withdrawn
     */
    function test_cancel_successfullyEmitsSaleCanceledWithCapitalToReturn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1 days);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();

        vm.warp(block.timestamp + 2 weeks + 2 days);

        vm.prank(projectAdmin);
        bidToken.approve(legionCapitalRaiseInstance, 10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRaiseCanceled();

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();
    }

    /**
     * @notice Tests that canceling an already canceled capital raise reverts
     * @dev Expects LegionSale__SaleIsCanceled revert when capital raise is already canceled
     */
    function test_cancel_revertsIfSaleIsAlreadyCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();
    }

    /**
     * @notice Tests that canceling by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_cancel_revertsIfCalledByNonProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(1 + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();
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
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.EmergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).emergencyWithdraw(legionBouncer, address(bidToken), 1000 * 1e6);
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).emergencyWithdraw(projectAdmin, address(bidToken), 1000 * 1e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        PUBLISH CAPITAL RAISED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully publish capital raised and accepted capital merkle root
     * @dev Expects CapitalRaisedPublished event emission with correct amount after capital raise ends and refund period
     * expires
     */
    function test_publishRaisedCapital_successfullyEmitsCapitalRaisedPublished() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRaisedPublished(10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised by non-legion admin
     * @dev Expects LegionSale__NotCalledByLegion revert when called by an unauthorized address
     */
    function testFuzz_publishRaisedCapital_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if capital raise is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to publish after capital raise cancellation
     */
    function test_publishRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if capital raise has not ended
     * @dev Expects LegionSale__SaleHasNotEnded revert when capital raise is still active
     */
    function test_publishRaisedCapital_revertsIfSaleHasNotEnded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleHasNotEnded.selector, block.timestamp));

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refund period expires
     */
    function test_publishRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /**
     * @notice Test case: Attempt to publish capital raised if already published
     * @dev Expects LegionSale__CapitalRaisedAlreadyPublished revert when attempting to publish twice
     */
    function test_publishRaisedCapital_revertsIfCapitalAlreadyPublished() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalRaisedAlreadyPublished.selector));

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW RAISED CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully withdraw raised capital by project admin
     * @dev Expects CapitalWithdrawn event emission after capital is published and refund period ends
     */
    function test_withdrawRaisedCapital_successfullyEmitsCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalWithdrawn(10_000 * 1e6);

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital without project admin permissions
     * @dev Expects LegionSale__NotCalledByProject revert when called by a non-project admin address
     */
    function testFuzz_withdrawRaisedCapital_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);

        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital when capital raise is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to withdraw after cancellation
     */
    function test_withdrawRaisedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital before refund period ends
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when called before refund period expires
     */
    function test_withdrawRaisedCapital_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionSale__RefundPeriodIsNotOver.selector, (block.timestamp), refundEndTime()
            )
        );

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital if already withdrawn
     * @dev Expects LegionSale__CapitalAlreadyWithdrawn revert when attempting to withdraw twice
     */
    function test_withdrawRaisedCapital_revertsIfCapitalAlreadyWithdrawn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).publishRaisedCapital(10_000 * 1e6);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalAlreadyWithdrawn.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /**
     * @notice Test case: Attempt to withdraw capital if capital raised is not published
     * @dev Expects LegionSale__CapitalNotRaised revert when capital raised has not been published
     */
    function test_withdrawRaisedCapital_revertsIfCapitalRaisedNotPublished() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__CapitalNotRaised.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawRaisedCapital();
    }

    /*//////////////////////////////////////////////////////////////////////////
                  WITHDRAW CAPITAL IF SALE IS CANCELED TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful withdrawal of invested capital by an investor after capital raise cancellation
     * @dev Verifies CapitalRefundedAfterCancel event is emitted with 10,000 USDC for investor1
     */
    function test_withdrawInvestedCapitalIfCanceled_successfullyEmitsCapitalRefundedAfterCancel() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRefundedAfterCancel(10_000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital when the capital raise is not canceled reverts
     * @dev Expects LegionSale__SaleIsNotCanceled revert when investor1 tries to withdraw without cancellation
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfSaleIsNotCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsNotCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital with no investment reverts
     * @dev Expects LegionSale__InvestorPositionDoesNotExist revert when investor2, who didn't invest, tries to withdraw
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfNoCapitalInvested() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        // Act
        vm.prank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawInvestedCapitalIfCanceled();
    }

    /**
     * @notice Tests that withdrawing capital after cancellation reverts if the investor has already withdrawn
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when investor1 tries to withdraw again
     */
    function test_withdrawInvestedCapitalIfCanceled_revertsIfInvestorHasAlreadyWithdrawnInvestedCapital() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawInvestedCapitalIfCanceled();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawInvestedCapitalIfCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        WITHDRAW EXCESS CAPITAL TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully withdraw excess capital if amount allowed to invest has changed
     * @dev Expects ExcessCapitalWithdrawn event emission with correct parameters
     */
    function test_withdrawExcessInvestedCapital_successfullyEmitsExcessCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.ExcessCapitalWithdrawn(1000 * 1e6, investor1, 1);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Successfully withdraw excess capital if amount allowed to invest has changed
     * @dev Expects ExcessCapitalWithdrawn event emission with correct parameters
     */
    function test_withdrawExcessInvestedCapital_revertsIfExcessInvestedCapitalWithdrawn() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadyClaimedExcess.selector, investor1));

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcessUpdated
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital after capital raise cancellation
     * @dev Expects LegionSale__SaleIsCanceled revert when attempting to withdraw after capital raise is canceled
     */
    function test_withdrawExcessInvestedCapital_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital with used signature
     * @dev Expects LegionSale__SignatureAlreadyUsed revert when reusing a signature for withdrawal
     */
    function test_withdrawExcessInvestedCapital_revertsIfSignatureAlreadyUsed() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__SignatureAlreadyUsed.selector, signatureInv1WithdrawExcess)
        );

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw more than allowed excess capital
     * @dev Expects LegionSale__InvalidPositionAmount revert when withdrawal exceeds allowed excess
     */
    function test_withdrawExcessInvestedCapital_revertsIfTryToWithdrawMoreThanExcess() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidPositionAmount.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            2000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );
    }

    /**
     * @notice Test case: Attempt to withdraw excess capital with invalid signature
     * @dev Expects LegionSale__InvalidSignature revert when signature data does not match expected values
     */
    function test_withdrawExcessInvestedCapital_revertsIfInvalidSignatureData() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1 days);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.warp(block.timestamp + 1 days + 2 weeks);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1WithdrawExcess)
        );

        // Act
        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 100, signatureInv1WithdrawExcess
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                END RAISE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully end capital raise by project admin
     * @dev Expects SaleEnded event emission when project admin ends the capital raise
     */
    function test_end_successfullyEndsSale() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.CapitalRaiseEnded();

        // Act
        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();
    }

    /**
     * @notice Test case: Attempt to end capital raise without project admin permissions
     * @dev Expects LegionSale__NotCalledByLegionOrProject revert when called by non-project admin
     */
    function testFuzz_end_revertsIfCalledByNonProjectOrNonLegionAdmin(address nonProjectOrLegionAdmin) public {
        // Arrange
        vm.assume(nonProjectOrLegionAdmin != projectAdmin && nonProjectOrLegionAdmin != legionBouncer);
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();

        vm.warp(1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegionOrProject.selector));

        // Act
        vm.prank(nonProjectOrLegionAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        SYNC LEGION ADDRESSES TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully sync Legion addresses from registry
     * @dev Expects LegionAddressesSynced event emission with updated addresses from registry
     */
    function test_syncLegionAddresses_successfullyEmitsLegionAddressesSynced() public {
        // Arrange
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionCapitalRaise.LegionAddressesSynced(legionBouncer, vm.addr(legionSignerPK), address(1));

        // Act
        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).syncLegionAddresses();
    }

    /**
     * @notice Test case: Attempt to sync Legion addresses without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionCapitalRaise();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).syncLegionAddresses();
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
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor1);
        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).investedCapital,
            9000 * 1e6
        );
        assertEq(ERC721(legionCapitalRaiseInstance).ownerOf(1), investor2);
    }

    /**
     * @notice Test case: Successfully transfer investor position to an existing investor by Legion admin
     * @dev Verifies that investor position is transferred correctly and both investors' positions are updated
     */
    function test_transferInvestorPosition_successfullyTransfersInvestorPositionToExistingInvestor() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        vm.prank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            5000 * 1e6, 5000 * 1e6, 2_500_000_000_000_000, signatureInv2WithdrawExcess
        );

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionCapitalRaiseInstance).ownerOf(1);

        assertEq(ERC721(legionCapitalRaiseInstance).ownerOf(2), investor2);

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).investedCapital,
            14_000 * 1e6
        );

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2)
                .cachedTokenAllocationRate,
            6_500_000_000_000_000
        );

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).cachedInvestAmount,
            14_000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPosition_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.startPrank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
        vm.stopPrank();

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function test_transferInvestorPosition_revertsIfNotCalledByLegion() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPosition_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPosition_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPosition_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
    }

    /**
     * @notice Test case: Attempt to transfer investor position that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPosition_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(legionBouncer);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPosition(investor1, investor2, 1);
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
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));

        vm.prank(investor1);
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor1);

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).investedCapital,
            9000 * 1e6
        );
        assertEq(ERC721(legionCapitalRaiseInstance).ownerOf(1), investor2);
    }

    /**
     * @notice Test case: Successfully transfer investor position with signature to an existing investor
     * @dev Verifies that investor position is transferred correctly and both investors' positions are updated
     */
    function test_transferInvestorPositionWithSignature_successfullyTransfersInvestorPositionToExistingInvestor()
        public
    {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        vm.prank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            5000 * 1e6, 5000 * 1e6, 2_500_000_000_000_000, signatureInv2WithdrawExcess
        );

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvestorPositionDoesNotExist.selector));
        LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor1);

        vm.expectRevert(abi.encodeWithSelector(ERC721.TokenDoesNotExist.selector));
        ERC721(legionCapitalRaiseInstance).ownerOf(1);

        assertEq(ERC721(legionCapitalRaiseInstance).ownerOf(2), investor2);

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).investedCapital,
            14_000 * 1e6
        );

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2)
                .cachedTokenAllocationRate,
            6_500_000_000_000_000
        );

        assertEq(
            LegionCapitalRaise(payable(legionCapitalRaiseInstance)).investorPosition(investor2).cachedInvestAmount,
            14_000 * 1e6
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if existing position is refunded
     * @dev Expects LegionSale__UnableToMergeInvestorPosition revert when trying to transfer position of refunded
     * investor
     */
    function test_transferInvestorPositionWithSignature_revertsIfExistingPositionIsRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.startPrank(investor2);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv2
        );
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();
        vm.stopPrank();

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).withdrawExcessInvestedCapital(
            1000 * 1e6, 9000 * 1e6, 4_000_000_000_000_000, signatureInv1WithdrawExcess
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToMergeInvestorPosition.selector, 2));

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position by non-position owner using signature
     * @dev Expects LegionSale__InvalidSignature revert when called by non-Legion admin
     */
    function test_transferInvestorPositionWithSignature_revertsIfNotCalledByPositionOwner() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv1Transfer));

        // Act
        vm.prank(investor2);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if sale is canceled
     * @dev Expects LegionSale__SaleIsCanceled revert when trying to transfer position after sale cancellation
     */
    function test_transferInvestorPositionWithSignature_revertsIfSaleIsCanceled() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).cancel();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__SaleIsCanceled.selector));

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature if refund period is not over
     * @dev Expects LegionSale__RefundPeriodIsNotOver revert when trying to transfer position before refund period ends
     */
    function test_transferInvestorPositionWithSignature_revertsIfRefundPeriodIsNotOver() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 1 days);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__RefundPeriodIsNotOver.selector, block.timestamp, refundEndTime())
        );

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position with signature while sale is paused
     * @dev Expects Pausable.EnforcedPause revert when trying to transfer position while sale is paused
     */
    function test_transferInvestorPositionWithSignature_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.warp(block.timestamp + 2 weeks + 1);

        vm.prank(legionBouncer);
        ILegionCapitalRaise(legionCapitalRaiseInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }

    /**
     * @notice Test case: Attempt to transfer investor position that has already been refunded
     * @dev Expects LegionSale__UnableToTransferInvestorPosition revert when trying to transfer refunded position
     */
    function test_transferInvestorPositionWithSignature_revertsIfPositionHasBeenRefunded() public {
        // Arrange
        prepareCreateLegionCapitalRaise();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();
        prepareTransferSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).invest(
            10_000 * 1e6, 10_000 * 1e6, 5_000_000_000_000_000, signatureInv1
        );

        vm.prank(projectAdmin);
        ILegionCapitalRaise(legionCapitalRaiseInstance).end();

        vm.prank(investor1);
        ILegionCapitalRaise(legionCapitalRaiseInstance).refund();

        vm.warp(block.timestamp + 2 weeks + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__UnableToTransferInvestorPosition.selector, 1));

        // Act
        vm.prank(investor1);
        LegionCapitalRaise(legionCapitalRaiseInstance).transferInvestorPositionWithAuthorization(
            investor1, investor2, 1, signatureInv1Transfer
        );
    }
}
