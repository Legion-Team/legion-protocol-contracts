// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { MockERC20 } from "@solady/test/utils/mocks/MockERC20.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";
import { Test, Vm, console2 } from "forge-std/Test.sol";

import { Errors } from "../../src/utils/Errors.sol";

import { ILegionReferrerFeeDistributor } from "../../src/interfaces/distribution/ILegionReferrerFeeDistributor.sol";

import { LegionAddressRegistry } from "../../src/registries/LegionAddressRegistry.sol";
import { LegionBouncer } from "../../src/access/LegionBouncer.sol";
import { LegionReferrerFeeDistributor } from "../../src/distribution/LegionReferrerFeeDistributor.sol";

/**
 * @title Legion Referrer Fee Distributor Test
 * @author Legion
 * @notice Test suite for the LegionReferrerFeeDistributor contract
 * @dev Inherits from Forge's Test contract to access testing utilities
 */
contract LegionReferrerFeeDistributorTest is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initialization parameters for the referrer fee distributor
    ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams referrerFeeDistributorInitParams;

    /// @notice Registry for Legion-related addresses
    LegionAddressRegistry legionAddressRegistry;

    /// @notice Mock token used as the sale token
    MockERC20 token;

    /// @notice Address of the deployed referrer fee distributor instance
    address legionReferrerFeeDistributorInstance;

    /// @notice Address representing an AWS broadcaster, set to 0x10
    address awsBroadcaster = address(0x10);

    /// @notice Address representing a Legion EOA, set to 0x01
    address legionEOA = address(0x01);

    /// @notice Address of the LegionBouncer contract, initialized with legionEOA and awsBroadcaster
    address legionBouncer = address(new LegionBouncer(legionEOA, awsBroadcaster));

    /// @notice Address representing investor1, set to 0x03
    address investor1 = address(0x03);

    /// @notice The merkle root used for testing, set to a specific value
    bytes32 merkleRoot = 0xd6766f04d9f3d13b3049ff7fa862995d8c1af0ff888928a51b07536dc380865b;

    /// @notice The merkle root updated during tests, set to a specific value
    bytes32 merkleRootUpdated = 0x6bf424981675a003587fab5fd806175d9911b0128fb1c39b7d091fcc9f81d439;

    /**
     * @notice Sets up the test environment by deploying necessary contracts and configurations
     */
    function setUp() public {
        legionAddressRegistry = new LegionAddressRegistry(legionBouncer);
        token = new MockERC20("USD Coin", "USDC", 6);
        prepareLegionAddressRegistry();
    }

    /**
     * @notice Sets the distributor configuration
     * @dev Updates the tokenDistributorInitParams with provided initialization parameters
     * @param _tokenDistributorInitParams Parameters for initializing the referrer fee distributor
     */
    function setDistributorConfig(
        ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams memory _tokenDistributorInitParams
    )
        public
    {
        referrerFeeDistributorInitParams = ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams({
            token: _tokenDistributorInitParams.token,
            addressRegistry: _tokenDistributorInitParams.addressRegistry
        });
    }

    /**
     * @notice Creates and initializes a LegionReferrerFeeDistributor instance
     * @dev Deploys a referrer fee distributor with default parameters
     */
    function prepareCreateLegionReferrerFeeDistributor() public {
        setDistributorConfig(
            ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams({
                token: address(token),
                addressRegistry: address(legionAddressRegistry)
            })
        );
        vm.prank(legionBouncer);
        legionReferrerFeeDistributorInstance =
            address(new LegionReferrerFeeDistributor(referrerFeeDistributorInitParams));
    }

    /**
     * @notice Mints tokens to investors and approves the LegionReferrerFeeDistributor contract
     * @dev Prepares tokens for distribution
     */
    function prepareMintAndApproveTokens() public {
        vm.startPrank(legionBouncer);
        token.mint(legionBouncer, 10_000 * 1e6);
        token.approve(legionReferrerFeeDistributorInstance, 10_000 * 1e6);
        vm.stopPrank();
    }

    /**
     * @notice Initializes the LegionAddressRegistry with required addresses
     * @dev Sets Legion bouncer
     */
    function prepareLegionAddressRegistry() public {
        vm.startPrank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET MERKLE ROOT TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests the successful setting of the Merkle root
     * @dev Expects the MerkleRootSet event to be emitted with the correct root
     */
    function test_setMerkleRoot_successfullySetMerkleRoot() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();

        // Expect
        vm.expectEmit();
        emit ILegionReferrerFeeDistributor.MerkleRootSet(merkleRoot);

        // Act
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);
    }

    /**
     * @notice Tests that setting the Merkle root reverts if not called by Legion admin
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function test_setMerkleRoot_revertsIfNotCalledByLegionAdmin() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CLAIM TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful claiming of referrer fees
     * @dev Expects ReferrerFeeClaimed event to be emitted with the correct referrer and amount
     */
    function test_claim_successfullyClaimReferrerFee() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);
        claimProofInvestor1[0] = bytes32(0xa27e3cd29578fe4c26f4fcad9e1c37eb66e24245cf9c67974fb1bd4313fb3801);
        claimProofInvestor1[1] = bytes32(0x128551ef39f8f71945937ba9fac73fe49f9eedc044b51887db9a7401b57387f0);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionReferrerFeeDistributor.ReferrerFeeClaimed(investor1, 1000 * 1e6);

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);
    }

    /**
     * @notice Tests that claiming referrer fees are claimed successfully with an updated Merkle root
     * @dev Expects ReferrerFeeClaimed event to be emitted with the correct referrer and amount
     */
    function test_claim_successfullyClaimReferrerFeeWithUpdatedMerkleRoot() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);
        claimProofInvestor1[0] = bytes32(0xa27e3cd29578fe4c26f4fcad9e1c37eb66e24245cf9c67974fb1bd4313fb3801);
        claimProofInvestor1[1] = bytes32(0x128551ef39f8f71945937ba9fac73fe49f9eedc044b51887db9a7401b57387f0);

        bytes32[] memory claimProofInvestor1Updated = new bytes32[](2);
        claimProofInvestor1Updated[0] = bytes32(0xbf1c5825c42427642262b520171e7259dcf6d857552913685798b35e6e1ce4d2);
        claimProofInvestor1Updated[1] = bytes32(0xc03066bc63a2fa6e7a375bafd5fba23506178e78378a8b1961b7f6c58b4cfe78);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);

        // Update the Merkle root
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRootUpdated);

        // Expect
        vm.expectEmit();
        emit ILegionReferrerFeeDistributor.ReferrerFeeClaimed(investor1, 1000 * 1e6);

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(
            2000 * 1e6, claimProofInvestor1Updated
        );
    }

    /**
     * @notice Tests that claiming referrer fees reverts if the contract is paused
     * @dev Expects Pausable.EnforcedPause revert when claiming while paused
     */
    function test_claim_revertsIfPaused() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);
        claimProofInvestor1[0] = bytes32(0xa27e3cd29578fe4c26f4fcad9e1c37eb66e24245cf9c67974fb1bd4313fb3801);
        claimProofInvestor1[1] = bytes32(0x128551ef39f8f71945937ba9fac73fe49f9eedc044b51887db9a7401b57387f0);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);
    }

    /**
     * @notice Tests that claiming referrer fees reverts if the Merkle proof is invalid
     * @dev Expects LegionSale__InvalidMerkleProof revert when the proof does not match the Merkle root
     */
    function test_claim_revertsIfInvalidMerkleProof() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidMerkleProof.selector));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);
    }

    /**
     * @notice Tests that claiming referrer fees reverts if the amount to claim is greater than the claimed amount
     * @dev Expects LegionSale__InvalidMerkleProof revert when the amount exceeds the claimed amount
     */
    function test_claim_revertsWithInvalidAmount() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);
        claimProofInvestor1[0] = bytes32(0xa27e3cd29578fe4c26f4fcad9e1c37eb66e24245cf9c67974fb1bd4313fb3801);
        claimProofInvestor1[1] = bytes32(0x128551ef39f8f71945937ba9fac73fe49f9eedc044b51887db9a7401b57387f0);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidMerkleProof.selector));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1001 * 1e6, claimProofInvestor1);
    }

    /**
     * @notice Tests that claiming referrer fees reverts if the amount to claim is zero
     * @dev Expects LegionSale__InvalidWithdrawAmount revert when the amount to claim is zero
     */
    function test_claim_revertsIfZeroAmountToClaim() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        bytes32[] memory claimProofInvestor1 = new bytes32[](2);
        claimProofInvestor1[0] = bytes32(0xa27e3cd29578fe4c26f4fcad9e1c37eb66e24245cf9c67974fb1bd4313fb3801);
        claimProofInvestor1[1] = bytes32(0x128551ef39f8f71945937ba9fac73fe49f9eedc044b51887db9a7401b57387f0);

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).setMerkleRoot(merkleRoot);

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__InvalidWithdrawAmount.selector, 0));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).claim(1000 * 1e6, claimProofInvestor1);
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
        prepareCreateLegionReferrerFeeDistributor();
        ILegionReferrerFeeDistributor.ReferrerFeeDistributorConfig memory distributorConfig =
        LegionReferrerFeeDistributor(payable(legionReferrerFeeDistributorInstance)).referrerFeeDistributorConfiguration(
        );

        // Expect
        assertEq(distributorConfig.totalReferrerFeesDistributed, 0);
        assertEq(distributorConfig.addressRegistry, address(legionAddressRegistry));
        assertEq(distributorConfig.legionBouncer, address(legionBouncer));
        assertEq(distributorConfig.token, address(token));
        assertEq(distributorConfig.merkleRoot, bytes32(0));
    }

    /**
     * @notice Tests that creating a sale with zero address parameters reverts
     * @dev Expects LegionSale__ZeroAddressProvided revert when addresses are zero
     */
    function test_createTokenDistributor_revertsWithZeroAddressProvided() public {
        // Arrange
        setDistributorConfig(
            ILegionReferrerFeeDistributor.ReferrerFeeDistributorInitializationParams({
                token: address(0),
                addressRegistry: address(0)
            })
        );

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__ZeroAddressProvided.selector));

        // Act
        vm.prank(legionBouncer);
        legionReferrerFeeDistributorInstance =
            address(new LegionReferrerFeeDistributor(referrerFeeDistributorInitParams));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    PAUSE TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Tests successful pausing of the sale by Legion admin
     * @dev Expects Paused event emission when paused by legionBouncer
     */
    function test_pause_successfullyPauseTheDistributor() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();

        // Expect
        vm.expectEmit();
        emit Pausable.Paused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).pause();
    }

    /**
     * @notice Tests that pausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_pause_revertsIfCalledByNonLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionReferrerFeeDistributor();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).pause();
    }

    /**
     * @notice Tests successful unpausing of the sale by Legion admin
     * @dev Expects Unpaused event emission after pausing and unpausing
     */
    function test_unpause_successfullyUnpauseTheSale() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).pause();

        // Expect
        vm.expectEmit();
        emit Pausable.Unpaused(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).unpause();
    }

    /**
     * @notice Tests that unpausing the sale by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by nonLegionAdmin
     */
    function testFuzz_unpause_revertsIfNotCalledByLegionAdmin(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionReferrerFeeDistributor();

        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).pause();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).unpause();
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
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        vm.prank(legionBouncer);
        MockERC20(token).transfer(legionReferrerFeeDistributorInstance, 10_000 * 1e6);

        // Expect
        vm.expectEmit();
        emit ILegionReferrerFeeDistributor.EmergencyWithdraw(legionBouncer, address(token), 10_000 * 1e6);

        // Act
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).emergencyWithdraw(
            legionBouncer, address(token), 10_000 * 1e6
        );
    }

    /**
     * @notice Tests that emergency withdrawal by a non-Legion admin reverts
     * @dev Expects LegionSale__NotCalledByLegion revert when called by projectAdmin
     */
    function test_emergencyWithdraw_revertsIfCalledByNonLegionAdmin() public {
        // Arrange
        prepareCreateLegionReferrerFeeDistributor();
        prepareMintAndApproveTokens();

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(investor1);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).emergencyWithdraw(
            investor1, address(token), 10_000 * 1e6
        );
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
        prepareCreateLegionReferrerFeeDistributor();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);

        // Expect
        vm.expectEmit();
        emit ILegionReferrerFeeDistributor.LegionAddressesSynced(legionBouncer);

        // Act
        vm.prank(legionBouncer);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).syncLegionAddresses();
    }

    /**
     * @notice Test case: Attempt to sync Legion addresses without Legion admin permissions
     * @dev Expects LegionSale__NotCalledByLegion revert when called by non-Legion admin
     */
    function testFuzz_syncLegionAddresses_revertsIfNotCalledByLegion(address nonLegionAdmin) public {
        // Arrange
        vm.assume(nonLegionAdmin != legionBouncer);
        prepareCreateLegionReferrerFeeDistributor();

        vm.prank(legionBouncer);
        legionAddressRegistry.setLegionAddress(bytes32("LEGION_BOUNCER"), legionBouncer);

        // Expect
        vm.expectRevert(abi.encodeWithSelector(Errors.LegionSale__NotCalledByLegion.selector));

        // Act
        vm.prank(nonLegionAdmin);
        ILegionReferrerFeeDistributor(legionReferrerFeeDistributorInstance).syncLegionAddresses();
    }
}
