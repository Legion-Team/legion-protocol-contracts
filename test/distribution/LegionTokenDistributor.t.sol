// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Constants } from "../../src/utils/Constants.sol";
import { Errors } from "../../src/utils/Errors.sol";

import { ILegionTokenDistributor } from "../../src/interfaces/distribution/ILegionTokenDistributor.sol";
import { ILegionTokenDistributorFactory } from "../../src/interfaces/factories/ILegionTokenDistributorFactory.sol";
import { ILegionVestingManager } from "../../src/interfaces/vesting/ILegionVestingManager.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionTokenDistributor } from "../../src/distribution/LegionTokenDistributor.sol";
import { LegionTokenDistributorFactory } from "../../src/factories/LegionTokenDistributorFactory.sol";
import { LegionVestingFactory } from "../../src/factories/LegionVestingFactory.sol";

/**
 * @title Legion Token Distributor Test
 * @author Legion
 * @notice Test suite for the LegionTokenDistributor contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionTokenDistributorTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the token distributor
    ILegionTokenDistributor.TokenDistributorInitializationParams tokenDistributorInitParams;

    /// @notice Linear vesting configuration for investors
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearVestingConfig;

    /// @notice Linear epoch vesting configuration for investors
    ILegionVestingManager.LegionInvestorVestingConfig investorLinearEpochVestingConfig;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Template instance of the LegionTokenDistributor contract for cloning
    LegionTokenDistributor tokenDistributorTemplate;

    /// @notice Factory contract for creating token distributors
    LegionTokenDistributorFactory tokenDistributorFactory;

    /// @notice Factory contract for creating vesting instances
    LegionVestingFactory legionVestingFactory;

    /// @notice Mock token used as the sale token
    MockERC20 askToken;

    /// @notice Address of the deployed token distributor instance
    address legionTokenDistributorInstance;

    /// @notice Address representing an AWS broadcaster, set to 0x10
    address awsBroadcaster = address(0x10);

    /// @notice Address representing a Legion EOA, set to 0x01
    address legionEOA = address(0x01);

    /// @notice Address of the LegionBouncer contract, initialized with legionEOA and awsBroadcaster
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing the vesting contract controller, set to 0x99
    address public legionVestingController = address(0x99);

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Signature for investor1's investment
    bytes signatureInv1;

    /// @notice Signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcess;

    /// @notice Updated signature for investor1's excess capital withdrawal
    bytes signatureInv1WithdrawExcessUpdated;

    /// @notice Signature for investor1's token allocation claim
    bytes signatureInv1Claim;

    /// @notice Updated signature for investor1's token allocation claim
    bytes signatureInv1Updated2;

    /// @notice Vesting signature for investor1's linear vesting
    bytes vestingSignatureInv1;

    /// @notice Vesting signature for investor2's linear epoch vesting
    bytes vestingSignatureInv2Epoch;

    /// @notice Signature for investor2's investment
    bytes signatureInv2;

    /// @notice Signature for investor2's token allocation claim
    bytes signatureInv2Claim;

    /// @notice Invalid signature for testing invalid cases
    bytes invalidSignature;

    /// @notice Invalid vesting signature for testing invalid cases
    bytes invalidVestingSignature;

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
     * @dev Initializes sale template, factory, vesting factory, registry, tokens, and vesting configs
     */
    function setUp() public {
        tokenDistributorTemplate = new LegionTokenDistributor();
        tokenDistributorFactory = new LegionTokenDistributorFactory(legionBouncer);
        legionVestingFactory = new LegionVestingFactory();
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
        prepareInvestorLinearVestingConfig();
        prepareInvestorLinearEpochVestingConfig();
    }

    /**
     * @notice Sets the pre-liquid sale configuration parameters
     * @dev Updates the tokenDistributorInitParams with provided initialization parameters
     * @param _tokenDistributorInitParams Parameters for initializing a pre-liquid sale
     */
    function setDistributorConfig(
        ILegionTokenDistributor.TokenDistributorInitializationParams memory _tokenDistributorInitParams
    )
        public
    {
        tokenDistributorInitParams = ILegionTokenDistributor.TokenDistributorInitializationParams({
            totalAmountToDistribute: _tokenDistributorInitParams.totalAmountToDistribute,
            legionFeeOnTokensSoldBps: _tokenDistributorInitParams.legionFeeOnTokensSoldBps,
            referrerFeeOnTokensSoldBps: _tokenDistributorInitParams.referrerFeeOnTokensSoldBps,
            referrerFeeReceiver: _tokenDistributorInitParams.referrerFeeReceiver,
            askToken: _tokenDistributorInitParams.askToken,
            addressRegistry: _tokenDistributorInitParams.addressRegistry,
            projectAdmin: _tokenDistributorInitParams.projectAdmin
        });
    }

    /**
     * @notice Creates and initializes a LegionTokenDistributor instance
     * @dev Deploys a pre-liquid sale with default parameters via the factory
     */
    function prepareCreateLegionTokenDistributor() public {
        setDistributorConfig(
            ILegionTokenDistributor.TokenDistributorInitializationParams({
                totalAmountToDistribute: 20_000 * 1e18,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnTokensSoldBps: 100,
                referrerFeeReceiver: referrerFeeReceiver,
                askToken: address(askToken),
                addressRegistry: address(legionAddressRegistry),
                projectAdmin: projectAdmin
            })
        );
        vm.prank(legionBouncer);
        legionTokenDistributorInstance = tokenDistributorFactory.createTokenDistributor(tokenDistributorInitParams);
    }

    /**
     * @notice Mints tokens to investors and approves the sale instance
     * @dev Prepares bid and ask tokens for investors and project admin
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(projectAdmin);
        askToken.mint(projectAdmin, 1_000_000 * 1e18);
        askToken.approve(legionTokenDistributorInstance, 1_000_000 * 1e18);
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
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_FACTORY"), address(legionVestingFactory));
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_VESTING_CONTROLLER"), legionVestingController);
        vm.stopPrank();
    }

    /**
     * @notice Prepares the linear vesting configuration for investors
     * @dev Sets up a linear vesting schedule with predefined parameters
     */
    function prepareInvestorLinearVestingConfig() public {
        investorLinearVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            (1_209_603 + 2 weeks + 2), 31_536_000, 3600, ILegionVestingManager.VestingType.LEGION_LINEAR, 0, 0, 1e17
        );
    }

    /**
     * @notice Prepares the linear epoch vesting configuration for investors
     * @dev Sets up a linear epoch vesting schedule with predefined parameters
     */
    function prepareInvestorLinearEpochVestingConfig() public {
        investorLinearEpochVestingConfig = ILegionVestingManager.LegionInvestorVestingConfig(
            (1_209_603 + 2 weeks + 2),
            31_536_000,
            3600,
            ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
            2_628_000,
            12,
            1e17
        );
    }

    /**
     * @notice Prepares investor signatures for authentication
     * @dev Generates signatures for investment, withdrawal, and vesting actions
     */
    function prepareInvestorSignatures() public {
        address legionSigner = vm.addr(legionSignerPK);
        address nonLegionSigner = vm.addr(nonLegionSignerPK);
        uint8 v;
        bytes32 r;
        bytes32 s;

        vm.startPrank(legionSigner);

        bytes32 digest1Claim = keccak256(
            abi.encodePacked(investor1, legionTokenDistributorInstance, block.chainid, uint256(5000 * 1e18))
        ).toEthSignedMessageHash();

        bytes32 digest1Updated2 = keccak256(
            abi.encodePacked(investor1, legionTokenDistributorInstance, block.chainid, uint256(5000 * 1e18))
        ).toEthSignedMessageHash();

        bytes32 digest1Vesting = keccak256(
            abi.encode(investor1, legionTokenDistributorInstance, block.chainid, investorLinearVestingConfig)
        ).toEthSignedMessageHash();

        bytes32 digest2VestingEpoch = keccak256(
            abi.encode(investor2, legionTokenDistributorInstance, block.chainid, investorLinearEpochVestingConfig)
        ).toEthSignedMessageHash();

        bytes32 digest2Claim = keccak256(
            abi.encodePacked(investor2, legionTokenDistributorInstance, block.chainid, uint256(5000 * 1e18))
        ).toEthSignedMessageHash();

        (v, r, s) = vm.sign(legionSignerPK, digest1Claim);
        signatureInv1Claim = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1Updated2);
        signatureInv1Updated2 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest1Vesting);
        vestingSignatureInv1 = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2VestingEpoch);
        vestingSignatureInv2Epoch = abi.encodePacked(r, s, v);

        (v, r, s) = vm.sign(legionSignerPK, digest2Claim);
        signatureInv2Claim = abi.encodePacked(r, s, v);

        vm.stopPrank();

        vm.startPrank(nonLegionSigner);
        (v, r, s) = vm.sign(nonLegionSignerPK, digest1Vesting);
        invalidVestingSignature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INITIALIZATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful initialization with valid parameters
     * @dev Verifies sale configuration, status, and vesting setup post-creation
     */
    function test_createTokenDistributor_successfullyCreatedWithCorrectConfiguration() public {
        // Arrange & Act
        prepareCreateLegionTokenDistributor();
        ILegionTokenDistributor.TokenDistributorConfig memory distributorConfig =
            LegionTokenDistributor(payable(legionTokenDistributorInstance)).distributorConfiguration();

        // Expect
        assertEq(distributorConfig.legionFeeOnTokensSoldBps, 250);
        assertEq(distributorConfig.askToken, address(askToken));
        assertEq(distributorConfig.projectAdmin, projectAdmin);
        assertEq(distributorConfig.addressRegistry, address(legionAddressRegistry));
    }

    /**
     * @notice Tests that re-initializing an already initialized contract reverts
     * @dev Expects InvalidInitialization revert from Initializable due to proxy initialization lock
     */
    function test_initialize_revertsIfAlreadyInitialized() public {
        // Arrange
        prepareCreateLegionTokenDistributor();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionTokenDistributor(payable(legionTokenDistributorInstance)).initialize(tokenDistributorInitParams);
    }

    /**
     * @notice Tests that initializing the implementation contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeImplementation() public {
        // Arrange
        setDistributorConfig(
            ILegionTokenDistributor.TokenDistributorInitializationParams({
                totalAmountToDistribute: 1_000_000 * 1e18,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnTokensSoldBps: 100,
                referrerFeeReceiver: referrerFeeReceiver,
                askToken: address(askToken),
                addressRegistry: address(legionAddressRegistry),
                projectAdmin: projectAdmin
            })
        );

        address preLiquidSaleImplementation = tokenDistributorFactory.i_tokenDistributorTemplate();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionTokenDistributor(payable(preLiquidSaleImplementation)).initialize(tokenDistributorInitParams);
    }

    /**
     * @notice Tests that initializing the template contract reverts
     * @dev Expects InvalidInitialization revert from Initializable
     */
    function test_initialize_revertInitializeTemplate() public {
        // Arrange
        setDistributorConfig(
            ILegionTokenDistributor.TokenDistributorInitializationParams({
                totalAmountToDistribute: 1_000_000 * 1e18,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnTokensSoldBps: 100,
                referrerFeeReceiver: referrerFeeReceiver,
                askToken: address(askToken),
                addressRegistry: address(legionAddressRegistry),
                projectAdmin: projectAdmin
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Initializable.InvalidInitialization.selector));

        // Act
        LegionTokenDistributor(tokenDistributorTemplate).initialize(tokenDistributorInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createTokenDistributor_revertsWithZeroAddressProvided() public {
        // Arrange
        setDistributorConfig(
            ILegionTokenDistributor.TokenDistributorInitializationParams({
                totalAmountToDistribute: 1_000_000 * 1e18,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnTokensSoldBps: 100,
                referrerFeeReceiver: referrerFeeReceiver,
                askToken: address(0),
                addressRegistry: address(0),
                projectAdmin: address(0)
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        tokenDistributorFactory.createTokenDistributor(tokenDistributorInitParams);
    }

    /**
     * @notice Tests that creating a sale with zero value parameters reverts
     * @dev Expects LegionSale__ZeroValueProvided revert when refund period is zero
     */
    function test_createTokenDistributor_revertsWithZeroValueProvided() public {
        // Arrange
        setDistributorConfig(
            ILegionTokenDistributor.TokenDistributorInitializationParams({
                totalAmountToDistribute: 0,
                legionFeeOnTokensSoldBps: 250,
                referrerFeeOnTokensSoldBps: 100,
                referrerFeeReceiver: referrerFeeReceiver,
                askToken: address(askToken),
                addressRegistry: address(legionAddressRegistry),
                projectAdmin: projectAdmin
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroValueProvided.selector));

        // Act
        vm.prank(legionBouncer);
        tokenDistributorFactory.createTokenDistributor(tokenDistributorInitParams);
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
        prepareCreateLegionTokenDistributor();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).pause();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionTokenDistributor();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionTokenDistributor();

        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).unpause();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionTokenDistributor();

        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).unpause();
    }

    /*//////////////////////////////////////////////////////////////////////////
                           SUPPLY TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful token supply by project admin
     * @dev Expects TokensSuppliedForDistribution event emission with correct amounts
     */
    function test_supplyTokens_successfullyEmitsTokensSuppliedForDistribution() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectEmit();
        emit ILegionTokenDistributor.TokensSuppliedForDistribution(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens twice reverts
     * @dev Expects LegionSale__TokensAlreadySupplied revert when tokens are already supplied
     */
    function test_supplyTokens_revertsIfTokensAlreadySupplied() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensAlreadySupplied.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying tokens by a non-project admin reverts
     * @dev Expects LegionSale__NotCalledByProject revert when called by nonProjectAdmin
     */
    function testFuzz_supplyTokens_revertsIfNotCalledByProjectAdmin(address nonProjectAdmin) public {
        // Arrange
        vm.assume(nonProjectAdmin != projectAdmin);

        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByProject.selector));

        // Act
        vm.prank(nonProjectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect token amount reverts
     * @dev Expects LegionSale__InvalidTokenAmountSupplied revert when amount mismatches TGE details
     */
    function test_supplyTokens_revertsIfIncorrectAmountSupplied() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LegionSale__InvalidTokenAmountSupplied.selector, 19_000 * 1e18, 20_000 * 1e18)
        );

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(19_000 * 1e18, 500 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect Legion fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when Legion fee is incorrect
     */
    function test_supplyTokens_revertsIfIncorrectLegionFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 499 * 1e18, 500 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 499 * 1e18, 200 * 1e18);
    }

    /**
     * @notice Tests that supplying incorrect referrer fee amount reverts
     * @dev Expects LegionSale__InvalidFeeAmount revert when referrer fee is incorrect
     */
    function test_supplyTokens_revertsIfIncorrectReferrerFeeAmountSupplied() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidFeeAmount.selector, 199 * 1e18, 200 * 1e18));

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 199 * 1e18);
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
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectEmit();
        emit ILegionTokenDistributor.EmergencyWithdraw(legionBouncer, address(askToken), 1000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).emergencyWithdraw(
            legionBouncer, address(askToken), 1000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).emergencyWithdraw(
            projectAdmin, address(askToken), 1000 * 1e6
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        CLAIM TOKEN ALLOCATION TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear vesting
     * @dev Verifies token allocation and vesting setup with linear vesting after TGE details and token supply
     */
    function test_claimTokenAllocation_successfullyEmitsTokenAllocationClaimedWithLinearVesting() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1Claim, vestingSignatureInv1
        );

        ILegionTokenDistributor.InvestorPosition memory position =
            LegionTokenDistributor(payable(legionTokenDistributorInstance)).investorPosition(investor1);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionTokenDistributor(payable(legionTokenDistributorInstance)).investorVestingStatus(investor1);

        // Expect
        assertEq(position.hasSettled, true);
        assertEq(MockERC20(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockERC20(askToken).balanceOf(investor1), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + 2 weeks + 2));
        assertEq(vestingStatus.end, (1_209_603 + 2 weeks + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + 2 weeks + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Successfully claim allocated tokens by investor with linear epoch vesting
     * @dev Verifies token allocation and vesting setup with linear epoch vesting after TGE details and token supply
     */
    function test_claimTokenAllocation_successfullyEmitsTokenAllocationClaimedWithLinearEpochVesting() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Act
        vm.prank(investor2);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearEpochVestingConfig, signatureInv2Claim, vestingSignatureInv2Epoch
        );

        ILegionTokenDistributor.InvestorPosition memory position =
            LegionTokenDistributor(payable(legionTokenDistributorInstance)).investorPosition(investor2);

        ILegionVestingManager.LegionInvestorVestingStatus memory vestingStatus =
            LegionTokenDistributor(payable(legionTokenDistributorInstance)).investorVestingStatus(investor2);

        // Expect
        assertEq(position.hasSettled, true);
        assertEq(MockERC20(askToken).balanceOf(position.vestingAddress), 4500 * 1e18);
        assertEq(MockERC20(askToken).balanceOf(investor2), 500 * 1e18);

        assertEq(vestingStatus.start, (1_209_603 + 2 weeks + 2));
        assertEq(vestingStatus.end, (1_209_603 + 2 weeks + 2 + 31_536_000));
        assertEq(vestingStatus.cliffEnd, (1_209_603 + 2 weeks + 2 + 3600));
        assertEq(vestingStatus.duration, (31_536_000));
        assertEq(vestingStatus.released, 0);
        assertEq(vestingStatus.releasable, 0);
        assertEq(vestingStatus.vestedAmount, 0);
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid linear vesting config
     * @dev Expects LegionVesting__InvalidVestingConfig revert when linear vesting parameters are invalid
     */
    function test_claimTokenAllocation_revertsIfInvalidLinearVestingConfig() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionVesting__InvalidVestingConfig.selector,
                uint8(ILegionVestingManager.VestingType.LEGION_LINEAR),
                Constants.MAX_VESTING_LOCKUP_SECONDS + block.timestamp + 1,
                520 weeks + 1,
                520 weeks + 2,
                0,
                0,
                1e18 + 1
            )
        );

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18),
            ILegionVestingManager.LegionInvestorVestingConfig(
                Constants.MAX_VESTING_LOCKUP_SECONDS + uint64(block.timestamp) + 1,
                520 weeks + 1,
                520 weeks + 2,
                ILegionVestingManager.VestingType.LEGION_LINEAR,
                0,
                0,
                1e18 + 1
            ),
            signatureInv1Claim,
            vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid linear vesting config
     * @dev Expects LegionVesting__InvalidVestingConfig revert when linear epoch vesting parameters are invalid
     */
    function test_claimTokenAllocation_revertsIfInvalidLinearEpochVestingConfig() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LegionVesting__InvalidVestingConfig.selector,
                uint8(ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH),
                0,
                520 weeks - 1,
                520 weeks - 2,
                520 weeks + 1,
                100,
                1e17
            )
        );

        // Act
        vm.prank(investor2);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18),
            ILegionVestingManager.LegionInvestorVestingConfig(
                0,
                520 weeks - 1,
                520 weeks - 2,
                ILegionVestingManager.VestingType.LEGION_LINEAR_EPOCH,
                520 weeks + 1,
                100,
                1e17
            ),
            signatureInv2Claim,
            vestingSignatureInv2Epoch
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens before ask tokens are supplied
     * @dev Expects LegionSale__TokensNotSupplied revert when tokens are not yet supplied
     */
    function test_claimTokenAllocation_revertsIfTokensNotSupplied() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__TokensNotSupplied.selector));

        // Act
        vm.prank(investor5);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1, vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens that were already claimed
     * @dev Expects LegionSale__AlreadySettled revert when attempting to claim a settled position
     */
    function test_claimTokenAllocation_revertsIfPositionAlreadySettled() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1Claim, vestingSignatureInv1
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__AlreadySettled.selector, investor1));

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1Claim, vestingSignatureInv1
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid vesting signature
     * @dev Expects LegionSale__InvalidSignature revert when vesting signature is invalid
     */
    function test_claimTokenAllocation_revertsIfVestingSignatureNotValid() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, invalidVestingSignature));

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1Claim, invalidVestingSignature
        );
    }

    /**
     * @notice Test case: Attempt to claim tokens with invalid claim signature
     * @dev Expects LegionSale__InvalidSignature revert when claim signature is invalid
     */
    function test_claimTokenAllocation_revertsIfClaimSignatureNotValid() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidSignature.selector, signatureInv2Claim));

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv2Claim, invalidVestingSignature
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        RELEASE VESTED TOKENS TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Test case: Successfully release tokens from vesting contract after vesting period
     * @dev Verifies token release from vesting contract to investor after cliff period has passed
     */
    function test_releaseVestedTokens_successfullyReleasesVestedTokensToInvestor() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).claimTokenAllocation(
            uint256(5000 * 1e18), investorLinearVestingConfig, signatureInv1Claim, vestingSignatureInv1
        );

        vm.warp(block.timestamp + 4 weeks + 1 hours + 3600);

        // Act
        vm.prank(investor1);
        ILegionTokenDistributor(legionTokenDistributorInstance).releaseVestedTokens();

        // Expect
        assertEq(MockERC20(askToken).balanceOf(investor1), 501_026_969_178_082_191_780);
    }

    /**
     * @notice Test case: Attempt to release tokens without a deployed vesting contract
     * @dev Expects LegionSale__ZeroAddressProvided revert when investor has no vesting contract deployed
     */
    function test_releaseVestedTokens_revertsIfInvestorHasNoVesting() public {
        // Arrange
        prepareCreateLegionTokenDistributor();
        prepareMintAndApproveTokens();
        prepareInvestorSignatures();

        vm.warp(block.timestamp + 1);

        vm.prank(projectAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).supplyTokens(20_000 * 1e18, 500 * 1e18, 200 * 1e18);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(investor2);
        ILegionTokenDistributor(legionTokenDistributorInstance).releaseVestedTokens();
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
        prepareCreateLegionTokenDistributor();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectEmit();
        emit ILegionTokenDistributor.LegionAddressesSynced(
            legionBouncer, vm.addr(legionSignerPK), address(1), address(legionVestingFactory), legionVestingController
        );

        // Act
        vm.prank(legionBouncer);
        ILegionTokenDistributor(legionTokenDistributorInstance).syncLegionAddresses();
    }

    /**
     * @notice Test case: Attempt to sync Legion addresses without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionTokenDistributor();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_FEE_RECEIVER"), address(1));

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionTokenDistributor(legionTokenDistributorInstance).syncLegionAddresses();
    }
}
