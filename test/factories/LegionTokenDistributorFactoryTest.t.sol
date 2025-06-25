// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Errors } from "../../src/utils/Errors.sol";

import { ILegionTokenDistributor } from "../../src/interfaces/distribution/ILegionTokenDistributor.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionTokenDistributor } from "../../src/distribution/LegionTokenDistributor.sol";
import { LegionTokenDistributorFactory } from "../../src/factories/LegionTokenDistributorFactory.sol";

/**
 * @title Legion Token Distributor Factory Test
 * @author Legion
 * @notice Test suite for the LegionTokenDistributorFactory contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionTokenDistributorFactoryTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the token distributor
    ILegionTokenDistributor.TokenDistributorInitializationParams tokenDistributorInitParams;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Template instance of the LegionTokenDistributor contract for cloning
    LegionTokenDistributor tokenDistributorTemplate;

    /// @notice Factory contract for creating token distributors
    LegionTokenDistributorFactory tokenDistributorFactory;

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

    /// @notice Address representing the project admin, set to 0x02
    address projectAdmin = address(0x02);

    /// @notice Private key for the Legion signer, set to 1234
    uint256 legionSignerPK = 1234;

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
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        askToken = new MockERC20("LFG Coin", "LFG", 18);
        prepareLegionAddressRegistry();
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
}
