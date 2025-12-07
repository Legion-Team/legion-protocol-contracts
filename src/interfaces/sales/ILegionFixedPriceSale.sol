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

import { ILegionAbstractSale } from "./ILegionAbstractSale.sol";

/**
 * @title ILegionFixedPriceSale
 * @author Legion
 * @notice Interface for the LegionFixedPriceSale contract.
 */
interface ILegionFixedPriceSale is ILegionAbstractSale {
    /// @dev Struct defining the initialization parameters for a fixed-price sale
    struct FixedPriceSaleInitializationParams {
        // Duration of the prefund period in seconds
        uint64 prefundPeriodSeconds;
        // Duration of the prefund allocation period in seconds
        uint64 prefundAllocationPeriodSeconds;
    }

    /// @dev Struct containing the runtime configuration of the fixed-price sale
    struct FixedPriceSaleConfiguration {
        // Unix timestamp (in seconds) when the prefund period begins
        uint64 prefundStartTime;
        // Unix timestamp (in seconds) when the prefund period ends
        uint64 prefundEndTime;
    }

    /// @notice Emitted when capital is successfully invested in the sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param investor The address of the investor.
    /// @param isPrefund Indicates if investment occurred before sale start.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 positionId);

    /// @notice Emitted when the total capital raised is published by the Legion admin.
    /// @param capitalRaised The total capital raised by the project.
    event CapitalRaisedPublished(uint256 capitalRaised);

    /// @notice Initializes the contract with sale parameters.
    /// @param saleInitParams The common Legion sale initialization parameters.
    /// @param fixedPriceSaleInitParams The fixed-price sale specific initialization parameters.
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external;

    /// @notice Allows an investor to contribute capital to the fixed-price sale.
    /// @param amount The amount of capital to invest.
    /// @param deadline The deadline for the investment.
    /// @param signature The Legion signature for investor verification.
    function invest(uint256 amount, uint256 deadline, bytes calldata signature) external payable;

    /// @notice Publishes the total capital raised.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Returns the current fixed-price sale configuration.
    /// @return The complete fixed-price sale configuration struct.
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
}
