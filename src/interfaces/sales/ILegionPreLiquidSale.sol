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
 * @title ILegionPreLiquidSale
 * @author Legion
 * @notice Interface for the LegionPreLiquidSale contract.
 */
interface ILegionPreLiquidSale is ILegionAbstractSale {
    /// @dev Struct defining the configuration for the pre-liquid sale
    struct PreLiquidSaleConfiguration {
        // Duration of the refund period in seconds
        uint64 refundPeriodSeconds;
    }

    /// @notice Emitted when capital is successfully invested in the pre-liquid sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param investor The address of the investor.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, address investor, uint256 positionId);

    /// @notice Emitted when the total capital raised is published by the Legion admin.
    /// @param capitalRaised The total capital raised by the project.
    event CapitalRaisedPublished(uint256 capitalRaised);

    /// @notice Emitted when the sale is ended by Legion or project.
    event SaleEnded();

    /// @notice Initializes the pre-liquid sale contract with parameters.
    /// @param saleInitParams The Legion sale initialization parameters.
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external;

    /// @notice Allows an investor to invest capital in the pre-liquid sale.
    /// @param amount The amount of capital to invest.
    /// @param deadline The deadline for the investment.
    /// @param signature The Legion signature for investor verification.
    function invest(uint256 amount, uint256 deadline, bytes calldata signature) external payable;

    /// @notice Ends the sale and sets the refund period.
    function end() external;

    /// @notice Publishes the total capital raised.
    /// @param capitalRaised The total capital raised by the project.
    function publishRaisedCapital(uint256 capitalRaised) external;

    /// @notice Returns the current pre-liquid sale configuration.
    /// @return The complete pre-liquid sale configuration struct.
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
}
