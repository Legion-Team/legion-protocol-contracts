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
 * @notice Interface for managing fixed-price sales of ERC20 tokens in the Legion Protocol
 */
interface ILegionFixedPriceSale is ILegionAbstractSale {
    /// @notice Struct defining the initialization parameters for a fixed-price sale
    struct FixedPriceSaleInitializationParams {
        /// @notice Duration of the prefund period in seconds
        /// @dev Specifies how long the prefund phase lasts before allocation
        uint64 prefundPeriodSeconds;
        /// @notice Duration of the prefund allocation period in seconds
        /// @dev Specifies the time between prefund end and sale start
        uint64 prefundAllocationPeriodSeconds;
        /// @notice Price of the token being sold in terms of the bid token
        /// @dev Denominated in the token used to raise capital
        uint256 tokenPrice;
    }

    /// @notice Struct containing the runtime configuration of the fixed-price sale
    struct FixedPriceSaleConfiguration {
        /// @notice Unix timestamp (in seconds) when the prefund period begins
        /// @dev Set at contract initialization
        uint64 prefundStartTime;
        /// @notice Unix timestamp (in seconds) when the prefund period ends
        /// @dev Calculated as prefundStartTime + prefundPeriodSeconds
        uint64 prefundEndTime;
        /// @notice Price of the token being sold in terms of the bid token
        /// @dev Denominated in the token used to raise capital
        uint256 tokenPrice;
    }

    /**
     * @notice Emitted when capital is successfully invested in the sale
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param isPrefund Indicates if investment occurred before sale start
     * @param positionId Unique identifier for the investment position
     */
    event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 positionId);

    /**
     * @notice Emitted when sale results are published by the Legion admin
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     * @param tokensAllocated Total amount of tokens allocated from the sale
     */
    event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);

    /**
     * @notice Initializes the fixed-price sale contract with parameters
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
     * @param amount Amount of capital (in bid tokens) to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes calldata signature) external;

    /**
     * @notice Publishes the results of the fixed-price sale
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
     * @return FixedPriceSaleConfiguration memory Struct containing the sale configuration
     */
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
}
