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

import { Constants } from "../utils/Constants.sol";
import { Errors } from "../utils/Errors.sol";

import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";
import { ILegionVestingManager } from "../interfaces/vesting/ILegionVestingManager.sol";

/**
 * @title Legion Vesting Manager
 * @author Legion
 * @notice Manages vesting creation and deployment in the Legion Protocol.
 * @dev Abstract contract implementing ILegionVestingManager with vesting type logic and factory interactions.
 */
abstract contract LegionVestingManager is ILegionVestingManager {
    /// @dev Struct containing the vesting configuration for the sale.
    LegionVestingConfig internal s_vestingConfig;

    /// @inheritdoc ILegionVestingManager
    function vestingConfiguration() external view virtual returns (LegionVestingConfig memory) {
        return s_vestingConfig;
    }

    /// @dev Creates a vesting schedule contract for an investor based on configuration.
    /// @param investorVestingConfig The vesting schedule configuration for the investor.
    /// @return vestingInstance The address of the deployed vesting contract instance.
    function _createVesting(LegionInvestorVestingConfig calldata investorVestingConfig)
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear vesting schedule instance
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR) {
            vestingInstance = _createLinearVesting(
                msg.sender,
                s_vestingConfig.vestingFactory,
                investorVestingConfig.vestingStartTime,
                investorVestingConfig.vestingDurationSeconds,
                investorVestingConfig.vestingCliffDurationSeconds
            );
        }

        // Deploy a linear epoch vesting schedule instance
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            vestingInstance = _createLinearEpochVesting(
                msg.sender,
                s_vestingConfig.vestingFactory,
                investorVestingConfig.vestingStartTime,
                investorVestingConfig.vestingDurationSeconds,
                investorVestingConfig.vestingCliffDurationSeconds,
                investorVestingConfig.epochDurationSeconds,
                investorVestingConfig.numberOfEpochs
            );
        }
    }

    /// @dev Creates a linear vesting schedule contract.
    /// @param beneficiary The address to receive the vested tokens.
    /// @param vestingFactory The address of the vesting factory contract.
    /// @param startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param durationSeconds The duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    /// @return vestingInstance The address of the deployed linear vesting contract.
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

    /// @dev Creates a linear epoch-based vesting schedule contract.
    /// @param beneficiary The address to receive the vested tokens.
    /// @param vestingFactory The address of the vesting factory contract.
    /// @param startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param durationSeconds The duration of the vesting period in seconds.
    /// @param cliffDurationSeconds The duration of the cliff period in seconds.
    /// @param epochDurationSeconds The duration of each epoch in seconds.
    /// @param numberOfEpochs The total number of epochs in the vesting schedule.
    /// @return vestingInstance The address of the deployed epoch vesting contract.
    function _createLinearEpochVesting(
        address beneficiary,
        address vestingFactory,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint64 epochDurationSeconds,
        uint64 numberOfEpochs
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

    /// @dev Verifies the validity of a vesting configuration.
    /// @param investorVestingConfig The vesting schedule configuration to validate.
    function _verifyValidVestingConfig(LegionInvestorVestingConfig calldata investorVestingConfig)
        internal
        view
        virtual
    {
        // Check if vesting duration is no more than 10 years, if vesting cliff duration is not more than vesting
        // duration, or the token allocation on TGE rate is no more than 100%
        if (
            investorVestingConfig.vestingStartTime > (Constants.MAX_VESTING_LOCKUP_SECONDS + block.timestamp)
                || investorVestingConfig.vestingDurationSeconds > Constants.MAX_VESTING_DURATION_SECONDS
                || investorVestingConfig.vestingCliffDurationSeconds > investorVestingConfig.vestingDurationSeconds
                || investorVestingConfig.tokenAllocationOnTGERate > Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR
        ) {
            revert Errors.LegionVesting__InvalidVestingConfig(
                uint8(investorVestingConfig.vestingType),
                investorVestingConfig.vestingStartTime,
                investorVestingConfig.vestingDurationSeconds,
                investorVestingConfig.vestingCliffDurationSeconds,
                investorVestingConfig.epochDurationSeconds,
                investorVestingConfig.numberOfEpochs,
                investorVestingConfig.tokenAllocationOnTGERate
            );
        }

        // Check if vesting type is LEGION_LINEAR_EPOCH
        if (investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            // Check if the number of epochs multiplied by the epoch duration is not more than 10 years
            // Check if the number of epochs multiplied by the epoch duration is equal to the vesting duration
            if (
                (investorVestingConfig.numberOfEpochs * investorVestingConfig.epochDurationSeconds)
                    > Constants.MAX_VESTING_DURATION_SECONDS
                    || (investorVestingConfig.numberOfEpochs * investorVestingConfig.epochDurationSeconds)
                        != investorVestingConfig.vestingDurationSeconds
                    || investorVestingConfig.epochDurationSeconds > Constants.MAX_EPOCH_DURATION_SECONDS
            ) {
                revert Errors.LegionVesting__InvalidVestingConfig(
                    uint8(investorVestingConfig.vestingType),
                    investorVestingConfig.vestingStartTime,
                    investorVestingConfig.vestingDurationSeconds,
                    investorVestingConfig.vestingCliffDurationSeconds,
                    investorVestingConfig.epochDurationSeconds,
                    investorVestingConfig.numberOfEpochs,
                    investorVestingConfig.tokenAllocationOnTGERate
                );
            }
        }
    }
}
