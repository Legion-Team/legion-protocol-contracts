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

/**
 * @title Legion Constants Library
 * @author Legion
 * @notice Stores constants shared across the Legion Protocol.
 * @dev Provides immutable values for time periods, denominators, and unique identifiers used throughout the protocol.
 */
library Constants {
    /// @dev Maximum duration allowed for token vesting, set to 520 weeks (10 years).
    uint64 internal constant MAX_VESTING_DURATION_SECONDS = 520 weeks;

    /// @dev Maximum duration allowed for an epoch, set to 52 weeks (1 year).
    uint64 internal constant MAX_EPOCH_DURATION_SECONDS = 52 weeks;

    /// @dev Maximum duration allowed for lockup periods, set to 520 weeks (10 years).
    uint64 internal constant MAX_VESTING_LOCKUP_SECONDS = 520 weeks;

    /// @dev Denominator for token allocation rate calculations (1e18 for 18 decimal precision).
    uint64 internal constant TOKEN_ALLOCATION_RATE_DENOMINATOR = 1e18;

    /// @dev Denominator for basis points calculations (10,000 where 1% = 100 bps).
    uint16 internal constant BASIS_POINTS_DENOMINATOR = 1e4;

    /// @dev Unique identifier for the Legion Bouncer in the Address Registry.
    bytes32 internal constant LEGION_BOUNCER_ID = bytes32("LEGION_BOUNCER");

    /// @dev Unique identifier for the Legion Fee Receiver in the Address Registry.
    bytes32 internal constant LEGION_FEE_RECEIVER_ID = bytes32("LEGION_FEE_RECEIVER");

    /// @dev Unique identifier for the Legion Signer in the Address Registry.
    bytes32 internal constant LEGION_SIGNER_ID = bytes32("LEGION_SIGNER");

    /// @dev Unique identifier for the Legion Vesting Factory in the Address Registry.
    bytes32 internal constant LEGION_VESTING_FACTORY_ID = bytes32("LEGION_VESTING_FACTORY");

    /// @dev Unique identifier for the Legion Vesting Controller in the Address Registry.
    bytes32 internal constant LEGION_VESTING_CONTROLLER_ID = bytes32("LEGION_VESTING_CONTROLLER");
}
