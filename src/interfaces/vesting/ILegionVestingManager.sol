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
 * @title ILegionVestingManager
 * @author Legion
 * @notice Interface for the LegionVestingManager contract.
 */
interface ILegionVestingManager {
    /// @dev Enum defining supported vesting types in the Legion Protocol.
    enum VestingType {
        // Linear vesting with a cliff period.
        LEGION_LINEAR,
        // Linear vesting with epoch-based releases and a cliff period.
        LEGION_LINEAR_EPOCH
    }

    /// @dev Struct containing the vesting configuration for a sale.
    struct LegionVestingConfig {
        // Address of Legion's Vesting Factory contract.
        address vestingFactory;
        // Address of Legion's Vesting Controller contract.
        address vestingController;
    }

    /// @dev Struct representing an investor's vesting status.
    struct LegionInvestorVestingStatus {
        // Unix timestamp (seconds) when vesting starts.
        uint64 start;
        // Unix timestamp (seconds) when vesting ends.
        uint64 end;
        // Unix timestamp (seconds) when the cliff period ends.
        uint64 cliffEnd;
        // Duration of the vesting schedule in seconds.
        uint64 duration;
        // Amount of tokens already released to the investor.
        uint256 released;
        // Amount of tokens currently available for release.
        uint256 releasable;
        // Amount of tokens vested up to the current timestamp.
        uint256 vestedAmount;
    }

    /// @dev Struct defining an investor's vesting configuration.
    struct LegionInvestorVestingConfig {
        // Unix timestamp (seconds) when vesting starts.
        uint64 vestingStartTime;
        // Duration of the vesting schedule in seconds.
        uint64 vestingDurationSeconds;
        // Duration of the cliff period in seconds.
        uint64 vestingCliffDurationSeconds;
        // Type of vesting schedule for the investor.
        ILegionVestingManager.VestingType vestingType;
        // Duration of each epoch in seconds (for epoch vesting).
        uint64 epochDurationSeconds;
        // Total number of epochs (for epoch vesting).
        uint64 numberOfEpochs;
        // Token allocation released at TGE (18 decimals precision).
        uint64 tokenAllocationOnTGERate;
    }

    /// @notice Returns the current vesting configuration.
    /// @return The complete vesting configuration struct.
    function vestingConfiguration() external view returns (ILegionVestingManager.LegionVestingConfig memory);
}
