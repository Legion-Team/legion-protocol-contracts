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

interface ILegionVestingFactory {
    /**
     * @notice This event is emitted when a new linear vesting schedule contract is deployed for an investor.
     *
     * @param beneficiary The address of the beneficiary.
     * @param startTimestamp The Unix timestamp (seconds) when the vesting period starts.
     * @param durationSeconds The vesting duration in seconds.
     * @param cliffDurationSeconds The vesting cliff duration in seconds.
     */
    event NewLinearVestingCreated(
        address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffDurationSeconds
    );

    /**
     * @notice Deploy a LegionLinearVesting contract.
     *
     * @param beneficiary The address of the beneficiary.
     * @param startTimestamp The Unix timestamp (seconds) when the vesting starts.
     * @param durationSeconds The total duration of the vesting period in seconds.
     * @param cliffDurationSeconds The duration of the cliff period in seconds.
     *
     * @return linearVestingInstance The address of the deployed LegionLinearVesting instance.
     */
    function createLinearVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        returns (address payable linearVestingInstance);
}
