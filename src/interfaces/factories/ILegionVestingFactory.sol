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
 * @title ILegionVestingFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion vesting contract instances
 * @dev Defines events and functions for creating linear and epoch-based vesting contracts
 */
interface ILegionVestingFactory {
    /**
     * @notice Emitted when a new linear vesting schedule contract is deployed for an investor
     * @dev Provides details about the new linear vesting instance and its configuration
     * @param beneficiary Address of the beneficiary receiving the vested tokens
     * @param startTimestamp Unix timestamp (in seconds) when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     */
    event NewLinearVestingCreated(
        address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffDurationSeconds
    );

    /**
     * @notice Emitted when a new linear epoch vesting schedule contract is deployed for an investor
     * @dev Provides details about the new epoch-based vesting instance and its configuration
     * @param beneficiary Address of the beneficiary receiving the vested tokens
     * @param startTimestamp Unix timestamp (in seconds) when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @param epochDurationSeconds Duration of each epoch in seconds
     * @param numberOfEpochs Total number of epochs in the vesting schedule
     */
    event NewLinearEpochVestingCreated(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs
    );

    /**
     * @notice Deploys a new LegionLinearVesting contract instance
     * @dev Must be implemented to create and initialize a new linear vesting contract
     * @param beneficiary Address of the beneficiary receiving the vested tokens
     * @param startTimestamp Unix timestamp (in seconds) when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @return linearVestingInstance Address of the newly deployed LegionLinearVesting instance
     */
    function createLinearVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        returns (address payable linearVestingInstance);

    /**
     * @notice Deploys a new LegionLinearEpochVesting contract instance
     * @dev Must be implemented to create and initialize a new epoch-based vesting contract
     * @param beneficiary Address that will receive the vested tokens
     * @param startTimestamp Unix timestamp (in seconds) when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @param epochDurationSeconds Duration of each epoch in seconds
     * @param numberOfEpochs Total number of epochs in the vesting schedule
     * @return linearEpochVestingInstance Address of the newly deployed LegionLinearEpochVesting instance
     */
    function createLinearEpochVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs
    )
        external
        returns (address payable linearEpochVestingInstance);
}
