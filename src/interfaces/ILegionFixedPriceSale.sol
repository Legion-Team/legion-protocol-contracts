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

import { ILegionSale } from "./ILegionSale.sol";

interface ILegionFixedPriceSale is ILegionSale {
    /// @notice A struct describing the fixed price sale initialization params.
    struct FixedPriceSaleInitializationParams {
        /// @dev The prefund period duration in seconds.
        uint256 prefundPeriodSeconds;
        /// @dev The prefund allocation period duration in seconds.
        uint256 prefundAllocationPeriodSeconds;
        /// @dev The price of the token being sold denominated in the token used to raise capital.
        uint256 tokenPrice;
    }

    /// @notice A struct describing the fixed price sale configuration.
    struct FixedPriceSaleConfiguration {
        /// @dev The price of the token being sold denominated in the token used to raise capital.
        uint256 tokenPrice;
        /// @dev The unix timestamp (seconds) of the block when the prefund starts.
        uint256 prefundStartTime;
        /// @dev The unix timestamp (seconds) of the block when the prefund ends.
        uint256 prefundEndTime;
    }

    /**
     * @notice This event is emitted when capital is successfully invested.
     *
     * @param amount The amount of capital invested.
     * @param investor The address of the investor.
     * @param isPrefund Whether capital is invested before sale start.
     * @param investTimestamp The unix timestamp (seconds) of the block when capital has been invested.
     */
    event CapitalInvested(uint256 amount, address investor, bool isPrefund, uint256 investTimestamp);

    /**
     * @notice This event is emitted when sale results are successfully published by the Legion admin.
     *
     * @param claimMerkleRoot The merkle root to verify token claims.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     * @param tokensAllocated The amount of tokens allocated from the sale.
     */
    event SaleResultsPublished(bytes32 claimMerkleRoot, bytes32 acceptedMerkleRoot, uint256 tokensAllocated);

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
        external;

    /**
     * @notice Invest capital to the fixed price sale.
     *
     * @param amount The amount of capital invested.
     * @param signature The Legion signature for verification.
     */
    function invest(uint256 amount, bytes memory signature) external;

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
        external;

    /**
     * @notice Returns the fixed price sale configuration.
     */
    function fixedPriceSaleConfiguration() external view returns (FixedPriceSaleConfiguration memory);
}
