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

/**
 * @title Legion Constants Library
 * @author Legion
 * @notice A library storing constants shared across the Legion Protocol
 * @dev Provides immutable values for time periods and unique IDs used in contracts
 */
library Constants {
    /// @notice Maximum duration allowed for token vesting, set to 520 weeks (10 years)
    /// @dev Represents the upper limit for vesting periods in seconds.
    uint256 internal constant MAX_VESTING_DURATION_SECONDS = 520 weeks;

    /// @notice Maximum duration allowed for an epoch, set to 52 weeks (1 year)
    /// @dev Defines the maximum length of an epoch in seconds.
    uint256 internal constant MAX_EPOCH_DURATION_SECONDS = 52 weeks;

    /// @notice Maximum duration allowed for lockup, set to 520 weeks (10 years)
    /// @dev Represents the upper limit for lockup periods in seconds.
    uint256 internal constant MAX_VESTING_LOCKUP_SECONDS = 520 weeks;

    /// @notice Constant representing the denominator for precise calculations
    /// @dev Equals 1e18, used for high-precision fee or rate computations with 18 decimals
    uint256 internal constant TOKEN_ALLOCATION_RATE_DENOMINATOR = 1e18;

    /// @notice Constant representing the denominator for basis points calculations
    /// @dev Equals 10,000, used to express percentages in basis points (1% = 100 bps)
    uint256 internal constant BASIS_POINTS_DENOMINATOR = 1e4;

    /// @notice Constant representing the unique ID for Legion Bouncer
    /// @dev Used to identify the Legion Bouncer in the Address Registry
    bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");

    /// @notice Constant representing the unique ID for Legion Fee Receiver
    /// @dev Used to identify the Fee Receiver in the Address Registry
    bytes32 internal constant LEGION_FEE_RECEIVER_ID = bytes32("LEGION_FEE_RECEIVER");

    /// @notice Constant representing the unique ID for Legion Signer
    /// @dev Used to identify the Signer in the Address Registry
    bytes32 internal constant LEGION_SIGNER_ID = bytes32("LEGION_SIGNER");

    /// @notice Constant representing the unique ID for Legion Vesting Factory
    /// @dev Used to identify the Vesting Factory in the Address Registry
    bytes32 internal constant LEGION_VESTING_FACTORY_ID = bytes32("LEGION_VESTING_FACTORY");
}
