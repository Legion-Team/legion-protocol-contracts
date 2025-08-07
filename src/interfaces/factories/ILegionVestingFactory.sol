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
 * @notice Interface for the LegionVestingFactory contract.
 * @dev Provides factory functionality for deploying and initializing vesting contracts with different schedules.
 */
interface ILegionVestingFactory {
    /// @notice Emitted when a new linear vesting schedule contract is deployed for an investor.
    /// @param beneficiary The address of the beneficiary receiving the vested tokens.
    /// @param vestingController The address of the vesting controller contract for access control.
    /// @param startTimestamp The Unix timestamp (in seconds) when the vesting period begins.
    /// @param durationSeconds The total duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    event NewLinearVestingCreated(
        address beneficiary,
        address vestingController,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    );

    /// @notice Emitted when a new linear epoch vesting schedule contract is deployed for an investor.
    /// @param beneficiary The address of the beneficiary receiving the vested tokens.
    /// @param vestingController The address of the vesting controller contract for access control.
    /// @param askToken The address of the token to be vested.
    /// @param startTimestamp The Unix timestamp (in seconds) when the vesting period begins.
    /// @param durationSeconds The total duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    /// @param epochDurationSeconds The duration of each epoch in seconds.
    /// @param numberOfEpochs The total number of epochs in the vesting schedule.
    event NewLinearEpochVestingCreated(
        address beneficiary,
        address vestingController,
        address askToken,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint64 epochDurationSeconds,
        uint64 numberOfEpochs
    );

    /// @notice Creates a new linear vesting contract instance.
    /// @param beneficiary The address that will receive the vested tokens.
    /// @param vestingController The address of the vesting controller contract for access control.
    /// @param startTimestamp The Unix timestamp when the vesting period begins.
    /// @param durationSeconds The total duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    /// @return linearVestingInstance The address of the newly deployed and initialized LegionLinearVesting instance.
    function createLinearVesting(
        address beneficiary,
        address vestingController,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        returns (address payable linearVestingInstance);

    /// @notice Creates a new linear epoch vesting contract instance.
    /// @param beneficiary The address that will receive the vested tokens.
    /// @param vestingController The address of the vesting controller contract for access control.
    /// @param askToken The address of the token to be vested.
    /// @param startTimestamp The Unix timestamp when the vesting period begins.
    /// @param durationSeconds The total duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    /// @param epochDurationSeconds The duration of each epoch in seconds.
    /// @param numberOfEpochs The total number of epochs in the vesting schedule.
    /// @return linearEpochVestingInstance The address of the newly deployed and initialized LegionLinearEpochVesting
    /// instance.
    function createLinearEpochVesting(
        address beneficiary,
        address vestingController,
        address askToken,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint64 epochDurationSeconds,
        uint64 numberOfEpochs
    )
        external
        returns (address payable linearEpochVestingInstance);
}
