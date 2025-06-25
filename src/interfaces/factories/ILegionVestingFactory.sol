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
 * @title ILegionVestingFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion vesting contract instances
 */
interface ILegionVestingFactory {
    /**
     * @notice Emitted when a new linear vesting schedule contract is deployed for an investor
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
        uint64 epochDurationSeconds,
        uint64 numberOfEpochs
    );

    /**
     * @notice Deploys a new LegionLinearVesting contract instance
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
        uint64 epochDurationSeconds,
        uint64 numberOfEpochs
    )
        external
        returns (address payable linearEpochVestingInstance);
}
