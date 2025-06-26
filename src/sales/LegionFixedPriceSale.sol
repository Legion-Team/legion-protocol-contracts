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

import { Errors } from "../utils/Errors.sol";

import { ILegionFixedPriceSale } from "../interfaces/sales/ILegionFixedPriceSale.sol";

import { LegionAbstractSale } from "./LegionAbstractSale.sol";

/**
 * @title Legion Fixed Price Sale
 * @author Legion
 * @notice Executes fixed-price sales of ERC20 tokens after Token Generation Event (TGE).
 * @dev Inherits from LegionAbstractSale and implements ILegionFixedPriceSale for fixed-price token sales with prefund
 * periods.
 */
contract LegionFixedPriceSale is LegionAbstractSale, ILegionFixedPriceSale {
    /// @dev Struct containing the fixed-price sale configuration
    FixedPriceSaleConfiguration private s_fixedPriceSaleConfig;

    /// @inheritdoc ILegionFixedPriceSale
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid
        _verifyValidParams(fixedPriceSaleInitParams);

        // Initialize and set the sale common parameters
        _setLegionSaleConfig(saleInitParams);

        // Set the fixed price sale specific configuration
        s_fixedPriceSaleConfig.tokenPrice = fixedPriceSaleInitParams.tokenPrice;

        // Calculate and set prefundStartTime and prefundEndTime
        s_fixedPriceSaleConfig.prefundStartTime = uint64(block.timestamp);
        s_fixedPriceSaleConfig.prefundEndTime =
            s_fixedPriceSaleConfig.prefundStartTime + fixedPriceSaleInitParams.prefundPeriodSeconds;

        // Calculate and set startTime, endTime and refundEndTime
        s_saleConfig.startTime =
            s_fixedPriceSaleConfig.prefundEndTime + fixedPriceSaleInitParams.prefundAllocationPeriodSeconds;
        s_saleConfig.endTime = s_saleConfig.startTime + saleInitParams.salePeriodSeconds;
        s_saleConfig.refundEndTime = s_saleConfig.endTime + saleInitParams.refundPeriodSeconds;
    }

    /// @inheritdoc ILegionFixedPriceSale
    function invest(uint256 amount, bytes calldata signature) external whenNotPaused {
        // Check if the investor has already invested
        // If not, create a new investor position
        uint256 positionId = _getInvestorPositionId(msg.sender) == 0
            ? _createInvestorPosition(msg.sender)
            : s_investorPositionIds[msg.sender];

        // Verify that the investor is allowed to invest capital
        _verifyInvestSignature(signature);

        // Verify that investment is not during the prefund allocation period
        _verifyNotPrefundAllocationPeriod();

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

        // Increment total capital invested from investors
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        s_investorPositions[positionId].investedCapital += amount;

        // Flag if capital is invested during the prefund period
        bool isPrefund = _isPrefund();

        // Emit CapitalInvested event
        emit CapitalInvested(amount, msg.sender, isPrefund, positionId);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /// @inheritdoc ILegionFixedPriceSale
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint8 askTokenDecimals
    )
        external
        onlyLegion
    {
        // Verify that the sale is not canceled
        _verifySaleNotCanceled();

        // Verify that the refund period is over
        _verifyRefundPeriodIsOver();

        // Verify that sale results are not already published
        _verifyCanPublishSaleResults();

        // Set the merkle root for claiming tokens
        s_saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the merkle root for accepted capital
        s_saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        s_saleStatus.totalTokensAllocated = tokensAllocated;

        // Set the total capital raised to be withdrawn by the project
        s_saleStatus.totalCapitalRaised =
            (tokensAllocated * s_fixedPriceSaleConfig.tokenPrice) / (10 ** askTokenDecimals);

        // Emit SaleResultsPublished event
        emit SaleResultsPublished(claimMerkleRoot, acceptedMerkleRoot, tokensAllocated);
    }

    /// @inheritdoc ILegionFixedPriceSale
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory) {
        return s_fixedPriceSaleConfig;
    }

    /// @dev Validates the fixed-price sale initialization parameters.
    /// @param fixedPriceSaleInitParams The fixed-price sale initialization parameters to validate.
    function _verifyValidParams(FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams) private pure {
        // Check for zero values provided
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds == 0
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds == 0 || fixedPriceSaleInitParams.tokenPrice == 0
        ) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check if prefund and allocation periods are longer than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds > 12 weeks
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds > 2 weeks
        ) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }

        // Check if prefund and allocation periods are shorter than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds < 1 hours
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds < 1 hours
        ) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }
    }

    /// @dev Checks if the current time is within the prefund period.
    /// @return True if within prefund period, false otherwise.
    function _isPrefund() private view returns (bool) {
        return (block.timestamp < s_fixedPriceSaleConfig.prefundEndTime);
    }

    /// @dev Verifies that the current time is not within the prefund allocation period.
    function _verifyNotPrefundAllocationPeriod() private view {
        if (block.timestamp >= s_fixedPriceSaleConfig.prefundEndTime && block.timestamp < s_saleConfig.startTime) {
            revert Errors.LegionSale__PrefundAllocationPeriodNotEnded(block.timestamp);
        }
    }
}
