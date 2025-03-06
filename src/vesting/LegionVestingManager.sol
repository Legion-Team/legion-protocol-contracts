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

import { ILegionVestingManager } from "../interfaces/vesting/ILegionVestingManager.sol";
import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";

/**
 * @title Legion Vesting
 * @author Legion
 * @notice A contract for managing vesting creation and deployment in the Legion Protocol
 */
abstract contract LegionVestingManager is ILegionVestingManager {
    /// @dev A struct describing the sale vesting configuration.
    LegionVestingConfig public vestingConfig;

    /**
     * @notice Create a vesting schedule contract for an investor.
     *
     * @param investorVestingConfig The configuration of the vesting schedule.
     *
     * @return vestingInstance The address of the deployed vesting instance.
     */
    function _createVesting(LegionInvestorVestingConfig memory investorVestingConfig)
        internal
        virtual
        returns (address payable vestingInstance)
    {
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR) {
            // Deploy a linear vesting schedule instance
            vestingInstance = ILegionVestingFactory(vestingConfig.vestingFactory).createLinearVesting(
                msg.sender,
                uint64(investorVestingConfig.vestingStartTime),
                uint64(investorVestingConfig.vestingDurationSeconds),
                uint64(investorVestingConfig.vestingCliffDurationSeconds)
            );
        }

        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            // Deploy a linear epoch vesting schedule instance
            vestingInstance = ILegionVestingFactory(vestingConfig.vestingFactory).createLinearEpochVesting(
                msg.sender,
                uint64(investorVestingConfig.vestingStartTime),
                uint64(investorVestingConfig.vestingDurationSeconds),
                uint64(investorVestingConfig.vestingCliffDurationSeconds),
                investorVestingConfig.epochDurationSeconds,
                investorVestingConfig.numberOfEpochs
            );
        }
    }

    /**
     * @notice Create a linear vesting schedule contract.
     *
     * @param beneficiary The beneficiary.
     * @param vestingFactory The address of the vesting factory.
     * @param startTimestamp The Unix timestamp when the vesting starts.
     * @param durationSeconds The duration in seconds.
     * @param cliffDurationSeconds The cliff duration in seconds.
     *
     * @return vestingInstance The address of the deployed vesting instance.
     */
    function _createLinearVesting(
        address beneficiary,
        address vestingFactory,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear vesting schedule instance
        vestingInstance = ILegionVestingFactory(vestingFactory).createLinearVesting(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }

    /**
     * @notice Create a linear vesting schedule contract.
     *
     * @param beneficiary The address that will receive the vested tokens
     * @param vestingFactory The address of the vesting factory.
     * @param startTimestamp The Unix timestamp when the vesting period starts
     * @param durationSeconds The duration of the vesting period in seconds
     * @param cliffDurationSeconds The duration of the cliff period in seconds
     * @param epochDurationSeconds The duration of each epoch in seconds
     * @param numberOfEpochs The number of epochs
     *
     * @return vestingInstance The address of the deployed vesting instance.
     */
    function _createLinearEpochVesting(
        address beneficiary,
        address vestingFactory,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs
    )
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear epoch vesting schedule instance
        vestingInstance = ILegionVestingFactory(vestingFactory).createLinearEpochVesting(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds, epochDurationSeconds, numberOfEpochs
        );
    }
}
