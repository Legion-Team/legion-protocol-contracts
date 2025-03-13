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
    /// @notice Constant representing the denominator for basis points calculations
    /// @dev Equals 10,000, used to express percentages in basis points (1% = 100 bps)
    uint256 internal constant BASIS_POINTS_DENOMINATOR = 10_000;

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
