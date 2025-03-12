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

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

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
    function _createVesting(LegionInvestorVestingConfig calldata investorVestingConfig)
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear vesting schedule instance
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR) {
            vestingInstance = _createLinearVesting(
                msg.sender,
                vestingConfig.vestingFactory,
                uint64(investorVestingConfig.vestingStartTime),
                uint64(investorVestingConfig.vestingDurationSeconds),
                uint64(investorVestingConfig.vestingCliffDurationSeconds)
            );
        }

        // Deploy a linear epoch vesting schedule instance
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            vestingInstance = _createLinearEpochVesting(
                msg.sender,
                vestingConfig.vestingFactory,
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

    /**
     * @notice Verify that the  vesting configuration is valid.
     *
     * @param investorVestingConfig The configuration of the vesting schedule.
     */
    function _verifyValidLinearVestingConfig(LegionInvestorVestingConfig calldata investorVestingConfig)
        internal
        view
        virtual
    {
        /// Check if vesting duration is no more than 10 years, if vesting cliff duration is not more than vesting
        /// duration or the token allocation on TGE rate is no more than 100%
        if (
            investorVestingConfig.vestingDurationSeconds > Constants.TEN_YEARS
                || investorVestingConfig.vestingCliffDurationSeconds > investorVestingConfig.vestingDurationSeconds
                || investorVestingConfig.tokenAllocationOnTGERate > 1e18
        ) revert Errors.InvalidVestingConfig();

        /// Check if vesting type is LEGION_LINEAR_EPOCH
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            /// Check if the number of epochs multiplied by the epoch duration is not more than 10 years
            /// Check if the number of epochs multiplied by the epoch duration is equal to the vesting duration
            if (
                (investorVestingConfig.numberOfEpochs * investorVestingConfig.epochDurationSeconds)
                    > Constants.TEN_YEARS
                    || (investorVestingConfig.numberOfEpochs * investorVestingConfig.epochDurationSeconds)
                        != investorVestingConfig.vestingDurationSeconds
                    || investorVestingConfig.epochDurationSeconds > Constants.ONE_YEAR
            ) revert Errors.InvalidVestingConfig();
        }
    }
}
