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
        // Price of the token being sold in terms of the bid token
        uint256 tokenPrice;
    }

    /// @dev Struct containing the runtime configuration of the fixed-price sale
    struct FixedPriceSaleConfiguration {
        // Unix timestamp (in seconds) when the prefund period begins
        uint64 prefundStartTime;
        // Unix timestamp (in seconds) when the prefund period ends
        uint64 prefundEndTime;
        // Price of the token being sold in terms of the bid token
        uint256 tokenPrice;
    }

    /// @notice Emitted when capital is successfully invested in the sale.
    /// @param amount The amount of capital invested (in bid tokens).
    /// @param investor The address of the investor.
    /// @param isPrefund Indicates if investment occurred before sale start.
    /// @param positionId The unique identifier for the investment position.
    event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 positionId);

    /// @notice Emitted when sale results are published by the Legion admin.
    /// @param claimMerkleRoot The Merkle root for verifying token claims.
    /// @param acceptedMerkleRoot The Merkle root for verifying accepted capital.
    /// @param tokensAllocated The total amount of tokens allocated from the sale.
    event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);

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
    /// @param signature The Legion signature for investor verification.
    function invest(uint256 amount, bytes calldata signature) external;

    /// @notice Publishes the sale results after completion.
    /// @param claimMerkleRoot The Merkle root for verifying token claims.
    /// @param acceptedMerkleRoot The Merkle root for verifying accepted capital.
    /// @param tokensAllocated The total tokens allocated for distribution.
    /// @param askTokenDecimals The decimals of the ask token for raised capital calculation.
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint8 askTokenDecimals
    )
        external;

    /// @notice Returns the current fixed-price sale configuration.
    /// @return The complete fixed-price sale configuration struct.
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
}
