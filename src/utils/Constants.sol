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
    /// @notice Constant representing one hour in seconds
    /// @dev Equals 3600 seconds (60 minutes * 60 seconds)
    uint256 internal constant ONE_HOUR = 3600;

    /// @notice Constant representing two weeks in seconds
    /// @dev Equals 1,209,600 seconds (14 days * 24 hours * 3600 seconds)
    uint256 internal constant TWO_WEEKS = 1_209_600;

    /// @notice Constant representing three months in seconds
    /// @dev Equals 7,776,000 seconds (90 days * 24 hours * 3600 seconds)
    uint256 internal constant THREE_MONTHS = 7_776_000;

    /// @notice Constant representing one year in seconds
    /// @dev Equals 31,536,000 seconds (365 days * 24 hours * 3600 seconds)
    uint256 internal constant ONE_YEAR = 31_536_000;

    /// @notice Constant representing ten years in seconds
    /// @dev Equals 315,360,000 seconds (10 * ONE_YEAR)
    uint256 internal constant TEN_YEARS = 315_360_000;

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
