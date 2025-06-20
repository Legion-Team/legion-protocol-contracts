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

import { ILegionAbstractSale } from "./ILegionAbstractSale.sol";

/**
 * @title ILegionFixedPriceSale
 * @author Legion
 * @notice Interface for managing fixed-price sales of ERC20 tokens in the Legion Protocol
 * @dev Extends ILegionAbstractSale with fixed-price sale specific functionality and events
 */
interface ILegionFixedPriceSale is ILegionAbstractSale {
    /// @notice Struct defining the initialization parameters for a fixed-price sale
    struct FixedPriceSaleInitializationParams {
        /// @notice Duration of the prefund period in seconds
        /// @dev Specifies how long the prefund phase lasts before allocation
        uint256 prefundPeriodSeconds;
        /// @notice Duration of the prefund allocation period in seconds
        /// @dev Specifies the time between prefund end and sale start
        uint256 prefundAllocationPeriodSeconds;
        /// @notice Price of the token being sold in terms of the bid token
        /// @dev Denominated in the token used to raise capital
        uint256 tokenPrice;
    }

    /// @notice Struct containing the runtime configuration of the fixed-price sale
    struct FixedPriceSaleConfiguration {
        /// @notice Price of the token being sold in terms of the bid token
        /// @dev Denominated in the token used to raise capital
        uint256 tokenPrice;
        /// @notice Unix timestamp (in seconds) when the prefund period begins
        /// @dev Set at contract initialization
        uint256 prefundStartTime;
        /// @notice Unix timestamp (in seconds) when the prefund period ends
        /// @dev Calculated as prefundStartTime + prefundPeriodSeconds
        uint256 prefundEndTime;
    }

    /**
     * @notice Emitted when capital is successfully invested in the sale
     * @dev Logs investment details including whether it occurred during prefund
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param isPrefund Indicates if investment occurred before sale start
     * @param positionId Unique identifier for the investment position
     */
    event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 positionId);

    /**
     * @notice Emitted when sale results are published by the Legion admin
     * @dev Logs merkle roots and token allocation for post-sale verification
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total amount of tokens allocated from the sale
     */
    event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);

    /**
     * @notice Initializes the fixed-price sale contract with parameters
     * @dev Must be implemented to set up sale configuration; callable only once
     * @param saleInitParams Calldata struct with common Legion sale initialization parameters
     * @param fixedPriceSaleInitParams Calldata struct with fixed-price sale specific initialization parameters
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
        FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external;

    /**
     * @notice Allows investment of capital into the fixed-price sale
     * @dev Must verify investor eligibility and sale conditions
     * @param amount Amount of capital (in bid tokens) to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes memory signature) external;

    /**
     * @notice Publishes the results of the fixed-price sale
     * @dev Must be restricted to Legion admin and callable only after sale conclusion
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total tokens allocated for distribution
     * @param askTokenDecimals Decimals of the ask token for price calculation
     */
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        bytes32 acceptedMerkleRoot,
        uint256 tokensAllocated,
        uint8 askTokenDecimals
    )
        external;

    /**
     * @notice Retrieves the current fixed-price sale configuration
     * @dev Must return the FixedPriceSaleConfiguration struct
     * @return FixedPriceSaleConfiguration memory Struct containing the sale configuration
     */
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
}
