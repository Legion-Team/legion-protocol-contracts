// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

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
 * @notice Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionPreLiquidOpenApplicationSale for open application
 * pre-liquid sale management.
 */
contract LegionPreLiquidOpenApplicationSale is LegionAbstractSale, ILegionPreLiquidOpenApplicationSale {
    /// @dev Struct containing the pre-liquid sale configuration
    PreLiquidSaleConfiguration private s_preLiquidSaleConfig;

    /// @notice Restricts interaction to when the sale has ended.
    /// @dev Reverts if the sale has not ended.
    modifier whenSaleEnded() {
        // Verify that the sale has ended
        _verifySaleHasEnded();
        _;
    }

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer {
        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Set the sale start time
        s_saleConfig.startTime = uint64(block.timestamp);

        // Set the refund period duration in seconds
        s_preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;
    }

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function invest(
        uint256 amount,
        bytes calldata signature
    )
        external
        whenNotPaused
        whenSaleNotEnded
        whenSaleNotCanceled
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature);

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

        // Emit CapitalInvested event
        emit CapitalInvested(amount, msg.sender, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function end() external onlyLegionOrProject whenNotPaused whenSaleNotCanceled whenSaleNotEnded {
        // Update the `hasEnded` status to true
        s_preLiquidSaleConfig.hasEnded = true;

        // Set the `endTime` of the sale
        s_saleConfig.endTime = uint64(block.timestamp);

        // Set the `refundEndTime` of the sale
        s_saleConfig.refundEndTime = uint64(block.timestamp) + s_preLiquidSaleConfig.refundPeriodSeconds;

        // Emit SaleEnded event
        emit SaleEnded();
    }

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function publishRaisedCapital(uint256 capitalRaised)
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
    {
        // Verify that capital raised can be published.
        _verifyCanPublishCapitalRaised();

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised = capitalRaised;

        // Emit CapitalRaisedPublished event
        emit CapitalRaisedPublished(capitalRaised);
    }

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        uint256 tokensAllocated,
        address askToken
    )
        external
        onlyLegion
        whenNotPaused
        whenSaleNotCanceled
        whenSaleEnded
        whenRefundPeriodIsOver
    {
        // Verify that sale results are not published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        s_saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        s_saleStatus.totalTokensAllocated = tokensAllocated;

        /// Set the address of the token distributed to investors
        s_addressConfig.askToken = askToken;

        // Emit SaleResultsPublished event
        emit SaleResultsPublished(claimMerkleRoot, tokensAllocated, askToken);
    }

    /// @inheritdoc ILegionAbstractSale
    function withdrawRaisedCapital()
        external
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
        whenSaleEnded
        whenRefundPeriodIsOver
        whenSaleNotCanceled
    {
        // Verify that the project can withdraw capital
        _verifyCanWithdrawCapital();

        // Flag that the capital has been withdrawn
        s_saleStatus.capitalWithdrawn = true;

        // Cache value in memory
        uint256 _totalCapitalRaised = s_saleStatus.totalCapitalRaised;

        // Set the total capital that has been withdrawn
        s_saleStatus.totalCapitalWithdrawn = _totalCapitalRaised;

        // Cache Legion Sale Address Configuration
        LegionSaleAddressConfiguration memory addressConfig = s_addressConfig;

        // Cache Legion Sale Configuration
        LegionSaleConfiguration memory saleConfig = s_saleConfig;

        // Calculate Legion Fee
        uint256 _legionFee =
            (saleConfig.legionFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Calculate Referrer Fee
        uint256 _referrerFee =
            (saleConfig.referrerFeeOnCapitalRaisedBps * _totalCapitalRaised) / Constants.BASIS_POINTS_DENOMINATOR;

        // Emit CapitalWithdrawn event
        emit CapitalWithdrawn(_totalCapitalRaised);

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

    /// @inheritdoc ILegionPreLiquidOpenApplicationSale
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return s_preLiquidSaleConfig;
    }

    /// @inheritdoc ILegionAbstractSale
    function cancel()
        public
        override(ILegionAbstractSale, LegionAbstractSale)
        onlyProject
        whenNotPaused
        whenSaleNotCanceled
        whenTokensNotSupplied
    {
        // Cache the amount of funds to be returned to the capital raise
        // The project should return the total capital raised including the charged fees
        uint256 capitalToReturn = s_saleStatus.totalCapitalWithdrawn;

        // Mark sale as canceled
        s_saleStatus.isCanceled = true;

        // Emit SaleCanceled event
        emit SaleCanceled();

        // In case there's capital to return, transfer the funds back to the contract
        if (capitalToReturn > 0) {
            // Set the totalCapitalWithdrawn to zero
            s_saleStatus.totalCapitalWithdrawn = 0;
            // Transfer the capital back to the contract
            SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), capitalToReturn);
        }
    }

    /// @dev Verifies that the sale has not ended.
    function _verifySaleHasNotEnded() internal view override {
        if (s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasEnded(block.timestamp);
    }

    /// @dev Verifies that the refund period has ended.
    function _verifyRefundPeriodIsOver() internal view override {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp < refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsNotOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies that the refund period is still active.
    function _verifyRefundPeriodIsNotOver() internal view override {
        // Cache the refund end time from the sale configuration
        uint256 refundEndTime = s_saleConfig.refundEndTime;

        if (refundEndTime > 0 && block.timestamp >= refundEndTime) {
            revert Errors.LegionSale__RefundPeriodIsOver(block.timestamp, refundEndTime);
        }
    }

    /// @dev Verifies conditions for withdrawing capital.
    function _verifyCanWithdrawCapital() internal view override {
        // Load the sale status
        LegionSaleStatus memory saleStatus = s_saleStatus;

        if (saleStatus.capitalWithdrawn) revert Errors.LegionSale__CapitalAlreadyWithdrawn();
        if (saleStatus.totalCapitalRaised == 0) revert Errors.LegionSale__CapitalRaisedNotPublished();
    }

    /// @dev Verifies that the sale has ended.
    function _verifySaleHasEnded() private view {
        if (!s_preLiquidSaleConfig.hasEnded) revert Errors.LegionSale__SaleHasNotEnded(block.timestamp);
    }

    /// @dev Verifies conditions for publishing capital raised.
    function _verifyCanPublishCapitalRaised() private view {
        if (s_saleStatus.totalCapitalRaised != 0) revert Errors.LegionSale__CapitalRaisedAlreadyPublished();
    }
}
