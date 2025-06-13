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

/**
 * @title ILegionVestingManager
 * @author Legion
 * @notice Interface for managing vesting creation and deployment in the Legion Protocol
 * @dev Defines vesting types and structs for vesting configuration and status tracking
 */
interface ILegionVestingManager {
    /**
     * @notice Enum defining supported vesting types in the Legion Protocol
     * @dev Used to specify the vesting schedule type for investors
     */
    enum VestingType {
        /// @notice Linear vesting with a cliff period
        LEGION_LINEAR,
        /// @notice Linear vesting with epoch-based releases and a cliff period
        LEGION_LINEAR_EPOCH
    }

    /**
     * @notice Struct containing the vesting configuration for a sale
     * @dev Stores factory address for deploying vesting contracts
     */
    struct LegionVestingConfig {
        /// @notice Address of Legion's Vesting Factory contract
        /// @dev Used to create vesting instances for investors
        address vestingFactory;
    }

    /**
     * @notice Struct representing an investor's vesting status
     * @dev Provides a snapshot of vesting progress and token amounts
     */
    struct LegionInvestorVestingStatus {
        /// @notice Unix timestamp (seconds) when vesting starts
        /// @dev Marks the beginning of the vesting schedule
        uint256 start;
        /// @notice Unix timestamp (seconds) when vesting ends
        /// @dev Marks the end of the vesting schedule
        uint256 end;
        /// @notice Unix timestamp (seconds) when the cliff period ends
        /// @dev Indicates when tokens become releasable
        uint256 cliffEnd;
        /// @notice Duration of the vesting schedule in seconds
        /// @dev Total time over which tokens vest
        uint256 duration;
        /// @notice Amount of tokens already released to the investor
        /// @dev Tracks tokens transferred to the beneficiary
        uint256 released;
        /// @notice Amount of tokens currently available for release
        /// @dev Represents tokens vested but not yet claimed
        uint256 releasable;
        /// @notice Amount of tokens vested up to the current timestamp
        /// @dev Total vested amount, including released and releasable
        uint256 vestedAmount;
    }

    /**
     * @notice Struct defining an investor's vesting configuration
     * @dev Specifies parameters for creating a vesting schedule
     */
    struct LegionInvestorVestingConfig {
        /// @notice Type of vesting schedule for the investor
        /// @dev References VestingType enum (LEGION_LINEAR or LEGION_LINEAR_EPOCH)
        ILegionVestingManager.VestingType vestingType;
        /// @notice Unix timestamp (seconds) when vesting starts
        /// @dev Sets the starting point of the vesting period
        uint256 vestingStartTime;
        /// @notice Duration of the vesting schedule in seconds
        /// @dev Total time over which tokens vest
        uint256 vestingDurationSeconds;
        /// @notice Duration of the cliff period in seconds
        /// @dev Time before which no tokens can be released
        uint256 vestingCliffDurationSeconds;
        /// @notice Duration of each epoch in seconds (for epoch vesting)
        /// @dev Defines the interval for token releases in LEGION_LINEAR_EPOCH
        uint256 epochDurationSeconds;
        /// @notice Total number of epochs (for epoch vesting)
        /// @dev Determines the granularity of releases in LEGION_LINEAR_EPOCH
        uint256 numberOfEpochs;
        /// @notice Token allocation released at TGE (18 decimals precision)
        /// @dev Percentage of tokens (in wei) released immediately after TGE
        uint256 tokenAllocationOnTGERate;
    }

    /**
     * @notice Retrieves the current vesting configuration
     * @dev Must return the LegionVestingConfig struct
     * @return ILegionVestingManager.LegionVestingConfig memory Struct containing vesting configuration
     */
    function vestingConfiguration() external view returns (ILegionVestingManager.LegionVestingConfig memory);
}
