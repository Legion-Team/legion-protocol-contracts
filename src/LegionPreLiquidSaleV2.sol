// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

import { Constants } from "./utils/Constants.sol";
import { Errors } from "./utils/Errors.sol";
import { ILegionPreLiquidSaleV2 } from "./interfaces/ILegionPreLiquidSaleV2.sol";
import { ILegionSale } from "./interfaces/ILegionSale.sol";
import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Pre-Liquid Sale.
 * @author Legion.
 * @notice A contract used to execute pre-liquid sales of ERC20 tokens before TGE.
 */
contract LegionPreLiquidSaleV2 is LegionSale, ILegionPreLiquidSaleV2 {
    /// @dev A struct describing the fixed price sale configuration.
    PreLiquidSaleConfiguration private preLiquidSaleConfig;

    /**
     * @notice See {ILegionPreLiquidSaleV2-initialize}.
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        LegionVestingInitializationParams calldata vestingInitParams
    )
        external
        initializer
    {
        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams, vestingInitParams);

        // Set the sale start time
        saleConfig.startTime = block.timestamp;

        /// Set the refund period duration is seconds
        preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;

        /// Set the lockup period duration is seconds
        preLiquidSaleConfig.lockupPeriodSeconds = saleInitParams.lockupPeriodSeconds;
    }

    /**
     * @notice See {ILegionPreLiquidSaleV2-invest}.
     */
    function invest(uint256 amount, bytes memory signature) external whenNotPaused {
        // Verify that the investor is allowed to pledge capital
        _verifyLegionSignature(signature);

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the amount pledged is more than the minimum required
        _verifyMinimumPledgeAmount(amount);

        // Verify that the investor has not refunded
        _verifyHasNotRefunded();

        // Increment total capital pledged from investors
        saleStatus.totalCapitalInvested += amount;

        // Increment total pledged capital for the investor
        investorPositions[msg.sender].investedCapital += amount;

        // Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, block.timestamp);

        // Transfer the pledged capital to the contract
        SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice See {ILegionPreLiquidSaleV2-closeSaleApplications}.
     */
    function endSale() external onlyLegionOrProject whenNotPaused {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the sale has not ended
        _verifySaleHasNotEnded();

        // Update the `hasEnded` status to false
        preLiquidSaleConfig.hasEnded = true;

        // Set the `endTime` of the sale
        saleConfig.endTime = block.timestamp;

        // Set the `refundEndTime` of the sale
        saleConfig.refundEndTime = block.timestamp + preLiquidSaleConfig.refundPeriodSeconds;

        // Check if lockupPeriodSeconds is less than refundPeriodSeconds
        // lockupEndTime should be at least refundEndTime
        if (preLiquidSaleConfig.lockupPeriodSeconds <= preLiquidSaleConfig.refundPeriodSeconds) {
            // If yes, set lockupEndTime to be refundEndTime
            saleConfig.lockupEndTime = saleConfig.refundEndTime;
        } else {
            // If no, calculate the lockupEndTime
            saleConfig.lockupEndTime = saleConfig.endTime + preLiquidSaleConfig.lockupPeriodSeconds;
        }

        // Emit successfully SaleEnded
        emit SaleEnded(block.timestamp);
    }

    function publishCapitalRaised(uint256 capitalRaised, bytes32 acceptedMerkleRoot) external onlyLegion {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // verify that the sale has ended
        _verifySaleHasEnded();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that capital raised can be published
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        saleStatus.totalCapitalRaised = capitalRaised;

        // Set the merkle root for accepted capital
        saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Emit successfully CapitalRaisedPublished
        emit CapitalRaisedPublished(capitalRaised, acceptedMerkleRoot);
    }

    /**
     * @notice See {ILegionPreLiquidSaleV2-publishSaleResults}.
     */
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        uint256 tokensAllocated,
        address askToken,
        uint256 vestingStartTime
    )
        external
        onlyLegion
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

        /// Set the address of the token ditributed to investors
        addressConfig.askToken = askToken;

        // Set the vesting start time block timestamp
        vestingConfig.vestingStartTime = vestingStartTime;

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(claimMerkleRoot, tokensAllocated, askToken, vestingStartTime);
    }

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
     * @notice See {ILegionPreLiquidSaleV2-preLiquidSaleConfiguration}.
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
     * @notice Verify that capital raised can be published
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
