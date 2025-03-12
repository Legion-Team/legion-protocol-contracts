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
 */
contract LegionPreLiquidSaleV2 is LegionSale, ILegionPreLiquidSaleV2 {
    /// @dev A struct describing the pre-liquid sale configuration
    PreLiquidSaleConfiguration private preLiquidSaleConfig;

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param saleInitParams The Legion sale initialization parameters.
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
     * @notice Invest capital to the pre-liquid sale.
     *
     * @param amount The amount of capital invested.
     * @param signature The Legion signature for verification.
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
     * @notice End sale by Legion or the Project and set the refund end time.
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
     * @notice Publish the total capital raised by the project.
     *
     * @param capitalRaised The total capital raised by the project.
     * @param acceptedMerkleRoot The Merkle root to verify accepted capital.
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
     * @notice Publish sale results, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param claimMerkleRoot The Merkle root to verify token claims.
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param askToken The address of the token distributed to investors.
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
     * @notice Withdraw raised capital from the sale contract.
     *
     * @dev Can be called only by the Project admin address.
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

        // Transfer the Referrer fee to the Legion fee receiver address
        if (_referrerFee != 0) {
            SafeTransferLib.safeTransfer(addressConfig.bidToken, addressConfig.referrerFeeReceiver, _referrerFee);
        }
    }

    /**
     * @notice Cancels an ongoing sale.
     *
     * @dev Can be called only by the Project admin address.
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
     * @notice Returns the pre-liquid sale configuration.
     */
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return preLiquidSaleConfig;
    }

    /**
     * @notice Verify that the sale has not ended.
     */
    function _verifySaleHasNotEnded() internal view override {
        if (preLiquidSaleConfig.hasEnded) revert Errors.SaleHasEnded();
    }

    /**
     * @notice Verify that the sale has ended.
     */
    function _verifySaleHasEnded() internal view {
        if (!preLiquidSaleConfig.hasEnded) revert Errors.SaleHasNotEnded();
    }

    /**
     * @notice Verify that capital raised can be published.
     */
    function _verifyCanPublishCapitalRaised() internal view {
        if (saleStatus.totalCapitalRaised != 0) revert Errors.CapitalRaisedAlreadyPublished();
    }

    /**
     * @notice Verify that the project can withdraw capital.
     */
    function _verifyCanWithdrawCapital() internal view override {
        if (saleStatus.capitalWithdrawn) revert Errors.CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.CapitalRaisedNotPublished();
    }

    /**
     * @notice Verify that the refund period is over.
     */
    function _verifyRefundPeriodIsOver() internal view override {
        if (saleConfig.refundEndTime > 0 && block.timestamp < saleConfig.refundEndTime) {
            revert Errors.RefundPeriodIsNotOver();
        }
    }

    /**
     * @notice Verify that the refund period is not over.
     */
    function _verifyRefundPeriodIsNotOver() internal view override {
        if (saleConfig.refundEndTime > 0 && block.timestamp >= saleConfig.refundEndTime) {
            revert Errors.RefundPeriodIsOver();
        }
    }
}
