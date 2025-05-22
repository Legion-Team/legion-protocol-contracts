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

import { ILegionSale } from "./ILegionSale.sol";

/**
 * @title ILegionPreLiquidSaleV2
 * @author Legion
 * @notice Interface for managing pre-liquid sales of ERC20 tokens before TGE in the Legion Protocol
 * @dev Extends ILegionSale with pre-liquid sale specific functionality and events
 */
interface ILegionPreLiquidSaleV2 is ILegionSale {
    /// @notice Struct defining the configuration for the pre-liquid sale
    struct PreLiquidSaleConfiguration {
        /// @notice Duration of the refund period in seconds
        /// @dev Time window for investors to request refunds
        uint256 refundPeriodSeconds;
        /// @notice Flag indicating whether the sale has ended
        /// @dev Tracks the sale's end status
        bool hasEnded;
    }

    /**
     * @notice Emitted when capital is successfully invested in the pre-liquid sale
     * @dev Logs investment details for tracking
     * @param amount Amount of capital invested (in bid tokens)
     * @param investor Address of the investor
     * @param investTimestamp Unix timestamp (in seconds) of the investment
     * @param positionId Unique identifier for the investment position
     */
    event CapitalInvested(uint256 amount, address investor, uint256 investTimestamp, uint256 positionId);

    /**
     * @notice Emitted when sale results are published by the Legion admin
     * @dev Logs token allocation and distribution details
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param tokensAllocated Total amount of tokens allocated from the sale
     * @param tokenAddress Address of the token distributed to investors
     */
    event SaleResultsPublished(bytes32 claimMerkleRoot, uint256 tokensAllocated, address tokenAddress);

    /**
     * @notice Emitted when the total capital raised is published by the Legion admin
     * @dev Logs the finalized capital raised and verification data
     * @param capitalRaised Total capital raised by the project
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     */
    event CapitalRaisedPublished(uint256 capitalRaised, bytes32 acceptedMerkleRoot);

    /**
     * @notice Emitted when the sale is ended by Legion or Project
     * @dev Logs the timestamp of sale completion
     * @param endTime Unix timestamp (in seconds) when the sale ended
     */
    event SaleEnded(uint256 endTime);

    /**
     * @notice Initializes the pre-liquid sale with parameters
     * @dev Must be implemented to set up sale configuration; callable only once
     * @param saleInitParams Calldata struct with Legion sale initialization parameters
     */
    function initialize(LegionSaleInitializationParams calldata saleInitParams) external;

    /**
     * @notice Allows investment into the pre-liquid sale
     * @dev Must verify investor eligibility and update sale state
     * @param amount Amount of capital (in bid tokens) to invest
     * @param signature Legion signature for investor verification
     */
    function invest(uint256 amount, bytes memory signature) external;

    /**
     * @notice Publishes sale results after conclusion
     * @dev Must be restricted to Legion admin; sets token distribution data
     * @param claimMerkleRoot Merkle root for verifying token claims
     * @param tokensAllocated Total tokens allocated for distribution
     * @param askToken Address of the token distributed to investors
     */
    function publishSaleResults(bytes32 claimMerkleRoot, uint256 tokensAllocated, address askToken) external;

    /**
     * @notice Publishes the total capital raised by the project
     * @dev Must be restricted to Legion admin; sets capital raised and verification data
     * @param capitalRaised Total capital raised by the project
     * @param acceptedMerkleRoot Merkle root for verifying accepted capital
     */
    function publishCapitalRaised(uint256 capitalRaised, bytes32 acceptedMerkleRoot) external;

    /**
     * @notice Ends the sale and sets the refund end time
     * @dev Must be restricted to Legion or Project; updates sale status
     */
    function endSale() external;

    /**
     * @notice Retrieves the current pre-liquid sale configuration
     * @dev Must return the PreLiquidSaleConfiguration struct
     * @return PreLiquidSaleConfiguration memory Struct containing the sale configuration
     */
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
}
