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
import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";

import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Sale
 * @author Legion
 * @notice A contract used for managing token sales in the Legion Protocol
 * @dev Abstract base contract implementing ILegionSale with vesting, pausing, and core sale functionality
 */
abstract contract LegionSale is ILegionSale, LegionVestingManager, Initializable, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the sale configuration
    /// @dev Stores general sale parameters internally
    LegionSaleConfiguration internal saleConfig;

    /// @notice Struct containing the sale addresses configuration
    /// @dev Stores address-related settings internally
    LegionSaleAddressConfiguration internal addressConfig;

    /// @notice Struct tracking the current sale status
    /// @dev Maintains runtime state of the sale internally
    LegionSaleStatus internal saleStatus;

    /// @notice Mapping of investor addresses to their positions
    /// @dev Tracks investor data internally
    mapping(address investorAddress => InvestorPosition investorPosition) internal investorPositions;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer
     */
    modifier onlyLegion() {
        if (msg.sender != addressConfig.legionBouncer) revert Errors.NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin
     */
    modifier onlyProject() {
        if (msg.sender != addressConfig.projectAdmin) revert Errors.NotCalledByProject();
        _;
    }

    /**
     * @notice Restricts function access to either Legion or Project admin
     * @dev Reverts if caller is neither project admin nor Legion bouncer
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != addressConfig.projectAdmin && msg.sender != addressConfig.legionBouncer) {
            revert Errors.NotCalledByLegionOrProject();
        }
        _;
    }

    /**
     * @notice Ensures the ask token is available before execution
     * @dev Reverts if askToken address is not set
     */
    modifier askTokenAvailable() {
        if (addressConfig.askToken == address(0)) revert Errors.AskTokenUnavailable();
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
        // Verify that the refund period is not over
        _verifyRefundPeriodIsNotOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Cache the amount to refund in memory
        uint256 amountToRefund = investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.InvalidRefundAmount();

        // Set the total invested capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        // Flag that the investor has refunded
        investorPositions[msg.sender].hasRefunded = true;

        // Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amountToRefund;

        // Emit CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amountToRefund);
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
        if (addressConfig.askToken != address(0)) {
            // Allow projects to withdraw capital only in case they've supplied tokens
            _verifyTokensSupplied();
        }

        // Flag that the capital has been withdrawn
        saleStatus.capitalWithdrawn = true;

        // Cache value in memory
        uint256 _totalCapitalRaised = saleStatus.totalCapitalRaised;

        // Calculate Legion Fee
        uint256 _legionFee =
            (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 _referrerFee =
            (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised, msg.sender);

        // Transfer the raised capital to the project owner
        SafeTransferLib.safeTransfer(
            addressConfig.bidToken, msg.sender, (_totalCapitalRaised - _legionFee - _referrerFee)
        );

        // Transfer the Legion fee to the Legion fee receiver address
        if (_legionFee != 0) {
            SafeTransferLib.safeTransfer(addressConfig.bidToken, addressConfig.legionFeeReceiver, _legionFee);
        }

        // Transfer the Referrer fee to the Referrer fee receiver address
        if (_referrerFee != 0) {
            SafeTransferLib.safeTransfer(addressConfig.bidToken, addressConfig.referrerFeeReceiver, _referrerFee);
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
        askTokenAvailable
        whenNotPaused
    {
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
        InvestorPosition storage position = investorPositions[msg.sender];

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
            SafeTransferLib.safeTransfer(addressConfig.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            // Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(addressConfig.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Withdraws excess invested capital back to the investor
     * @dev Virtual function using Merkle proof for verification
     * @param amount Amount of excess capital to withdraw
     * @param proof Merkle proof for excess capital verification
     */
    function withdrawExcessInvestedCapital(uint256 amount, bytes32[] calldata proof) external virtual whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Verify that the investor is eligible to get excess capital back
        _verifyCanClaimExcessCapital(msg.sender, amount, proof);

        // Mark that the excess capital has been returned
        investorPositions[msg.sender].hasClaimedExcess = true;

        if (amount != 0) {
            // Decrement the total invested capital for the investor
            investorPositions[msg.sender].investedCapital -= amount;

            // Decrement total capital invested from investors
            saleStatus.totalCapitalInvested -= amount;

            // Emit ExcessCapitalWithdrawn
            emit ExcessCapitalWithdrawn(amount, msg.sender);

            // Transfer the excess capital back to the investor
            SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amount);
        }
    }

    /**
     * @notice Releases vested tokens to the investor
     * @dev Virtual function interacting with vesting contract
     */
    function releaseVestedTokens() external virtual askTokenAvailable whenNotPaused {
        // Get the investor position details
        InvestorPosition memory position = investorPositions[msg.sender];

        // Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.ZeroAddressProvided();

        // Release tokens to the investor account
        ILegionVesting(position.vestingAddress).release(addressConfig.askToken);
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
        askTokenAvailable
        whenNotPaused
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

        // Verify that tokens have not been supplied
        _verifyTokensNotSupplied();

        // Flag that tokens have been supplied
        saleStatus.tokensSupplied = true;

        // Calculate and verify Legion Fee
        if (legionFee != (saleConfig.legionFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR) {
            revert Errors.InvalidFeeAmount();
        }

        // Calculate and verify Referrer Fee
        if (referrerFee != (saleConfig.referrerFeeOnTokensSoldBps * amount) / Constants.BASIS_POINTS_DENOMINATOR) {
            revert Errors.InvalidFeeAmount();
        }

        // Emit TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        // Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(addressConfig.askToken, msg.sender, address(this), amount);

        // Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.legionFeeReceiver, legionFee
            );
        }

        // Transfer the Referrer fee to the referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                addressConfig.askToken, msg.sender, addressConfig.referrerFeeReceiver, referrerFee
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
        saleStatus.acceptedCapitalMerkleRoot = merkleRoot;

        // Emit AcceptedCapitalSet
        emit AcceptedCapitalSet(merkleRoot);
    }

    /**
     * @notice Withdraws invested capital if the sale is canceled
     * @dev Virtual function to return capital post-cancellation
     */
    function withdrawInvestedCapitalIfCanceled() external virtual whenNotPaused {
        // Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        // Cache the amount to refund in memory
        uint256 amountToWithdraw = investorPositions[msg.sender].investedCapital;

        // Revert in case there's nothing to claim
        if (amountToWithdraw == 0) revert Errors.InvalidWithdrawAmount();

        // Set the total invested capital for the investor to 0
        investorPositions[msg.sender].investedCapital = 0;

        // Decrement total capital invested from investors
        saleStatus.totalCapitalInvested -= amountToWithdraw;

        // Emit CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToWithdraw, msg.sender);

        // Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(addressConfig.bidToken, msg.sender, amountToWithdraw);
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
     * @notice Returns the current sale configuration
     * @dev Virtual function providing read-only access to saleConfig
     * @return LegionSaleConfiguration memory Struct containing sale configuration
     */
    function saleConfiguration() external view virtual returns (LegionSaleConfiguration memory) {
        return saleConfig;
    }

    /**
     * @notice Returns the current sale status
     * @dev Virtual function providing read-only access to saleStatus
     * @return LegionSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view virtual returns (LegionSaleStatus memory) {
        return saleStatus;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Virtual function providing read-only access to investor position
     * @param investorAddress Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investorAddress) external view virtual returns (InvestorPosition memory) {
        return investorPositions[investorAddress];
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
        /// Get the investor position details
        address investorVestingAddress = investorPositions[investor].vestingAddress;

        // Return the investor vesting status
        investorVestingAddress != address(0)
            ? vestingStatus = LegionInvestorVestingStatus(
                ILegionVesting(investorVestingAddress).start(),
                ILegionVesting(investorVestingAddress).end(),
                ILegionVesting(investorVestingAddress).cliffEndTimestamp(),
                ILegionVesting(investorVestingAddress).duration(),
                ILegionVesting(investorVestingAddress).released(addressConfig.askToken),
                ILegionVesting(investorVestingAddress).releasable(addressConfig.askToken),
                ILegionVesting(investorVestingAddress).vestedAmount(addressConfig.askToken, uint64(block.timestamp))
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
        saleStatus.isCanceled = true;

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
        saleConfig.legionFeeOnCapitalRaisedBps = saleInitParams.legionFeeOnCapitalRaisedBps;
        saleConfig.legionFeeOnTokensSoldBps = saleInitParams.legionFeeOnTokensSoldBps;
        saleConfig.referrerFeeOnCapitalRaisedBps = saleInitParams.referrerFeeOnCapitalRaisedBps;
        saleConfig.referrerFeeOnTokensSoldBps = saleInitParams.referrerFeeOnTokensSoldBps;
        saleConfig.minimumInvestAmount = saleInitParams.minimumInvestAmount;

        // Set the address configuration
        addressConfig.bidToken = saleInitParams.bidToken;
        addressConfig.askToken = saleInitParams.askToken;
        addressConfig.projectAdmin = saleInitParams.projectAdmin;
        addressConfig.addressRegistry = saleInitParams.addressRegistry;
        addressConfig.referrerFeeReceiver = saleInitParams.referrerFeeReceiver;

        // Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the address registry
     * @dev Virtual function updating address configuration internally
     */
    function _syncLegionAddresses() internal virtual {
        // Cache Legion addresses from `LegionAddressRegistry`
        addressConfig.legionBouncer =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        addressConfig.legionSigner =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        addressConfig.legionFeeReceiver =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        vestingConfig.vestingFactory =
            ILegionAddressRegistry(addressConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit LegionAddressesSynced
        emit LegionAddressesSynced(
            addressConfig.legionBouncer,
            addressConfig.legionSigner,
            addressConfig.legionFeeReceiver,
            vestingConfig.vestingFactory
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
        // Generate the merkle leaf
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, _amount, investorVestingConfig))));

        // Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, saleStatus.claimTokensMerkleRoot, leaf)) {
            revert Errors.NotInClaimWhitelist(_investor);
        }

        // Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.AlreadySettled(_investor);
    }

    /**
     * @notice Verifies investor eligibility to claim excess capital
     * @dev Virtual function using Merkle proof for verification
     * @param _investor Address of the investor
     * @param _amount Amount of excess capital to claim
     * @param _proof Merkle proof for excess capital verification
     */
    function _verifyCanClaimExcessCapital(
        address _investor,
        uint256 _amount,
        bytes32[] calldata _proof
    )
        internal
        view
        virtual
    {
        // Load the investor position
        InvestorPosition memory position = investorPositions[_investor];

        // Check if the investor has already settled their allocation
        if (position.hasClaimedExcess) revert Errors.AlreadyClaimedExcess(_investor);

        // Safeguard to check if the investor has invested capital
        if (position.investedCapital == 0) revert Errors.NoCapitalInvested(_investor);

        // Generate the merkle leaf and verify accepted capital
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_investor, (position.investedCapital - _amount)))));

        // Verify the merkle proof
        if (!MerkleProofLib.verify(_proof, saleStatus.acceptedCapitalMerkleRoot, leaf)) {
            revert Errors.CannotWithdrawExcessInvestedCapital(_investor);
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
            revert Errors.ZeroAddressProvided();
        }

        // Check for zero values provided
        if (saleInitParams.salePeriodSeconds == 0 || saleInitParams.refundPeriodSeconds == 0) {
            revert Errors.ZeroValueProvided();
        }

        // Check if sale and refund periods are longer than allowed
        if (saleInitParams.salePeriodSeconds > 12 weeks || saleInitParams.refundPeriodSeconds > 2 weeks) {
            revert Errors.InvalidPeriodConfig();
        }

        // Check if sale and refund periods are shorter than allowed
        if (saleInitParams.salePeriodSeconds < 1 hours || saleInitParams.refundPeriodSeconds < 1 hours) {
            revert Errors.InvalidPeriodConfig();
        }
    }

    /**
     * @notice Verifies that the invested amount meets the minimum requirement
     * @dev Virtual function checking investment threshold
     * @param _amount Amount being invested
     */
    function _verifyMinimumInvestAmount(uint256 _amount) internal view virtual {
        if (_amount < saleConfig.minimumInvestAmount) revert Errors.InvalidInvestAmount(_amount);
    }

    /**
     * @notice Verifies that the sale has not ended
     * @dev Virtual function checking sale end time
     */
    function _verifySaleHasNotEnded() internal view virtual {
        if (block.timestamp >= saleConfig.endTime) revert Errors.SaleHasEnded();
    }

    /**
     * @notice Verifies that the refund period is over
     * @dev Virtual function checking refund window
     */
    function _verifyRefundPeriodIsOver() internal view virtual {
        if (block.timestamp < saleConfig.refundEndTime) revert Errors.RefundPeriodIsNotOver();
    }

    /**
     * @notice Verifies that the refund period is not over
     * @dev Virtual function checking refund window
     */
    function _verifyRefundPeriodIsNotOver() internal view virtual {
        if (block.timestamp >= saleConfig.refundEndTime) revert Errors.RefundPeriodIsOver();
    }

    /**
     * @notice Verifies that sale results are published
     * @dev Virtual function checking token allocation status
     */
    function _verifySaleResultsArePublished() internal view virtual {
        if (saleStatus.totalTokensAllocated == 0) revert Errors.SaleResultsNotPublished();
    }

    /**
     * @notice Verifies that sale results are not published
     * @dev Virtual function checking token allocation status
     */
    function _verifySaleResultsNotPublished() internal view virtual {
        if (saleStatus.totalTokensAllocated != 0) revert Errors.SaleResultsAlreadyPublished();
    }

    /**
     * @notice Verifies conditions for supplying tokens
     * @dev Virtual function ensuring token supply validity
     * @param _amount Amount of tokens to supply
     */
    function _verifyCanSupplyTokens(uint256 _amount) internal view virtual {
        // Revert if Legion has not set the total amount of tokens allocated for distribution
        if (saleStatus.totalTokensAllocated == 0) revert Errors.TokensNotAllocated();

        // Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != saleStatus.totalTokensAllocated) revert Errors.InvalidTokenAmountSupplied(_amount);
    }

    /**
     * @notice Verifies conditions for publishing sale results
     * @dev Virtual function ensuring results can be set
     */
    function _verifyCanPublishSaleResults() internal view virtual {
        if (saleStatus.totalTokensAllocated != 0) revert Errors.TokensAlreadyAllocated();
    }

    /**
     * @notice Verifies that the sale is not canceled
     * @dev Virtual function checking cancellation status
     */
    function _verifySaleNotCanceled() internal view virtual {
        if (saleStatus.isCanceled) revert Errors.SaleIsCanceled();
    }

    /**
     * @notice Verifies that the sale is canceled
     * @dev Virtual function checking cancellation status
     */
    function _verifySaleIsCanceled() internal view virtual {
        if (!saleStatus.isCanceled) revert Errors.SaleIsNotCanceled();
    }

    /**
     * @notice Verifies that tokens have not been supplied
     * @dev Virtual function checking token supply status
     */
    function _verifyTokensNotSupplied() internal view virtual {
        if (saleStatus.tokensSupplied) revert Errors.TokensAlreadySupplied();
    }

    /**
     * @notice Verifies that tokens have been supplied
     * @dev Virtual function checking token supply status
     */
    function _verifyTokensSupplied() internal view virtual {
        if (!saleStatus.tokensSupplied) revert Errors.TokensNotSupplied();
    }

    /**
     * @notice Verifies that a signature is from Legion
     * @dev Virtual function validating signature authenticity
     * @param _signature Signature to verify
     */
    function _verifyLegionSignature(bytes memory _signature) internal view virtual {
        bytes32 _data = keccak256(abi.encodePacked(msg.sender, address(this), block.chainid)).toEthSignedMessageHash();
        if (_data.recover(_signature) != addressConfig.legionSigner) revert Errors.InvalidSignature();
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Virtual function ensuring withdrawal eligibility
     */
    function _verifyCanWithdrawCapital() internal view virtual {
        if (saleStatus.capitalWithdrawn) revert Errors.CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.CapitalNotRaised();
    }

    /**
     * @notice Verifies that the investor has not refunded
     * @dev Virtual function checking refund status
     */
    function _verifyHasNotRefunded() internal view virtual {
        if (investorPositions[msg.sender].hasRefunded) revert Errors.InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verifies that the investor has not claimed excess capital
     * @dev Virtual function checking excess claim status
     */
    function _verifyHasNotClaimedExcess() internal view virtual {
        if (investorPositions[msg.sender].hasClaimedExcess) revert Errors.InvestorHasClaimedExcess(msg.sender);
    }
}
