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

import { ILegionPreLiquidSale } from "../interfaces/sales/ILegionPreLiquidSale.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale
 * @author Legion
 * @notice Executes pre-liquid sales of ERC20 tokens before Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionPreLiquidSale for open application
 * pre-liquid sale management.
 */
contract LegionPreLiquidSale is LegionAbstractSale, ILegionPreLiquidSale {
    /// @dev Struct containing the pre-liquid sale configuration
    PreLiquidSaleConfiguration private s_preLiquidSaleConfig;

    /// @notice Restricts interaction to when the sale has ended.
    /// @dev Reverts if the sale has not ended.
    modifier whenSaleEnded() {
        // Verify that the sale has ended
        _verifySaleHasEnded();
        _;
    }

    /// @inheritdoc ILegionPreLiquidSale
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external initializer {
        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Set the sale start time
        s_saleConfig.startTime = uint64(block.timestamp);

        // Set the refund period duration in seconds
        s_preLiquidSaleConfig.refundPeriodSeconds = saleInitParams.refundPeriodSeconds;
    }

    /// @inheritdoc ILegionPreLiquidSale
    function invest(
        uint256 amount,
        uint256 deadline,
        bytes calldata signature
    )
        external
        payable
        whenNotPaused
        whenSaleNotEnded
        whenSaleNotCanceled
    {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the amount invested is more than the minimum required
        _verifyMinimumInvestAmount(amount);

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature, amount, deadline);

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

        // Collect Legion's operations fee
        _handleOpsFee();

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionPreLiquidSale
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

    /// @inheritdoc ILegionPreLiquidSale
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

    /// @inheritdoc ILegionPreLiquidSale
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory) {
        return s_preLiquidSaleConfig;
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
