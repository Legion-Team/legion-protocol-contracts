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
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionAddressRegistry } from "../interfaces/registries/ILegionAddressRegistry.sol";
import { ILegionPreLiquidSaleV1 } from "../interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionVesting } from "../interfaces/vesting/ILegionVesting.sol";

import { LegionPositionManager } from "../position/LegionPositionManager.sol";
import { LegionVestingManager } from "../vesting/LegionVestingManager.sol";

/**
 * @title Legion Pre-Liquid Sale V1
 * @author Legion
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE
 * @dev Manages pre-liquid sale lifecycle including investment, refunds, token supply, and vesting; inherits from
 * multiple contracts
 */
contract LegionPreLiquidSaleV1 is
    ILegionPreLiquidSaleV1,
    LegionVestingManager,
    LegionPositionManager,
    Initializable,
    Pausable
{
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the pre-liquid sale configuration
    /// @dev Stores sale parameters and settings
    PreLiquidSaleConfig private s_saleConfig;

    /// @notice Struct tracking the current sale status
    /// @dev Maintains runtime state of the sale
    PreLiquidSaleStatus private s_saleStatus;

    /// @notice Mapping of position IDs to their respective positions
    /// @dev Investor data
    mapping(uint256 s_positionId => InvestorPosition s_investorPosition) private s_investorPositions;

    /// @notice Mapping to track used signatures per investor to prevent replay attacks
    /// @dev Nested mapping for signature usage status
    mapping(address s_investorAddress => mapping(bytes s_signature => bool s_used) s_usedSignature) private
        s_usedSignatures;

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Restricts function access to the Legion address only
     * @dev Reverts if caller is not the configured Legion bouncer address
     */
    modifier onlyLegion() {
        if (msg.sender != s_saleConfig.legionBouncer) revert Errors.LegionSale__NotCalledByLegion();
        _;
    }

    /**
     * @notice Restricts function access to the Project admin only
     * @dev Reverts if caller is not the configured project admin address
     */
    modifier onlyProject() {
        if (msg.sender != s_saleConfig.projectAdmin) revert Errors.LegionSale__NotCalledByProject();
        _;
    }

    /**
     * @notice Restricts function access to either Legion or Project admin
     * @dev Reverts if caller is neither the project admin nor Legion bouncer
     */
    modifier onlyLegionOrProject() {
        if (msg.sender != s_saleConfig.projectAdmin && msg.sender != s_saleConfig.legionBouncer) {
            revert Errors.LegionSale__NotCalledByLegionOrProject();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructor for LegionPreLiquidSaleV1
     * @dev Disables initializers to prevent uninitialized deployment
     */
    constructor() {
        /// Disable initialization
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the pre-liquid sale contract with parameters
     * @dev Sets up sale configuration; callable only once during initialization
     * @param preLiquidSaleInitParams Calldata struct with pre-liquid sale initialization parameters
     */
    function initialize(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams) external initializer {
        _setLegionSaleConfig(preLiquidSaleInitParams);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to contribute capital to the pre-liquid sale
     * @dev Verifies conditions and updates state; uses SafeTransferLib for token transfer
     * @param amount Amount of capital (in bid tokens) to invest
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investSignature Signature verifying investor eligibility
     */
    function invest(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory investSignature
    )
        external
        whenNotPaused
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(investSignature);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        /// Increment total capital invested from investors
        s_saleStatus.totalCapitalInvested += amount;

        /// Increment total capital for the investor
        position.investedCapital += amount;

        /// Mark the signature as used
        s_usedSignatures[msg.sender][investSignature] = true;

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(investSignature, positionId, SaleAction.INVEST);

        /// Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, tokenAllocationRate, block.timestamp, positionId);

        /// Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_saleConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Processes a refund for an investor during the refund period
     * @dev Transfers invested capital back to the investor if conditions are met
     */
    function refund() external whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the investor can get a refund
        _verifyRefundPeriodIsNotOver();

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        /// Cache the amount to refund in memory
        uint256 amountToRefund = position.investedCapital;

        /// Revert in case there's nothing to refund
        if (amountToRefund == 0) revert Errors.LegionSale__InvalidRefundAmount(0);

        /// Set the total invested capital for the investor to 0
        position.investedCapital = 0;

        // Flag that the investor has refunded
        s_investorPositions[positionId].hasRefunded = true;

        /// Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amountToRefund;

        /// Burn the investor position ID
        _burnInvestorPosition(msg.sender);

        /// Emit successfully CapitalRefunded
        emit CapitalRefunded(amountToRefund, msg.sender, positionId);

        /// Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amountToRefund);
    }

    /**
     * @notice Publishes token details post-TGE
     * @dev Sets token-related data; restricted to Legion
     * @param _askToken Address of the token to be distributed
     * @param _askTokenTotalSupply Total supply of the ask token
     * @param _totalTokensAllocated Total tokens allocated for investors
     */
    function publishTgeDetails(
        address _askToken,
        uint256 _askTokenTotalSupply,
        uint256 _totalTokensAllocated
    )
        external
        onlyLegion
        whenNotPaused
    {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        /// Veriify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Set the address of the token distributed to investors
        s_saleStatus.askToken = _askToken;

        /// Set the total supply of the token distributed to investors
        s_saleStatus.askTokenTotalSupply = _askTokenTotalSupply;

        /// Set the total allocated amount of token for distribution.
        s_saleStatus.totalTokensAllocated = _totalTokensAllocated;

        /// Emit successfully TgeDetailsPublished
        emit TgeDetailsPublished(_askToken, _askTokenTotalSupply, _totalTokensAllocated);
    }

    /**
     * @notice Supplies tokens for distribution post-TGE
     * @dev Transfers tokens and fees; restricted to Project
     * @param amount Amount of tokens to supply
     * @param legionFee Fee amount for Legion
     * @param referrerFee Fee amount for referrer
     */
    function supplyTokens(uint256 amount, uint256 legionFee, uint256 referrerFee) external onlyProject whenNotPaused {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that tokens can be supplied for distribution
        _verifyCanSupplyTokens(amount);

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

        /// Flag that ask tokens have been supplied
        s_saleStatus.tokensSupplied = true;

        /// Emit successfully TokensSuppliedForDistribution
        emit TokensSuppliedForDistribution(amount, legionFee, referrerFee);

        /// Transfer the allocated amount of tokens for distribution
        SafeTransferLib.safeTransferFrom(s_saleStatus.askToken, msg.sender, address(this), amount);

        /// Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_saleStatus.askToken, msg.sender, s_saleConfig.legionFeeReceiver, legionFee
            );
        }

        /// Transfer the Referrer fee to the Referer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransferFrom(
                s_saleStatus.askToken, msg.sender, s_saleConfig.referrerFeeReceiver, referrerFee
            );
        }
    }

    /**
     * @notice Withdraws tokens in emergency situations
     * @dev Restricted to Legion; used for safety measures
     * @param receiver Address to receive withdrawn tokens
     * @param token Address of the token to withdraw
     * @param amount Amount of tokens to withdraw
     */
    function emergencyWithdraw(address receiver, address token, uint256 amount) external onlyLegion {
        /// Emit successfully EmergencyWithdraw
        emit EmergencyWithdraw(receiver, token, amount);

        /// Transfer the amount to Legion's address
        SafeTransferLib.safeTransfer(token, receiver, amount);
    }

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Transfers capital and fees; restricted to Project
     */
    function withdrawRaisedCapital() external onlyProject whenNotPaused {
        /// Verify that the sale is not canceled
        _verifySaleNotCanceled();

        /// Verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        /// Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        /// Account for the capital withdrawn
        s_saleStatus.totalCapitalWithdrawn = s_saleStatus.totalCapitalRaised;

        /// Calculate Legion Fee
        uint256 legionFee = (s_saleConfig.legionFeeOnCapitalRaisedBps * s_saleStatus.totalCapitalWithdrawn)
            / Constants.BASIS_POINTS_DENOMINATOR;

        /// Calculate Referrer Fee
        uint256 referrerFee = (s_saleConfig.referrerFeeOnCapitalRaisedBps * s_saleStatus.totalCapitalWithdrawn)
            / Constants.BASIS_POINTS_DENOMINATOR;

        /// Emit successfully CapitalWithdrawn
        emit CapitalWithdrawn(s_saleStatus.totalCapitalWithdrawn);

        /// Transfer the amount to the Project's address
        SafeTransferLib.safeTransfer(
            s_saleConfig.bidToken, msg.sender, (s_saleStatus.totalCapitalWithdrawn - legionFee - referrerFee)
        );

        /// Transfer the Legion fee to the Legion fee receiver address
        if (legionFee != 0) {
            SafeTransferLib.safeTransfer(s_saleConfig.bidToken, s_saleConfig.legionFeeReceiver, legionFee);
        }

        /// Transfer the Referrer fee to the Referrer fee receiver address
        if (referrerFee != 0) {
            SafeTransferLib.safeTransfer(s_saleConfig.bidToken, s_saleConfig.referrerFeeReceiver, referrerFee);
        }
    }

    /**
     * @notice Allows investors to claim their token allocation
     * @dev Handles vesting and immediate distribution; requires signatures
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param investorVestingConfig Vesting configuration for the investor
     * @param claimSignature Signature verifying investment eligibility
     * @param vestingSignature Signature verifying vesting terms
     */
    function claimTokenAllocation(
        uint256 investAmount,
        uint256 tokenAllocationRate,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig,
        bytes memory claimSignature,
        bytes memory vestingSignature
    )
        external
        whenNotPaused
    {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        // Verify that the vesting configuration is valid
        _verifyValidLinearVestingConfig(investorVestingConfig);

        /// Verify that the investor can claim the token allocation
        _verifyCanClaimTokenAllocation();

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(claimSignature, positionId, SaleAction.CLAIM_TOKEN_ALLOCATION);

        /// Verify that the investor vesting terms are valid
        _verifyValidVestingPosition(vestingSignature, investorVestingConfig);

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(claimSignature);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        /// Mark the signature as used
        s_usedSignatures[msg.sender][claimSignature] = true;

        /// Mark that the token amount has been settled
        position.hasSettled = true;

        /// Calculate the total token amount to be claimed
        uint256 totalAmount = s_saleStatus.askTokenTotalSupply * position.cachedTokenAllocationRate
            / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        /// Calculate the amount to be distributed on claim
        uint256 amountToDistributeOnClaim =
            totalAmount * investorVestingConfig.tokenAllocationOnTGERate / Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR;

        /// Calculate the remaining amount to be vested
        uint256 amountToBeVested = totalAmount - amountToDistributeOnClaim;

        /// Emit successfully TokenAllocationClaimed
        emit TokenAllocationClaimed(amountToBeVested, amountToDistributeOnClaim, msg.sender, positionId);

        // Deploy vesting and distribute tokens only if there is anything to distribute
        if (amountToBeVested != 0) {
            /// Deploy a vesting schedule contract
            address payable vestingAddress = _createVesting(investorVestingConfig);

            /// Save the vesting address for the investor
            position.vestingAddress = vestingAddress;

            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransfer(s_saleStatus.askToken, vestingAddress, amountToBeVested);
        }

        if (amountToDistributeOnClaim != 0) {
            /// Transfer the allocated amount of tokens for distribution on claim
            SafeTransferLib.safeTransfer(s_saleStatus.askToken, msg.sender, amountToDistributeOnClaim);
        }
    }

    /**
     * @notice Cancels the sale and handles capital return
     * @dev Restricted to Project; reverts if tokens supplied
     */
    function cancelSale() external onlyProject whenNotPaused {
        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();

        /// Cache the amount of funds to be returned to the sale
        uint256 capitalToReturn = s_saleStatus.totalCapitalWithdrawn;

        /// Mark the sale as canceled
        s_saleStatus.isCanceled = true;

        /// Emit successfully CapitalWithdrawn
        emit SaleCanceled();

        /// In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            /// Set the totalCapitalWithdrawn to zero
            s_saleStatus.totalCapitalWithdrawn = 0;
            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransferFrom(s_saleConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /**
     * @notice Allows investors to withdraw capital if sale is canceled
     * @dev Transfers invested capital back to investor
     */
    function withdrawInvestedCapitalIfCanceled() external whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Verify that the sale has been actually canceled
        _verifySaleIsCanceled();

        /// Cache the amount to refund in memory
        uint256 amountToClaim = s_investorPositions[positionId].investedCapital;

        /// Revert in case there's nothing to claim
        if (amountToClaim == 0) revert Errors.LegionSale__InvalidWithdrawAmount(0);

        /// Set the total pledged capital for the investor to 0
        s_investorPositions[positionId].investedCapital = 0;

        /// Decrement total capital pledged from investors
        s_saleStatus.totalCapitalInvested -= amountToClaim;

        /// Emit successfully CapitalRefundedAfterCancel
        emit CapitalRefundedAfterCancel(amountToClaim, msg.sender, positionId);

        /// Transfer the refunded amount back to the investor
        SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amountToClaim);
    }

    /**
     * @notice Withdraws excess invested capital back to investors
     * @dev Updates position and transfers excess; requires signature
     * @param amount Amount of excess capital to withdraw
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     * @param withdrawsignature Signature verifying eligibility
     */
    function withdrawExcessInvestedCapital(
        uint256 amount,
        uint256 investAmount,
        uint256 tokenAllocationRate,
        bytes memory withdrawsignature
    )
        external
        whenNotPaused
    {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        /// Verify that the signature has not been used
        _verifySignatureNotUsed(withdrawsignature);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        /// Decrement total capital invested from investors
        s_saleStatus.totalCapitalInvested -= amount;

        /// Decrement total investor capital for the investor
        position.investedCapital -= amount;

        /// Mark the signature as used
        s_usedSignatures[msg.sender][withdrawsignature] = true;

        /// Update the investor position
        _updateInvestorPosition(investAmount, tokenAllocationRate);

        /// Verify that the investor position is valid
        _verifyValidPosition(withdrawsignature, positionId, SaleAction.WITHDRAW_EXCESS_CAPITAL);

        /// Emit successfully ExcessCapitalWithdrawn
        emit ExcessCapitalWithdrawn(amount, msg.sender, tokenAllocationRate, block.timestamp, positionId);

        /// Transfer the excess capital to the investor
        SafeTransferLib.safeTransfer(s_saleConfig.bidToken, msg.sender, amount);
    }

    /**
     * @notice Releases vested tokens to the investor
     * @dev Calls vesting contract to release tokens
     */
    function releaseVestedTokens() external whenNotPaused {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Get the investor position details
        InvestorPosition memory position = s_investorPositions[positionId];

        /// Revert in case there's no vesting for the investor
        if (position.vestingAddress == address(0)) revert Errors.LegionSale__ZeroAddressProvided();

        /// Release tokens to the investor account
        ILegionVesting(position.vestingAddress).release(s_saleStatus.askToken);
    }

    /**
     * @notice Ends the sale manually
     * @dev Sets end times; restricted to Legion or Project
     */
    function endSale() external onlyLegionOrProject whenNotPaused {
        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        /// Verify that the sale has not been canceled
        _verifySaleNotCanceled();

        // Update the `hasEnded` status to false
        s_saleStatus.hasEnded = true;

        // Set the `endTime` of the sale
        s_saleStatus.endTime = block.timestamp;

        // Set the `refundEndTime` of the sale
        s_saleStatus.refundEndTime = block.timestamp + s_saleConfig.refundPeriodSeconds;

        /// Emit successfully SaleEnded
        emit SaleEnded(block.timestamp);
    }

    /**
     * @notice Publishes the total capital raised
     * @dev Sets capital raised; restricted to Legion
     * @param capitalRaised Total capital raised by the project
     */
    function publishCapitalRaised(uint256 capitalRaised) external onlyLegion whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised = capitalRaised;

        // Emit successfully CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised);
    }

    /**
     * @notice Transfers an investor position from one address to another
     * @param from The address of the current owner
     * @param to The address of the new owner
     * @param positionId The ID of the position
     * @dev Allow transfers only between end of refund period and before TGE
     */
    function transferInvestorPosition(
        address from,
        address to,
        uint256 positionId
    )
        external
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
     * @notice Syncs Legion addresses from the address registry
     * @dev Updates configuration with latest addresses; restricted to Legion
     */
    function syncLegionAddresses() external onlyLegion {
        _syncLegionAddresses();
    }

    /**
     * @notice Pauses the sale
     * @dev Triggers Pausable pause; restricted to Legion
     */
    function pauseSale() external onlyLegion {
        // Pause the sale
        _pause();
    }

    /**
     * @notice Unpauses the sale
     * @dev Triggers Pausable unpause; restricted to Legion
     */
    function unpauseSale() external onlyLegion {
        // Unpause the sale
        _unpause();
    }

    /**
     * @notice Returns the current sale configuration
     * @dev Provides read-only access to s_saleConfig
     * @return PreLiquidSaleConfig memory Struct containing sale configuration
     */
    function saleConfiguration() external view returns (PreLiquidSaleConfig memory) {
        /// Get the pre-liquid sale config
        return s_saleConfig;
    }

    /**
     * @notice Returns the current sale status
     * @dev Provides read-only access to s_saleStatus
     * @return PreLiquidSaleStatus memory Struct containing sale status
     */
    function saleStatusDetails() external view returns (PreLiquidSaleStatus memory) {
        /// Get the pre-liquid sale status
        return s_saleStatus;
    }

    /**
     * @notice Returns an investor's position details
     * @dev Provides read-only access to investor position
     * @param @investor Address of the investor
     * @return InvestorPosition memory Struct containing investor position details
     */
    function investorPositionDetails(address investor) external view returns (InvestorPosition memory) {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(investor);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        return s_investorPositions[positionId];
    }

    /**
     * @notice Returns an investor's vesting status
     * @dev Queries vesting contract if applicable
     * @param investor Address of the investor
     * @return vestingStatus LegionInvestorVestingStatus memory Struct containing vesting status details
     */
    function investorVestingStatus(address investor)
        external
        view
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
                ILegionVesting(investorVestingAddress).released(s_saleStatus.askToken),
                ILegionVesting(investorVestingAddress).releasable(s_saleStatus.askToken),
                ILegionVesting(investorVestingAddress).vestedAmount(s_saleStatus.askToken, uint64(block.timestamp))
            )
            : vestingStatus;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the sale parameters during initialization
     * @dev Private function to configure sale
     * @param preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function _setLegionSaleConfig(PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams)
        private
        onlyInitializing
    {
        /// Verify if the sale configuration is valid
        _verifyValidConfig(preLiquidSaleInitParams);

        /// Initialize pre-liquid sale configuration
        s_saleConfig.refundPeriodSeconds = preLiquidSaleInitParams.refundPeriodSeconds;
        s_saleConfig.legionFeeOnCapitalRaisedBps = preLiquidSaleInitParams.legionFeeOnCapitalRaisedBps;
        s_saleConfig.legionFeeOnTokensSoldBps = preLiquidSaleInitParams.legionFeeOnTokensSoldBps;
        s_saleConfig.referrerFeeOnCapitalRaisedBps = preLiquidSaleInitParams.referrerFeeOnCapitalRaisedBps;
        s_saleConfig.referrerFeeOnTokensSoldBps = preLiquidSaleInitParams.referrerFeeOnTokensSoldBps;
        s_saleConfig.bidToken = preLiquidSaleInitParams.bidToken;
        s_saleConfig.projectAdmin = preLiquidSaleInitParams.projectAdmin;
        s_saleConfig.addressRegistry = preLiquidSaleInitParams.addressRegistry;
        s_saleConfig.referrerFeeReceiver = preLiquidSaleInitParams.referrerFeeReceiver;

        /// Initialize pre-liquid sale solbound token configuration
        s_positionManagerconfig.name = preLiquidSaleInitParams.saleName;
        s_positionManagerconfig.symbol = preLiquidSaleInitParams.saleSymbol;
        s_positionManagerconfig.baseURI = preLiquidSaleInitParams.saleBaseURI;

        /// Cache Legion addresses from `LegionAddressRegistry`
        _syncLegionAddresses();
    }

    /**
     * @notice Syncs Legion addresses from the registry
     * @dev Updates configuration with latest addresses
     */
    function _syncLegionAddresses() private {
        // Cache Legion addresses from `LegionAddressRegistry`
        s_saleConfig.legionBouncer =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_BOUNCER_ID);
        s_saleConfig.legionSigner =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_SIGNER_ID);
        s_saleConfig.legionFeeReceiver =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_FEE_RECEIVER_ID);
        s_vestingConfig.vestingFactory =
            ILegionAddressRegistry(s_saleConfig.addressRegistry).getLegionAddress(Constants.LEGION_VESTING_FACTORY_ID);

        // Emit successfully LegionAddressesSynced
        emit LegionAddressesSynced(
            s_saleConfig.legionBouncer,
            s_saleConfig.legionSigner,
            s_saleConfig.legionFeeReceiver,
            s_vestingConfig.vestingFactory
        );
    }

    /**
     * @notice Updates an investor's position with SAFT data
     * @dev Caches investment and allocation details
     * @param investAmount Maximum capital allowed per SAFT
     * @param tokenAllocationRate Token allocation percentage (18 decimals)
     */
    function _updateInvestorPosition(uint256 investAmount, uint256 tokenAllocationRate) private {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Load the investor position
        InvestorPosition storage position = s_investorPositions[positionId];

        /// Cache the SAFT amount the investor is allowed to invest
        if (position.cachedInvestAmount != investAmount) {
            position.cachedInvestAmount = investAmount;
        }

        /// Cache the token allocation rate in 18 decimals precision
        if (position.cachedTokenAllocationRate != tokenAllocationRate) {
            position.cachedTokenAllocationRate = tokenAllocationRate;
        }
    }

    /**
     * @notice Validates an investor's vesting position
     * @dev Verifies vesting signature and configuration
     * @param vestingSignature Signature proving vesting terms
     * @param investorVestingConfig Vesting configuration to verify
     */
    function _verifyValidVestingPosition(
        bytes memory vestingSignature,
        LegionVestingManager.LegionInvestorVestingConfig calldata investorVestingConfig
    )
        private
        view
    {
        /// Construct the signed data
        bytes32 _data = keccak256(abi.encode(msg.sender, address(this), block.chainid, investorVestingConfig))
            .toEthSignedMessageHash();

        /// Verify the signature
        if (_data.recover(vestingSignature) != s_saleConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(vestingSignature);
        }
    }

    /**
     * @notice Validates the sale configuration parameters
     * @dev Checks for invalid values and addresses
     * @param _preLiquidSaleInitParams Calldata struct with initialization parameters
     */
    function _verifyValidConfig(PreLiquidSaleInitializationParams calldata _preLiquidSaleInitParams) private pure {
        /// Check for zero addresses provided
        if (
            _preLiquidSaleInitParams.bidToken == address(0) || _preLiquidSaleInitParams.projectAdmin == address(0)
                || _preLiquidSaleInitParams.addressRegistry == address(0)
        ) revert Errors.LegionSale__ZeroAddressProvided();

        /// Check for zero values provided
        if (_preLiquidSaleInitParams.refundPeriodSeconds == 0) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        /// Check if the refund period is within range
        if (_preLiquidSaleInitParams.refundPeriodSeconds > 2 weeks) revert Errors.LegionSale__InvalidPeriodConfig();

        /// Check if the soulbound token configuration is valid
        if (
            bytes(_preLiquidSaleInitParams.saleName).length == 0
                || bytes(_preLiquidSaleInitParams.saleSymbol).length == 0
                || bytes(_preLiquidSaleInitParams.saleBaseURI).length == 0
        ) {
            revert Errors.LegionSale__ZeroValueProvided();
        }
    }

    /**
     * @notice Verifies conditions for supplying tokens
     * @dev Ensures allocation and supply state are valid
     * @param _amount Amount of tokens to supply
     */
    function _verifyCanSupplyTokens(uint256 _amount) private view {
        /// Revert if Legion has not set the total amount of tokens allocated for distribution
        if (s_saleStatus.totalTokensAllocated == 0) revert Errors.LegionSale__TokensNotAllocated();

        /// Revert if tokens have already been supplied
        if (s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();

        /// Revert if the amount of tokens supplied is different than the amount set by Legion
        if (_amount != s_saleStatus.totalTokensAllocated) {
            revert Errors.LegionSale__InvalidTokenAmountSupplied(_amount, s_saleStatus.totalTokensAllocated);
        }
    }

    /**
     * @notice Ensures the sale is not canceled
     * @dev Reverts if sale is marked as canceled
     */
    function _verifySaleNotCanceled() private view {
        if (s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsCanceled();
    }

    /**
     * @notice Ensures the sale is canceled
     * @dev Reverts if sale is not marked as canceled
     */
    function _verifySaleIsCanceled() private view {
        if (!s_saleStatus.isCanceled) revert Errors.LegionSale__SaleIsNotCanceled();
    }

    /**
     * @notice Ensures the sale has not ended
     * @dev Reverts if sale is marked as ended
     */
    function _verifySaleHasNotEnded() private view {
        if (s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /**
     * @notice Ensures the sale has ended
     * @dev Reverts if sale is not marked as ended
     */
    function _verifySaleHasEnded() private view {
        if (!s_saleStatus.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /**
     * @notice Verifies conditions for claiming token allocation
     * @dev Checks supply and settlement status
     */
    function _verifyCanClaimTokenAllocation() private view {
        /// Get the investor position ID
        uint256 positionId = _getInvestorPositionId(msg.sender);

        /// Verify that the position exists
        _verifyPositionExists(positionId);

        /// Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

        /// Check if the askToken has been supplied to the sale
        if (!s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensNotSupplied();

        /// Check if the investor has already settled their allocation
        if (position.hasSettled) revert Errors.LegionSale__AlreadySettled(msg.sender);
    }

    /**
     * @notice Ensures no tokens have been supplied
     * @dev Reverts if tokens are already supplied
     */
    function _verifyTokensNotSupplied() private view {
        if (s_saleStatus.tokensSupplied) revert Errors.LegionSale__TokensAlreadySupplied();
    }

    /**
     * @notice Ensures a signature has not been used
     * @dev Prevents replay attacks by checking usage
     * @param signature Signature to verify
     */
    function _verifySignatureNotUsed(bytes memory signature) private view {
        /// Check if the signature is used
        if (s_usedSignatures[msg.sender][signature]) revert Errors.LegionSale__SignatureAlreadyUsed(signature);
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Ensures capital state allows withdrawal
     */
    function _verifyCanWithdrawCapital() private view {
        if (s_saleStatus.totalCapitalWithdrawn > 0) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (s_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalNotRaised();
    }

    /**
     * @notice Ensures the refund period is over
     * @dev Reverts if refund period is still active
     */
    function _verifyRefundPeriodIsOver() private view {
        if (s_saleStatus.refundEndTime > 0 && block.timestamp < s_saleStatus.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, s_saleStatus.refundEndTime);
        }
    }

    /**
     * @notice Ensures the refund period is not over
     * @dev Reverts if refund period has ended
     */
    function _verifyRefundPeriodIsNotOver() private view {
        if (s_saleStatus.refundEndTime > 0 && block.timestamp >= s_saleStatus.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, s_saleStatus.refundEndTime);
        }
    }

    /**
     * @notice Ensures the investor has not refunded
     * @param positionId ID of the investor's position
     * @dev Reverts if investor has already refunded
     */
    function _verifyHasNotRefunded(uint256 positionId) private view {
        if (s_investorPositions[positionId].hasRefunded) revert Errors.LegionSale__InvestorHasRefunded(msg.sender);
    }

    /**
     * @notice Verifies conditions for publishing capital raised
     * @dev Ensures capital raised is not already set
     */
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }

    /**
     * @notice Verifies the existence of an investor's position
     * @param positionId ID of the investor's position
     * @dev Reverts if position does not exist
     */
    function _verifyPositionExists(uint256 positionId) private pure {
        if (positionId == 0) revert Errors.LegionSale__InvestorPostionDoesNotExist();
    }

    /**
     * @notice Validates an investor's position
     * @dev Verifies investment amount and signature
     * @param signature Signature to verify
     * @param positionId ID of the investor's position
     * @param actionType Type of sale action being performed
     */
    function _verifyValidPosition(bytes memory signature, uint256 positionId, SaleAction actionType) private view {
        /// Load the investor position
        InvestorPosition memory position = s_investorPositions[positionId];

        /// Verify that the amount invested is equal to the SAFT amount
        if (position.investedCapital != position.cachedInvestAmount) {
            revert Errors.LegionSale__InvalidPositionAmount(msg.sender);
        }

        /// Construct the signed data
        bytes32 _data = keccak256(
            abi.encodePacked(
                msg.sender,
                address(this),
                block.chainid,
                uint256(position.cachedInvestAmount),
                uint256(position.cachedTokenAllocationRate),
                actionType
            )
        ).toEthSignedMessageHash();

        /// Verify the signature
        if (_data.recover(signature) != s_saleConfig.legionSigner) {
            revert Errors.LegionSale__InvalidSignature(signature);
        }
    }
}
