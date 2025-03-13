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

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";
import { ILegionPreLiquidSaleV2 } from "../interfaces/sales/ILegionPreLiquidSaleV2.sol";
import { ILegionSale } from "../interfaces/sales/ILegionSale.sol";
import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Pre-Liquid Sale V2
 * @author Legion
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE
 * @dev Inherits from LegionSale and implements ILegionPreLiquidSaleV2 for pre-liquid sale management
 */
contract LegionPreLiquidSaleV2 is LegionSale, ILegionPreLiquidSaleV2 {
    /// @notice Struct containing the pre-liquid sale configuration
    /// @dev Stores specific sale parameters like refund period and end status
    PreLiquidSaleConfiguration private preLiquidSaleConfig;

    /**
     * @notice Initializes the pre-liquid sale contract with parameters
     * @dev Sets up common and specific sale configurations; callable only once
     * @param saleInitParams Calldata struct with Legion sale initialization parameters
     */
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer {
        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams);

        // Set the sale start time
        saleConfig.startTime = block.timestamp;

        /// Set the refund period duration in seconds
        preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;
    }

    /**
     * @notice Allows an investor to contribute capital to the pre-liquid sale
     * @dev Verifies conditions and updates state; uses SafeTransferLib for token transfer
     * @param amount Amount of capital (in bid tokens) to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes memory signature) external whenNotPaused {
        // Verify that the investor is allowed to pledge capital
        _verifyLegionSignature(signature);

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the amount invested is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Verify that the investor has not claimed excess capital
        _verifyHasNotClaimedExcess();

        // Increment total capital invested from investors
        saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        investorPositions[msg.sender].investedCapital += amount;

        // Emit CapitalInvested
        emit CapitalInvested(amount, msg.sender, block.timestamp);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), amount);
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
        preLiquidSaleConfig.hasEnded = true;

        // Set the `endTime` of the sale
        saleConfig.endTime = block.timestamp;

        // Set the `refundEndTime` of the sale
        saleConfig.refundEndTime = block.timestamp + preLiquidSaleConfig.refundPeriodSeconds;

        // Emit SaleEnded successfully
        emit SaleEnded(block.timestamp);
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
        saleStatus.totalCapitalRaised = capitalRaised;

        // Set the merkle root for accepted capital
        saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

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

        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        saleStatus.totalTokensAllocated = tokensAllocated;

        /// Set the address of the token distributed to investors
        addressConfig.askToken = askToken;

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(claimMerkleRoot, tokensAllocated, askToken);
    }

    /**
     * @notice Withdraws raised capital to the Project
     * @dev Restricted to Project; transfers capital and fees post-sale
     */
    function withdrawRaisedCapital() external override(ILegionSale, LegionSale) onlyProject whenNotPaused {
        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Flag that the capital has been withdrawn
        saleStatus.capitalWithdrawn = true;

        // Set the total capital that has been withdrawn
        saleStatus.totalCapitalWithdrawn = saleStatus.totalCapitalRaised;

        // Cache value in memory
        uint256 _totalCapitalRaised = saleStatus.totalCapitalRaised;

        // Calculate Legion Fee
        uint256 _legionFee = (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / 10_000;

        // Calculate Referrer Fee
        uint256 _referrerFee = (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / 10_000;

        // Emit successfully CapitalWithdrawn
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
     * @notice Cancels the ongoing pre-liquid sale
     * @dev Restricted to Project; handles cancellation and capital return
     */
    function cancelSale() public override(ILegionSale, LegionSale) onlyProject whenNotPaused {
        // Verify sale has not already been canceled
        _verifySaleNotCanceled();

        /// Verify that no tokens have been supplied to the sale by the Project
        _verifyTokensNotSupplied();

        /// Cache the amount of funds to be returned to the sale
        uint256 capitalToReturn = saleStatus.totalCapitalWithdrawn;

        // Mark sale as canceled
        saleStatus.isCanceled = true;

        // Emit successfully SaleCanceled
        emit SaleCanceled();

        /// In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            /// Set the totalCapitalWithdrawn to zero
            saleStatus.totalCapitalWithdrawn = 0;
            /// Transfer the allocated amount of tokens for distribution
            SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /**
     * @notice Returns the current pre-liquid sale configuration
     * @dev Provides read-only access to preLiquidSaleConfig
     * @return PreLiquidSaleConfiguration memory Struct containing the sale configuration
     */
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return preLiquidSaleConfig;
    }

    /**
     * @notice Verifies that the sale has not ended
     * @dev Overrides parent to use preLiquidSaleConfig; reverts if ended
     */
    function _verifySaleHasNotEnded() internal view override {
        if (preLiquidSaleConfig.hasEnded) revert Errors.SaleHasEnded();
    }

    /**
     * @notice Verifies that the sale has ended
     * @dev Reverts if sale has not ended based on preLiquidSaleConfig
     */
    function _verifySaleHasEnded() internal view {
        if (!preLiquidSaleConfig.hasEnded) revert Errors.SaleHasNotEnded();
    }

    /**
     * @notice Verifies conditions for publishing capital raised
     * @dev Reverts if capital raised is already published
     */
    function _verifyCanPublishCapitalRaised() internal view {
        if (saleStatus.totalCapitalRaised != 0) revert Errors.CapitalRaisedAlreadyPublished();
    }

    /**
     * @notice Verifies conditions for withdrawing capital
     * @dev Overrides parent to check withdrawal status and capital raised
     */
    function _verifyCanWithdrawCapital() internal view override {
        if (saleStatus.capitalWithdrawn) revert Errors.CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.CapitalRaisedNotPublished();
    }

    /**
     * @notice Verifies that the refund period is over
     * @dev Overrides parent to check refundEndTime; reverts if not over
     */
    function _verifyRefundPeriodIsOver() internal view override {
        if (saleConfig.refundEndTime > 0 && block.timestamp < saleConfig.refundEndTime) {
            revert Errors.RefundPeriodIsNotOver();
        }
    }

    /**
     * @notice Verifies that the refund period is not over
     * @dev Overrides parent to check refundEndTime; reverts if over
     */
    function _verifyRefundPeriodIsNotOver() internal view override {
        if (saleConfig.refundEndTime > 0 && block.timestamp >= saleConfig.refundEndTime) {
            revert Errors.RefundPeriodIsOver();
        }
    }
}
