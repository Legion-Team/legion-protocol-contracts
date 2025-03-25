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

import { Errors } from "../utils/Errors.sol";

import { ILegionFixedPriceSale } from "../interfaces/sales/ILegionFixedPriceSale.sol";

import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Fixed Price Sale
 * @author Legion
 * @notice A contract used to execute fixed-price sales of ERC20 tokens after TGE
 * @dev Inherits from LegionSale and implements ILegionFixedPriceSale for fixed-price token sales
 */
contract LegionFixedPriceSale is LegionSale, ILegionFixedPriceSale {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the fixed-price sale configuration
    /// @dev Stores sale-specific parameters like token price and timing details
    FixedPriceSaleConfiguration private s_fixedPriceSaleConfig;

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with sale parameters
     * @dev Sets up both common sale and fixed-price specific configurations; callable only once
     * @param saleInitParams Calldata struct with common Legion sale initialization parameters
     * @param fixedPriceSaleInitParams Calldata struct with fixed-price sale specific initialization parameters
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid.
        _verifyValidParams(fixedPriceSaleInitParams);

        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams);

        // Set the fixed price sale specific configuration
        s_fixedPriceSaleConfig.tokenPrice = fixedPriceSaleInitParams.tokenPrice;

        // Calculate and set prefundStartTime and prefundEndTime
        s_fixedPriceSaleConfig.prefundStartTime = block.timestamp;
        s_fixedPriceSaleConfig.prefundEndTime =
            s_fixedPriceSaleConfig.prefundStartTime + fixedPriceSaleInitParams.prefundPeriodSeconds;

        // Calculate and set startTime, endTime and refundEndTime
        s_saleConfig.startTime =
            s_fixedPriceSaleConfig.prefundEndTime + fixedPriceSaleInitParams.prefundAllocationPeriodSeconds;
        s_saleConfig.endTime = s_saleConfig.startTime + saleInitParams.salePeriodSeconds;
        s_saleConfig.refundEndTime = s_saleConfig.endTime + saleInitParams.refundPeriodSeconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows an investor to contribute capital to the fixed-price sale
     * @dev Verifies multiple conditions before accepting investment; uses SafeTransferLib for token transfer
     * @param amount Amount of capital (in bid tokens) to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes memory signature) external whenNotPaused {
        // Verify that the investor is allowed to invest capital
        _verifyLegionSignature(signature);

        // Verify that invest is not during the prefund allocation period
        _verifyNotPrefundAllocationPeriod();

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
        s_saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        s_investorPositions[msg.sender].investedCapital += amount;

        // Flag if capital is invested during the prefund period
        bool isPrefund = _isPrefund();

        // Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, isPrefund, block.timestamp);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(s_addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Publishes the sale results after completion
     * @dev Sets merkle roots and token allocation; restricted to Legion admin
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total tokens allocated for distribution
     * @param askTokenDecimals Decimals of the ask token for raised capital calculation
     */
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

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(claimMerkleRoot, acceptedMerkleRoot, tokensAllocated);
    }

    /**
     * @notice Returns the current fixed-price sale configuration
     * @dev Provides read-only access to the fixedPriceSaleConfig struct
     * @return FixedPriceSaleConfiguration memory Struct containing the sale configuration
     */
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory) {
        return s_fixedPriceSaleConfig;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates the fixed-price sale initialization parameters
     * @dev Checks for zero values and ensures periods are within allowed ranges
     * @param fixedPriceSaleInitParams Calldata struct with fixed-price sale initialization parameters
     */
    function _verifyValidParams(FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams) private pure {
        // Check for zero values provided
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds == 0
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds == 0 || fixedPriceSaleInitParams.tokenPrice == 0
        ) {
            revert Errors.LegionSale__ZeroValueProvided();
        }

        // Check whether prefund and allocation periods are longer than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds > 12 weeks
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds > 2 weeks
        ) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }

        // Check whether prefund and allocation periods are shorter than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds < 1 hours
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds < 1 hours
        ) {
            revert Errors.LegionSale__InvalidPeriodConfig();
        }
    }

    /**
     * @notice Checks if the current time is within the prefund period
     * @dev Compares block timestamp with prefund end time
     * @return bool True if within prefund period, false otherwise
     */
    function _isPrefund() private view returns (bool) {
        return (block.timestamp < s_fixedPriceSaleConfig.prefundEndTime);
    }

    /**
     * @notice Verifies that the current time is not within the prefund allocation period
     * @dev Reverts if called between prefundEndTime and sale startTime
     */
    function _verifyNotPrefundAllocationPeriod() private view {
        if (block.timestamp >= s_fixedPriceSaleConfig.prefundEndTime && block.timestamp < s_saleConfig.startTime) {
            revert Errors.LegionSale__PrefundAllocationPeriodNotEnded(block.timestamp);
        }
    }
}
