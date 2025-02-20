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

/**
 * @title Legion Constants Library
 * @author Legion
 * @notice A library used for storing constants shared across the Legion protocol.
 */
library Constants {
    /// @dev Constant representing one hour in seconds
    uint256 internal constant ONE_HOUR = 3600;

    /// @dev Constant representing two weeks in seconds
    uint256 internal constant TWO_WEEKS = 1_209_600;

    /// @dev Constant representing forty days in seconds
    uint256 internal constant FORTY_DAYS = 3_456_000;

    /// @dev Constant representing 3 months in seconds.
    uint256 internal constant THREE_MONTHS = 7_776_000;

    /// @dev Constant representing 6 months in seconds.
    uint256 internal constant SIX_MONTHS = 15_780_000;

    /// @dev Constant representing 1 year in seconds.
    uint256 internal constant ONE_YEAR = 31_536_000;

    /// @dev Constant representing 10 years in seconds.
    uint256 internal constant TEN_YEARS = 315_360_000;

    /// @dev Constant representing the LEGION_BOUNCER unique ID
    bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");

    /// @dev Constant representing the LEGION_FEE_RECEIVER unique ID
    bytes32 internal constant LEGION_FEE_RECEIVER_ID = bytes32("LEGION_FEE_RECEIVER");

    /// @dev Constant representing the LEGION_SIGNER unique ID
    bytes32 internal constant LEGION_SIGNER_ID = bytes32("LEGION_SIGNER");

    /// @dev Constant representing the LEGION_VESTING_FACTORY unique ID
    bytes32 internal constant LEGION_VESTING_FACTORY_ID = bytes32("LEGION_VESTING_FACTORY");
}
