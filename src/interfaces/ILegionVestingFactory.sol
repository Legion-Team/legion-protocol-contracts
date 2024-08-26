// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
interface ILegionVestingFactory {
    /**
     * @notice This event is emitted when a new linear vesting schedule contract is deployed for an investor.
     *
     * @param beneficiary The address of the beneficiary.
     * @param startTimestamp The start timestamp of the vesting period.
     * @param durationSeconds The vesting duration in seconds.
     * @param cliffDurationSeconds The vesting cliff duration in seconds.
     */
    event NewLinearVestingCreated(
        address beneficiary, uint64 startTimestamp, uint64 durationSeconds, uint64 cliffDurationSeconds
    );

    /**
     * @notice Deploy a LegionLinearVesting contract.
     *
     * @dev Can be called only by addresses allowed to deploy.
     *
     * @param beneficiary The beneficiary.
     * @param startTimestamp The start timestamp.
     * @param durationSeconds The duration in seconds.
     * @param cliffDurationSeconds The cliff duration in seconds.
     *
     * @return linearVestingInstance The address of the deployed linearVesting instance.
     */
    function createLinearVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    ) external returns (address payable linearVestingInstance);
}
