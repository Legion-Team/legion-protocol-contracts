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
 * @title Legion Vesting Interface
 * @author Legion
 * @notice An interface for managing vesting creation and deployment in the Legion Protocol
 */
interface ILegionVestingManager {
    /// @notice An enum describing possible vesting types.
    enum VestingType {
        LEGION_LINEAR,
        LEGION_LINEAR_EPOCH
    }

    /// @notice A struct describing the vesting configuration for the sale.
    struct LegionVestingConfig {
        /// @dev The address of Legion's Vesting Factory contract.
        address vestingFactory;
    }

    /// @notice A struct describing the vesting status for an investor.
    struct LegionInvestorVestingStatus {
        /// @dev The Unix timestamp (seconds) of the block when the vesting starts.
        uint256 start;
        /// @dev The Unix timestamp (seconds) of the block when the vesting ends.
        uint256 end;
        /// @dev The Unix timestamp (seconds) of the block when the cliff ends.
        uint256 cliffEnd;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 duration;
        /// @dev The amount of tokens released to the investor.
        uint256 released;
        /// @dev The amount of tokens that are currently releasable.
        uint256 releasable;
        /// @dev The amount of tokens that are currently vested.
        uint256 vestedAmount;
    }

    /// @notice A struct describing the vesting configuration for an investor.
    struct LegionInvestorVestingConfig {
        /// @dev The vesting type of the investor.
        ILegionVestingManager.VestingType vestingType;
        /// @dev The Unix timestamp (seconds) of the block when the vesting starts.
        uint256 vestingStartTime;
        /// @dev The vesting schedule duration for the token sold in seconds.
        uint256 vestingDurationSeconds;
        /// @dev The vesting cliff duration for the token sold in seconds.
        uint256 vestingCliffDurationSeconds;
        /// @dev The duration of each epoch in seconds.
        uint256 epochDurationSeconds;
        /// @dev The number of epochs.
        uint256 numberOfEpochs;
        /// @dev The token allocation amount released to investors after TGE in 18 decimals precision.
        uint256 tokenAllocationOnTGERate;
    }
}
