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
import { ILegionFixedPriceSale } from "./interfaces/ILegionFixedPriceSale.sol";
import { LegionSale } from "./LegionSale.sol";

/**
 * @title Legion Fixed Price Sale
 * @author Legion
 * @notice A contract used to execute fixed-price sales of ERC20 tokens after TGE
 */
contract LegionFixedPriceSale is LegionSale, ILegionFixedPriceSale {
    /// @dev A struct describing the fixed-price sale configuration
    FixedPriceSaleConfiguration private fixedPriceSaleConfig;

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams,
        LegionVestingInitializationParams calldata vestingInitParams
    )
        external
        initializer
    {
        // Verify if the sale initialization parameters are valid.
        _verifyValidParams(fixedPriceSaleInitParams);

        // Init and set the sale common params
        _setLegionSaleConfig(saleInitParams, vestingInitParams);

        // Set the fixed price sale specific configuration
        fixedPriceSaleConfig.tokenPrice = fixedPriceSaleInitParams.tokenPrice;

        // Calculate and set prefundStartTime, prefundEndTime, startTime, endTime and refundEndTime
        fixedPriceSaleConfig.prefundStartTime = block.timestamp;
        fixedPriceSaleConfig.prefundEndTime =
            fixedPriceSaleConfig.prefundStartTime + fixedPriceSaleInitParams.prefundPeriodSeconds;

        saleConfig.startTime =
            fixedPriceSaleConfig.prefundEndTime + fixedPriceSaleInitParams.prefundAllocationPeriodSeconds;
        saleConfig.endTime = saleConfig.startTime + saleInitParams.salePeriodSeconds;
        saleConfig.refundEndTime = saleConfig.endTime + saleInitParams.refundPeriodSeconds;

        // Check if lockupPeriodSeconds is less than refundPeriodSeconds
        // lockupEndTime should be at least refundEndTime
        if (saleInitParams.lockupPeriodSeconds <= saleInitParams.refundPeriodSeconds) {
            // If yes, set lockupEndTime to be refundEndTime
            saleConfig.lockupEndTime = saleConfig.refundEndTime;
        } else {
            // If no, calculate the lockupEndTime
            saleConfig.lockupEndTime = saleConfig.endTime + saleInitParams.lockupPeriodSeconds;
        }

        // Set the vestingStartTime to begin when lockupEndTime is reached
        vestingConfig.vestingStartTime = saleConfig.lockupEndTime;
    }

    /**
     * @notice Invest capital to the fixed price sale.
     *
     * @param amount The amount of capital invested.
     * @param signature The Legion signature for verification.
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

        // Increment total capital invested from investors
        saleStatus.totalCapitalInvested += amount;

        // Increment total invested capital for the investor
        investorPositions[msg.sender].investedCapital += amount;

        // Flag if capital is invested during the prefund period
        bool isPrefund = _isPrefund();

        // Emit successfully CapitalInvested
        emit CapitalInvested(amount, msg.sender, isPrefund, block.timestamp);

        // Transfer the invested capital to the contract
        SafeTransferLib.safeTransferFrom(addressConfig.bidToken, msg.sender, address(this), amount);
    }

    /**
     * @notice Publish sale results, once the sale has concluded.
     *
     * @dev Can be called only by the Legion admin address.
     *
     * @param claimMerkleRoot The merkle root to verify token claims.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param askTokenDecimals The decimals number of the ask token.
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
        saleStatus.claimTokensMerkleRoot = claimMerkleRoot;

        // Set the merkle root for accepted capital
        saleStatus.acceptedCapitalMerkleRoot = acceptedMerkleRoot;

        // Set the total tokens to be allocated by the Project team
        saleStatus.totalTokensAllocated = tokensAllocated;

        // Set the total capital raised to be withdrawn by the project
        saleStatus.totalCapitalRaised = (tokensAllocated * fixedPriceSaleConfig.tokenPrice) / (10 ** askTokenDecimals);

        // Emit successfully SaleResultsPublished
        emit SaleResultsPublished(claimMerkleRoot, acceptedMerkleRoot, tokensAllocated);
    }

    /**
     * @notice Returns the fixed price sale configuration.
     */
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory) {
        return fixedPriceSaleConfig;
    }

    /**
     * @notice Verify whether the prefund period is active (before sale startTime)
     */
    function _isPrefund() private view returns (bool) {
        return (block.timestamp < fixedPriceSaleConfig.prefundEndTime);
    }

    /**
     * @notice Verify whether the prefund allocation period is active (after prefundEndTime and before sale startTime)
     */
    function _verifyNotPrefundAllocationPeriod() private view {
        if (block.timestamp >= fixedPriceSaleConfig.prefundEndTime && block.timestamp < saleConfig.startTime) {
            revert Errors.PrefundAllocationPeriodNotEnded();
        }
    }

    /**
     * @notice Verify whether the sale initialization parameters are valid
     */
    function _verifyValidParams(FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams) private pure {
        // Check for zero values provided
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds == 0
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds == 0 || fixedPriceSaleInitParams.tokenPrice == 0
        ) {
            revert Errors.ZeroValueProvided();
        }

        // Check whether prefund and allocation periods are longer than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds > Constants.THREE_MONTHS
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds > Constants.TWO_WEEKS
        ) {
            revert Errors.InvalidPeriodConfig();
        }

        // Check whether prefund and allocation periods are shorter than allowed
        if (
            fixedPriceSaleInitParams.prefundPeriodSeconds < Constants.ONE_HOUR
                || fixedPriceSaleInitParams.prefundAllocationPeriodSeconds < Constants.ONE_HOUR
        ) {
            revert Errors.InvalidPeriodConfig();
        }
    }
}
