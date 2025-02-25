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

interface ILegionPreLiquidSaleV2 is ILegionSale {
    /// @notice A struct describing the pre-liquid sale configuration.
    struct PreLiquidSaleConfiguration {
        /// @dev The refund period duration in seconds.
        uint256 refundPeriodSeconds;
        /// @dev The lockup period duration in seconds.
        uint256 lockupPeriodSeconds;
        /// @dev Flag indicating if the sale has ended.
        bool hasEnded;
    }

    /**
     * @notice This event is emitted when capital is successfully invested.
     *
     * @param amount The amount of capital invested.
     * @param investor The address of the investor.
     * @param investTimestamp The Unix timestamp (seconds) of the block when capital has been invested.
     */
    event CapitalInvested(uint256 amount, address investor, uint256 investTimestamp);

    /**
     * @notice This event is emitted when sale results are successfully published by the Legion admin.
     *
     * @param claimMerkleRoot The merkle root to verify token claims.
     * @param tokensAllocated The amount of tokens allocated from the sale.
     * @param tokenAddress The address of the token distributed to investors.
     * @param vestingStartTime The Unix timestamp (seconds) of the block when the vesting starts.
     */
    event SaleResultsPublished(
        bytes32 claimMerkleRoot, uint256 tokensAllocated, address tokenAddress, uint256 vestingStartTime
    );

    /**
     * @notice This event is emitted when the capital raised is successfully published by the Legion admin.
     *
     * @param capitalRaised The total capital raised by the project.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     */
    event CapitalRaisedPublished(uint256 capitalRaised, bytes32 acceptedMerkleRoot);

    /**
     * @notice This event is emitted when the sale has been ended.
     *
     * @param endTime The unix timestamp (seconds) of the block when the sale has been ended.
     */
    event SaleEnded(uint256 endTime);

    /**
     * @notice Initializes the contract with correct parameters.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    function initialize(
        LegionSaleInitializationParams calldata saleInitParams,
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
     * @param tokensAllocated The total amount of tokens allocated for distribution among investors.
     * @param askToken The address of the token distributed to investors.
     * @param vestingStartTime The Unix timestamp (seconds) of the block when the vesting starts.
     */
    function publishSaleResults(
        bytes32 claimMerkleRoot,
        uint256 tokensAllocated,
        address askToken,
        uint256 vestingStartTime
    )
        external;

    /**
     * @notice Publish the total capital raised by the project.
     *
     * @param capitalRaised The total capital raised by the project.
     * @param acceptedMerkleRoot The merkle root to verify accepted capital.
     */
    function publishCapitalRaised(uint256 capitalRaised, bytes32 acceptedMerkleRoot) external;

    /**
     * @notice End sale by Legion or the Project and set the refund end time.
     */
    function endSale() external;

    /**
     * @notice Returns the pre-liquid sale configuration.
     */
    function preLiquidSaleConfiguration() external view returns (PreLiquidSaleConfiguration memory);
}
