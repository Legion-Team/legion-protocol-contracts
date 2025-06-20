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

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionPreLiquidOpenApplicationSale } from "../interfaces/sales/ILegionPreLiquidOpenApplicationSale.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale
 * @author Legion
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE
 * @dev Inherits from LegionAbstractSale and implements ILegionPreLiquidOpenApplicationSale for pre-liquid sale
 * management
 */
contract LegionPreLiquidOpenApplicationSale is LegionAbstractSale, ILegionPreLiquidOpenApplicationSale {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the pre-liquid sale configuration
    /// @dev Stores specific sale parameters like refund period and end status
    PreLiquidSaleConfiguration private s_preLiquidSaleConfig;

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the pre-liquid sale contract with parameters
     * @dev Sets up common and specific sale configurations; callable only once
     * @param saleInitParams Calldata struct with Legion sale initialization parameters
     */
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer {
        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams);

        // Set the sale start time
        s_saleConfig.startTime = block.timestamp;

        /// Set the refund period duration in seconds
        s_preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to invest capital to the pre-liquid sale
     * @dev Verifies conditions and updates state
     * @param amount Amount of capital to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes memory signature) external whenNotPaused {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature);

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the amount invested is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded(positionId);

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess(positionId);

        // Increment total capital invested from all investors
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        s_investorPositions[positionId].investedCapital += amount;

        // Emit CapitalInvested
        emit CapitalInvested(amount, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Ends the sale and sets refund period
     * @dev Restricted to Legion or Project; updates sale status and times
     */
    function endSale() external onlyLegionOrProject whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Update the `hasEnded` status to true
        s_preLiquidSaleConfig.hasEnded = true;

        // Set the `endTime` of the sale
        s_saleConfig.endTime = block.timestamp;

        // Set the `refundEndTime` of the sale
        s_saleConfig.refundEndTime = block.timestamp + s_preLiquidSaleConfig.refundPeriodSeconds;

        // Emit SaleEnded successfully
        emit SaleEnded();
    }

    /**
     * @notice Publishes the total capital raised and accepted capital Merkle root
     * @dev Restricted to Legion; sets capital raised after sale conclusion
     * @param capitalRaised Total capital raised by the project
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     */
    function publishCapitalRaised(
        uint256 capitalRaised,
        bytes32 acceptedMerkleRoot
    )
        external
        onlyLegion
        whenNotPaused
    {
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

        // Set the merkle root for accepted capital
        s_saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Emit successfully CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised, acceptedMerkleRoot);
    }

    /**
     * @notice Publishes sale results including token allocation details
     * @dev Restricted to Legion; sets token distribution data post-sale
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param tokensAllocated Total tokens allocated for investors
     * @param askToken Address of the token to be distributed
     */
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        uint256 tokensAllocated,
        address askToken
    )
        external
        onlyLegion
        whenNotPaused
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that sale results are not published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        s_saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        s_saleStatus.totalTokensAllocated = tokensAllocated;

        /// Set the address of the token distributed to investors
        s_addressConfig.askToken = askToken;

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(claimMerkleRoot, tokensAllocated, askToken);
    }

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Restricted to Project; transfers capital and fees post-sale
     */
    function withdrawRaisedCapital()
        external
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
    {
        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Flag that the capital has been withdrawn
        s_saleStatus.capitalWithdrawn = true;

        // Set the total capital that has been withdrawn
        s_saleStatus.totalCapitalWithdrawn = s_saleStatus.totalCapitalRaised;

        // Cache value in memory
        uint256 _totalCapitalRaised = s_saleStatus.totalCapitalRaised;

        // Calculate Legion Fee
        uint256 _legionFee =
            (s_saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 _referrerFee =
            (s_saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit successfully CapitalWithdrawn
        emit CapitalWithdrawn(_totalCapitalRaised);

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
     * @notice Returns the current pre-liquid sale configuration
     * @dev Provides read-only access to s_preLiquidSaleConfig
     * @return PreLiquidSaleConfiguration memory Struct containing the sale configuration
     */
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return s_preLiquidSaleConfig;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Cancels the ongoing pre-liquid sale
     * @dev Restricted to Project; handles cancellation and capital return
     */
    function cancelSale() public override(ILegionAbstractSale, LegionAbstractSale) onlyProject whenNotPaused {
        // Verify sale has not already been canceled
        _verifySaleNotCanceled();

        /// Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();

        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_saleStatus.totalCapitalWithdrawn;

        // Mark sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit successfully SaleCanceled
        emit SaleCanceled();

        /// In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            /// Set the totalCapitalWithdrawn to zero
            s_saleStatus.totalCapitalWithdrawn = 0;
            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that the sale has not ended
     * @dev Overrides parent to use s_preLiquidSaleConfig; reverts if ended
     */
    function _verifySaleHasNotEnded() internal view override {
        if (s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /**
     * @notice Verifies that the refund period is over
     * @dev Overrides parent to check refundEndTime; reverts if not over
     */
    function _verifyRefundPeriodIsOver() internal view override {
        if (s_saleConfig.refundEndTime > 0 && block.timestamp < s_saleConfig.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, s_saleConfig.refundEndTime);
        }
    }

    /**
     * @notice Verifies that the refund period is not over
     * @dev Overrides parent to check refundEndTime; reverts if over
     */
    function _verifyRefundPeriodIsNotOver() internal view override {
        if (s_saleConfig.refundEndTime > 0 && block.timestamp >= s_saleConfig.refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, s_saleConfig.refundEndTime);
        }
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Overrides parent to check withdrawal status and capital raised
     */
    function _verifyCanWithdrawCapital() internal view override {
        if (s_saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (s_saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalRaisedNotPublished();
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Verifies that the sale has ended
     * @dev Reverts if sale has not ended based on s_preLiquidSaleConfig
     */
    function _verifySaleHasEnded() private view {
        if (!s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /**
     * @notice Verifies conditions for publishing capital raised
     * @dev Reverts if capital raised is already published
     */
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }
}
