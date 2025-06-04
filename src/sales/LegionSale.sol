// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

//       ___       ___           ___                       ___           ___
//      /\__\     /\  \         /\  \          ___        /\  \         /\__\
//     /:/  /    /::\  \       /::\  \        /\  \      /::\  \       /::|  |
//    /:/  /    /:/\:\  \     /:/\:\  \       \:\  \    /:/\:\  \     /:|:|  |
//   /:/  /    /::\~\:\  \   /:/  \:\  \      /::\__\  /:/  \:\  \   /:/|:|  |__
//  /:/__/    /:/\:\ \:\__\ /:/__/_\:\__\  __/:/\/__/ /:/__/ \:\__\ /:/ |:| /\__\
//  \:\  \    \:\~\:\ \/__/ \:\  /\ \/__/ /\/:/  /    \:\  \ /:/  / \/__|:|/:/  /
//   \:\  \    \:\ \:\__\    \:\ \:\__\   \::/__/      \:\  /:/  /      |:/:/  /
//    \:\  \    \:\ \/__/     \:\/:/  /    \:\__\       \:\/:/  /       |::/  /
//     \:\__\    \:\__\        \::/  /      \/__/        \::/  /        /:/  /
//      \/__/     \/__/         \/__/                     \/__/         \/__/
//
// If you find a bug, please contact security[at]legion.cc
// We will pay a fair bounty for any issue that puts users' funds at risk.

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { MerkleProofLib } from "@solady/src/utils/MerkleProofLib.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionSale } from "../interfaces/sales/ILegionSale.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";

import { LegionPositionManager } from "../position/LegionPositionManager.sol";
import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Sale
 * @author Legion
 * @notice A contract used for managing token sales in the Legion Protocol
 * @dev Abstract base contract implementing ILegionSale with vesting, pausing, and core sale functionality
 */
abstract contract LegionSale is ILegionSale, LegionVestingManager, LegionPositionManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the sale configuration
    /// @dev Stores general sale parameters internally
    LegionSaleConfiguration internal s_saleConfig;

    /// @notice Struct containing the sale addresses configuration
    /// @dev Stores address-related settings internally
    LegionSaleAddressConfiguration internal s_addressConfig;

    /// @notice Struct tracking the current sale status
    /// @dev Maintains runtime state of the sale internally
    LegionSaleStatus internal s_saleStatus;

    /// @notice Mapping of position IDs to their respective positions
    /// @dev Investor data
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) internal s_investorPositions;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer
     */
    modifier onlyLegion() {
        if (msg.sender != s_addressConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin
     */
    modifier onlyProject() {
        if (msg.sender != s_addressConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /**
     * @notice Restricts function access to either Legion or Project admin
     * @dev Reverts if caller is neither project admin nor Legion bouncer
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != s_addressConfig.projectAdmin && msg.sender != s_addressConfig.legionBouncer) {
            revert Errors.LegionSale__NotCalledByLegionOrProject();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionSale
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        // Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Requests a refund from the sale during the refund window
     * @dev Virtual function to process refunds; transfers capital back to investor
     */
    function refund() external virtual whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Cache the amount to refund in memory
        uint256 amountToRefund = s_investorPositions[positionId].investedCapital;

        // Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.LegionSale__InvalidRefundAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[positionId].hasRefunded = true;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amountToRefund);
    }

    /**
     * @notice Withdraws raised capital to the Project admin
     * @dev Virtual function restricted to Project; handles capital and fees
     */
    function withdrawRaisedCapital() external virtual onlyProject whenNotPaused {
        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that sale results have been published
        _verifySaleResultsArePublished();

        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Check if projects are withdrawing capital on the sale source chain
        if (s_addressConfig.askToken != address(0)) {
            // Allow projects to withdraw capital only in case they've supplied tokens
            _verifyTokensSupplied();
        }

        // Flag that the capital has been withdrawn
        s_saleStatus.capitalWithdrawn = true;

        // Cache value in memory
        uint256 _totalCapitalRaised = s_saleStatus.totalCapitalRaised;

        // Calculate Legion Fee
        uint256 _legionFee =
            (s_saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 _referrerFee =
            (s_saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised, msg.sender);

        // Transfer the raised capital to the project owner
        SafeTransferLib.safeTransfer(
            s_addressConfig.bidToken, msg.sender, (_totalCapitalRaised - _legionFee - _referrerFee)
        );

        // Transfer the Legion fee to the Legion fee receiver address
        if (_legionFee != 0) {
            SafeTransferLib.safeTransfer(s_addressConfig.bidToken, s_addressConfig.legionFeeReceiver, _legionFee);
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (_referrerFee != 0) {
            SafeTransferLib.safeTransfer(s_addressConfig.bidToken, s_addressConfig.referrerFeeReceiver, _referrerFee);
        }
    }

    /**
     * @notice Claims token allocation for an investor
     * @dev Virtual function handling vesting and immediate distribution
     * @param amount Total amount of tokens to claim
     * @param investorVestingConfig Vesting configuration for the investor
     * @param proof Merkle proof for claim verification
     */
    function claimTokenAllocation(
        uint256 amount,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes32[] calldata proof
    )
        external
        virtual
        whenNotPaused
    {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the vesting configuration is valid
        _verifyValidLinearVestingConfig(investorVestingConfig);

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that sales results have been published
        _verifySaleResultsArePublished();

        // Verify that the investor is eligible to claim the requested amount
        _verifyCanClaimTokenAllocation(msg.sender, amount, investorVestingConfig, proof);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        // Mark that the token amount has been settled
        position.hasSettled = true;

        // Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            amount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        // Calculate the remaining amount to be vested
        uint256 amountToBeVested = amount - amountToDistributeOnClaim;

        // Emit TokenAllocationClaimed
        emit TokenAllocationClaimed(amount, msg.sender);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            // Deploy a linear vesting schedule contract
            address payable vestingAddress = _createVesting(investorVestingConfig);

            // Save the vesting address for the investor
            position.vestingAddress = vestingAddress;

            // Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransfer(s_addressConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(s_addressConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Withdraws excess invested capital back to the investor
     * @dev Virtual function using Merkle proof for verification
     * @param amount Amount of excess capital to withdraw
     * @param proof Merkle proof for excess capital verification
     */
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external virtual whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, positionId, amount, proof);

        // Mark that the excess capital has been returned
        s_investorPositions[positionId].hasClaimedExcess = true;

        if (amount != 0) {
            // Decrement the total invested capital for the investor
            s_investorPositions[positionId].investedCapital -= amount;

            // Decrement total capital invested from investors
            s_saleStatus.totalCapitalInvested -= amount;

            // Emit ExcessCapitalWithdrawn
            emit ExcessCapitalWithdrawn(amount, msg.sender, positionId);

            // Transfer the excess capital back to the investor
            SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amount);
        }
    }

    /**
     * @notice Releases vested tokens to the investor
     * @dev Virtual function interacting with vesting contract
     */
    function releaseVestedTokens() external virtual whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Get the investor position details
        InvestorPosition memory position = s_investorPositions[positionId];

        // Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(position.vestingAddress).release(s_addressConfig.askToken);
    }

    /**
     * @notice Supplies tokens for distribution post-sale
     * @dev Virtual function restricted to Project; handles token and fee transfers
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(
        uint256 amount,
        uint256 legionFee,
        uint256 referrerFee
    )
        external
        virtual
        onlyProject
        whenNotPaused
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Verify that tokens have not been supplied
        _verifyTokensNotSupplied();

        // Flag that tokens have been supplied
        s_saleStatus.tokensSupplied = true;

        /// Calculate the expected Legion Fee amount
        uint256 expectedLegionFeeAmount =
            (s_saleConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        /// Calculate the expected Referrer Fee amount
        uint256 expectedReferrerFeeAmount =
            (s_saleConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR;

        /// Verify Legion Fee amount
        if (legionFee != (expectedLegionFeeAmount)) {
            revert Errors.LegionSale__InvalidFeeAmount(legionFee, expectedLegionFeeAmount);
        }

        /// Verify Referrer Fee amount
        if (referrerFee != expectedReferrerFeeAmount) {
            revert Errors.LegionSale__InvalidFeeAmount(referrerFee, expectedReferrerFeeAmount);
        }

        // Emit TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(s_addressConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_addressConfig.askToken, msg.sender, s_addressConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_addressConfig.askToken, msg.sender, s_addressConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /**
     * @notice Sets the Merkle root for accepted capital
     * @dev Virtual function restricted to Legion; updates verification data
     * @param merkleRoot Merkle root for accepted capital verification
     */
    function setAcceptedCapital(bytes32 merkleRoot) external virtual onlyLegion {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Set the merkle root for accepted capital
        s_saleStatus.acceptedCapitalMerkleRoot = merkleRoot;

        // Emit AcceptedCapitalSet
        emit AcceptedCapitalSet(merkleRoot);
    }

    /**
     * @notice Withdraws invested capital if the sale is canceled
     * @dev Virtual function to return capital post-cancellation
     */
    function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        // Cache the amount to refund in memory
        uint256 amountToWithdraw = s_investorPositions[positionId].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToWithdraw == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        // Set the total invested capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        // Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToWithdraw;

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_addressConfig.bidToken, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Performs an emergency withdrawal of tokens
     * @dev Virtual function restricted to Legion; used for safety measures
     * @param receiver Address to receive tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external virtual onlyLegion {
        // Emit EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        // Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Virtual function restricted to Legion; updates address configuration
     */
    function syncLegionAddresses() external virtual onlyLegion {
        // Sync the Legion addresses
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the sale
     * @dev Virtual function restricted to Legion; halts operations
     */
    function pauseSale() external virtual onlyLegion {
        // Pause the sale
        _pause();
    }

    /**
     * @notice Unpauses the sale
     * @dev Virtual function restricted to Legion; resumes operations
     */
    function unpauseSale() external virtual onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     */
    function transferInvestorPosition(
        address from,
        address to,
        uint256 positionId
    )
        external
        virtual
        override
        onlyLegion
        whenNotPaused
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();

        /// Transfer the investor position to the new address
        _transferInvestorPosition(from, to, positionId);
    }

    /**
     * @notice Transfers an investor position with a signature
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @param signature The signature authorizing the transfer
     */
    function transferInvestorPositionWithSignature(
        address from,
        address to,
        uint256 positionId,
        bytes calldata signature
    )
        external
        virtual
        override
        whenNotPaused
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();

        // Verify the signature for transferring the position
        _verifyTransferSignature(from, to, positionId, s_addressConfig.legionSigner, signature);

        /// Transfer the investor position to the new address
        _transferInvestorPosition(from, to, positionId);
    }

    /**
     * @notice Returns the current sale configuration
     * @dev Virtual function providing read-only access to s_saleConfig
     * @return LegionSaleConfiguration memory Struct containing sale configuration
     */
    function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory) {
        return s_saleConfig;
    }

    /**
     * @notice Returns the current sale status
     * @dev Virtual function providing read-only access to s_saleStatus
     * @return LegionSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view virtual returns (LegionSaleStatus memory) {
        return s_saleStatus;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Virtual function providing read-only access to investor position
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view virtual returns (InvestorPosition memory) {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investorAddress);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /**
     * @notice Returns an investor's vesting status
     * @dev Queries vesting contract if applicable; returns status
     * @param investor Address of the investor
     * @return vestingStatus LegionInvestorVestingStatus memory Struct containing vesting status details
     */
    function investorVestingStatus(address investor)
        external
        view
        virtual
        returns (LegionInvestorVestingStatus memory vestingStatus)
    {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Get the investor position details
        address investorVestingAddress = s_investorPositions[positionId].vestingAddress;

        // Return the investor vesting status
        investorVestingAddress != address(0)
            ? vestingStatus = LegionInvestorVestingStatus(
                ILegionVesting(investorVestingAddress).start(),
                ILegionVesting(investorVestingAddress).end(),
                ILegionVesting(investorVestingAddress).cliffEndTimestamp(),
                ILegionVesting(investorVestingAddress).duration(),
                ILegionVesting(investorVestingAddress).released(s_addressConfig.askToken),
                ILegionVesting(investorVestingAddress).releasable(s_addressConfig.askToken),
                ILegionVesting(investorVestingAddress).vestedAmount(s_addressConfig.askToken, uint64(block.timestamp))
            )
            : vestingStatus;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Cancels the ongoing sale
     * @dev Virtual function restricted to Project; allows cancellation before results
     */
    function cancelSale() public virtual onlyProject whenNotPaused {
        // Allow the Project to cancel the sale at any time until results are published
        _verifySaleResultsNotPublished();

        // Verify sale has not already been canceled
        _verifySaleNotCanceled();

        // Mark sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit SaleCanceled
        emit SaleCanceled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sale parameters during initialization
     * @dev Virtual function to configure sale; restricted to initialization
     * @param saleInitParams Calldata struct with initialization parameters
     */
    function _setLegionSaleConfig(LegionSaleInitializationParams calldata saleInitParams)
        internal
        virtual
        onlyInitializing
    {
        // Verify if the sale common configuration is valid
        _verifyValidInitParams(saleInitParams);

        // Set the sale configuration
        s_saleConfig.legionFeeOnCapitalRaisedBps = saleInitParams.legionFeeOnCapitalRaisedBps;
        s_saleConfig.legionFeeOnTokensSoldBps = saleInitParams.legionFeeOnTokensSoldBps;
        s_saleConfig.referrerFeeOnCapitalRaisedBps = saleInitParams.referrerFeeOnCapitalRaisedBps;
        s_saleConfig.referrerFeeOnTokensSoldBps = saleInitParams.referrerFeeOnTokensSoldBps;
        s_saleConfig.minimumInvestAmount = saleInitParams.minimumInvestAmount;

        // Set the address configuration
        s_addressConfig.bidToken = saleInitParams.bidToken;
        s_addressConfig.askToken = saleInitParams.askToken;
        s_addressConfig.projectAdmin = saleInitParams.projectAdmin;
        s_addressConfig.addressRegistry = saleInitParams.addressRegistry;
        s_addressConfig.referrerFeeReceiver = saleInitParams.referrerFeeReceiver;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Virtual function updating address configuration internally
     */
    function _syncLegionAddresses() internal virtual {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_addressConfig.legionBouncer =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_addressConfig.legionSigner =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_addressConfig.legionFeeReceiver =
            ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        s_vestingConfig.vestingFactory = ILegionAddressRegistry(s_addressConfig.addressRegistry).getLegionAddress(
            Constants.LEGION_VESTING_FACTORY_ID
        );

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            s_addressConfig.legionBouncer,
            s_addressConfig.legionSigner,
            s_addressConfig.legionFeeReceiver,
            s_vestingConfig.vestingFactory
        );
    }

    /**
     * @notice Verifies investor eligibility to claim token allocation
     * @dev Virtual function using Merkle proof for verification
     * @param _investor Address of the investor
     * @param _amount Amount of tokens to claim
     * @param investorVestingConfig Vesting configuration for the investor
     * @param _proof Merkle proof for claim verification
     */
    function _verifyCanClaimTokenAllocation(
        address _investor,
        uint256 _amount,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(_investor);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        // Generate the merkle leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount, investorVestingConfig))));

        // Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, s_saleStatus.claimTokensMerkleRoot, leaf)) {
            revert Errors.LegionSale__NotInClaimWhitelist(_investor);
        }

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(_investor);
    }

    /**
     * @notice Verifies investor eligibility to claim excess capital
     * @dev Virtual function using Merkle proof for verification
     * @param _investor Address of the investor
     * @param _positionId Position ID of the investor
     * @param _amount Amount of excess capital to claim
     * @param _proof Merkle proof for excess capital verification
     */
    function _verifyCanClaimExcessCapital(
        address _investor,
        uint256 _positionId,
        uint256 _amount,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Load the investor position
        InvestorPosition memory position = s_investorPositions[_positionId];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.LegionSale__AlreadyClaimedExcess(_investor);

        // Safeguard to check if the investor has invested capital
        if (position.investedCapital == 0) revert Errors.LegionSale__NoCapitalInvested(_investor);

        // Generate the merkle leaf and verify accepted capital
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, (position.investedCapital - _amount)))));

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, s_saleStatus.acceptedCapitalMerkleRoot, leaf)) {
            revert Errors.LegionSale__CannotWithdrawExcessInvestedCapital(_investor, _amount);
        }
    }

    /**
     * @notice Verifies the validity of sale initialization parameters
     * @dev Virtual function checking configuration constraints
     * @param saleInitParams Struct with initialization parameters
     */
    function _verifyValidInitParams(LegionSaleInitializationParams memory saleInitParams) internal view virtual {
        // Check for zero addresses provided
        if (
            saleInitParams.bidToken == address(0) || saleInitParams.projectAdmin == address(0)
                || saleInitParams.addressRegistry == address(0)
        ) {
            revert Errors.LegionSale__ZeroAddressProvided();
        }

        // Check for zero values provided
        if (saleInitParams.salePeriodSeconds == 0 || saleInitParams.refundPeriodSeconds == 0) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check if sale and refund periods are longer than allowed
        if (saleInitParams.salePeriodSeconds > 12 weeks || saleInitParams.refundPeriodSeconds > 2 weeks) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }

        // Check if sale and refund periods are shorter than allowed
        if (saleInitParams.salePeriodSeconds < 1 hours || saleInitParams.refundPeriodSeconds < 1 hours) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }
    }

    /**
     * @notice Verifies that the invested amount meets the minimum requirement
     * @dev Virtual function checking investment threshold
     * @param _amount Amount being invested
     */
    function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual {
        if (_amount < s_saleConfig.minimumInvestAmount) revert Errors.LegionSale__InvalidInvestAmount(_amount);
    }

    /**
     * @notice Verifies that the sale has not ended
     * @dev Virtual function checking sale end time
     */
    function _verifySaleHasNotEnded() internal view virtual {
        if (block.timestamp >= s_saleConfig.endTime) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /**
     * @notice Verifies that the refund period is over
     * @dev Virtual function checking refund window
     */
    function _verifyRefundPeriodIsOver() internal view virtual {
        if (block.timestamp < s_saleConfig.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, s_saleConfig.refundEndTime);
        }
    }

    /**
     * @notice Verifies that the refund period is not over
     * @dev Virtual function checking refund window
     */
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        if (block.timestamp >= s_saleConfig.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, s_saleConfig.refundEndTime);
        }
    }

    /**
     * @notice Verifies that sale results are published
     * @dev Virtual function checking token allocation status
     */
    function _verifySaleResultsArePublished() internal view virtual {
        if (s_saleStatus.totalTokensAllocated == 0) revert Errors.LegionSale__SaleResultsNotPublished();
    }

    /**
     * @notice Verifies that sale results are not published
     * @dev Virtual function checking token allocation status
     */
    function _verifySaleResultsNotPublished() internal view virtual {
        if (s_saleStatus.totalTokensAllocated != 0) revert Errors.LegionSale__SaleResultsAlreadyPublished();
    }

    /**
     * @notice Verifies conditions for supplying tokens
     * @dev Virtual function ensuring token supply validity
     * @param _amount Amount of tokens to supply
     */
    function _verifyCanSupplyTokens(uint256 _amount) internal view virtual {
        // Revert if Legion has not set the total amount of tokens allocated for distribution
        if (s_saleStatus.totalTokensAllocated == 0) revert Errors.LegionSale__TokensNotAllocated();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != s_saleStatus.totalTokensAllocated) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(_amount, s_saleStatus.totalTokensAllocated);
        }
    }

    /**
     * @notice Verifies conditions for publishing sale results
     * @dev Virtual function ensuring results can be set
     */
    function _verifyCanPublishSaleResults() internal view virtual {
        if (s_saleStatus.totalTokensAllocated != 0) revert Errors.LegionSale__TokensAlreadyAllocated();
    }

    /**
     * @notice Verifies that the sale is not canceled
     * @dev Virtual function checking cancellation status
     */
    function _verifySaleNotCanceled() internal view virtual {
        if (s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /**
     * @notice Verifies that the sale is canceled
     * @dev Virtual function checking cancellation status
     */
    function _verifySaleIsCanceled() internal view virtual {
        if (!s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /**
     * @notice Verifies that tokens have not been supplied
     * @dev Virtual function checking token supply status
     */
    function _verifyTokensNotSupplied() internal view virtual {
        if (s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();
    }

    /**
     * @notice Verifies that tokens have been supplied
     * @dev Virtual function checking token supply status
     */
    function _verifyTokensSupplied() internal view virtual {
        if (!s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();
    }

    /**
     * @notice Verifies that a invest signature is valid
     * @dev Virtual function validating signature authenticity
     * @param _signature Signature to verify
     */
    function _verifyInvestSignature(bytes memory _signature) internal view virtual {
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();
        if (_data.recover(_signature) != s_addressConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(_signature);
        }
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Virtual function ensuring withdrawal eligibility
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        if (s_saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (s_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /**
     * @notice Verifies that the investor has not refunded
     * @param positionId ID of the investor's position
     * @dev Virtual function checking refund status
     */
    function _verifyHasNotRefunded(uint256 positionId) internal view virtual {
        if (s_investorPositions[positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verifies that the investor has not claimed excess capital
     * @param positionId ID of the investor's position
     * @dev Virtual function checking excess claim status
     */
    function _verifyHasNotClaimedExcess(uint256 positionId) internal view virtual {
        if (s_investorPositions[positionId].hasClaimedExcess) {
            revert Errors.LegionSale__InvestorHasClaimedExcess(msg.sender);
        }
    }
}
