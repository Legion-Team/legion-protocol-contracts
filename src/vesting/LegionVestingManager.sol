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
    /// @param _investorVestingConfig The vesting schedule configuration for the investor.
    /// @param _askToken The address of the token used for vesting.
    /// @return vestingInstance The address of the deployed vesting contract instance.
    function _createVesting(
        LegionInvestorVestingConfig calldata _investorVestingConfig,
        address _askToken
    )
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear vesting schedule instance
        if (_investorVestingConfig.vestingType == VestingType.LEGION_LINEAR) {
            vestingInstance = _createLinearVesting(
                msg.sender,
                s_vestingConfig.vestingController,
                s_vestingConfig.vestingFactory,
                _investorVestingConfig.vestingStartTime,
                _investorVestingConfig.vestingDurationSeconds,
                _investorVestingConfig.vestingCliffDurationSeconds
            );
        }

        // Deploy a linear epoch vesting schedule instance
        if (_investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            vestingInstance = _createLinearEpochVesting(
                msg.sender,
                s_vestingConfig.vestingController,
                s_vestingConfig.vestingFactory,
                _askToken,
                _investorVestingConfig.vestingStartTime,
                _investorVestingConfig.vestingDurationSeconds,
                _investorVestingConfig.vestingCliffDurationSeconds,
                _investorVestingConfig.epochDurationSeconds,
                _investorVestingConfig.numberOfEpochs
            );
        }
    }

    /// @dev Creates a linear vesting schedule contract.
    /// @param _beneficiary The address to receive the vested tokens.
    /// @param _vestingController The address of the vesting controller contract.
    /// @param _vestingFactory The address of the vesting factory contract.
    /// @param _startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param _durationSeconds The duration of the vesting period in seconds.
    /// @param _cliffDurationSeconds The duration of the cliff period in seconds.
    /// @return vestingInstance The address of the deployed linear vesting contract.
    function _createLinearVesting(
        address _beneficiary,
        address _vestingController,
        address _vestingFactory,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds
    )
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear vesting schedule instance
        vestingInstance = ILegionVestingFactory(_vestingFactory).createLinearVesting(
            _beneficiary, _vestingController, _startTimestamp, _durationSeconds, _cliffDurationSeconds
        );
    }

    /// @dev Creates a linear epoch-based vesting schedule contract.
    /// @param _beneficiary The address to receive the vested tokens.
    /// @param _vestingController The address of the vesting controller contract.
    /// @param _vestingFactory The address of the vesting factory contract.
    /// @param _askToken The address of the token to be vested.
    /// @param _startTimestamp The Unix timestamp (seconds) when vesting starts.
    /// @param _durationSeconds The duration of the vesting period in seconds.
    /// @param _cliffDurationSeconds The duration of the cliff period in seconds.
    /// @param _epochDurationSeconds The duration of each epoch in seconds.
    /// @param _numberOfEpochs The total number of epochs in the vesting schedule.
    /// @return vestingInstance The address of the deployed epoch vesting contract.
    function _createLinearEpochVesting(
        address _beneficiary,
        address _vestingController,
        address _vestingFactory,
        address _askToken,
        uint64 _startTimestamp,
        uint64 _durationSeconds,
        uint64 _cliffDurationSeconds,
        uint64 _epochDurationSeconds,
        uint64 _numberOfEpochs
    )
        internal
        virtual
        returns (address payable vestingInstance)
    {
        // Deploy a linear epoch vesting schedule instance
        vestingInstance = ILegionVestingFactory(_vestingFactory).createLinearEpochVesting(
            _beneficiary,
            _vestingController,
            _askToken,
            _startTimestamp,
            _durationSeconds,
            _cliffDurationSeconds,
            _epochDurationSeconds,
            _numberOfEpochs
        );
    }

    /// @dev Verifies the validity of a vesting configuration.
    /// @param _investorVestingConfig The vesting schedule configuration to validate.
    function _verifyValidVestingConfig(LegionInvestorVestingConfig calldata _investorVestingConfig)
        internal
        view
        virtual
    {
        // Check if vesting duration is no more than 10 years, if vesting cliff duration is not more than vesting
        // duration, or the token allocation on TGE rate is no more than 100%
        if (
            _investorVestingConfig.vestingStartTime > (Constants.MAX_VESTING_LOCKUP_SECONDS + block.timestamp)
                || _investorVestingConfig.vestingDurationSeconds > Constants.MAX_VESTING_DURATION_SECONDS
                || _investorVestingConfig.vestingCliffDurationSeconds > _investorVestingConfig.vestingDurationSeconds
                || _investorVestingConfig.tokenAllocationOnTGERate > Constants.TOKEN_ALLOCATION_RATE_DENOMINATOR
        ) {
            revert Errors.LegionVesting__InvalidVestingConfig(
                uint8(_investorVestingConfig.vestingType),
                _investorVestingConfig.vestingStartTime,
                _investorVestingConfig.vestingDurationSeconds,
                _investorVestingConfig.vestingCliffDurationSeconds,
                _investorVestingConfig.epochDurationSeconds,
                _investorVestingConfig.numberOfEpochs,
                _investorVestingConfig.tokenAllocationOnTGERate
            );
        }

        // Check if vesting type is LEGION_LINEAR_EPOCH
        if (_investorVestingConfig.vestingType == VestingType.LEGION_LINEAR_EPOCH) {
            // Check if the number of epochs multiplied by the epoch duration is not more than 10 years
            // Check if the number of epochs multiplied by the epoch duration is equal to the vesting duration
            if (
                (_investorVestingConfig.numberOfEpochs * _investorVestingConfig.epochDurationSeconds)
                    > Constants.MAX_VESTING_DURATION_SECONDS
                    || (_investorVestingConfig.numberOfEpochs * _investorVestingConfig.epochDurationSeconds)
                        != _investorVestingConfig.vestingDurationSeconds
                    || _investorVestingConfig.epochDurationSeconds > Constants.MAX_EPOCH_DURATION_SECONDS
            ) {
                revert Errors.LegionVesting__InvalidVestingConfig(
                    uint8(_investorVestingConfig.vestingType),
                    _investorVestingConfig.vestingStartTime,
                    _investorVestingConfig.vestingDurationSeconds,
                    _investorVestingConfig.vestingCliffDurationSeconds,
                    _investorVestingConfig.epochDurationSeconds,
                    _investorVestingConfig.numberOfEpochs,
                    _investorVestingConfig.tokenAllocationOnTGERate
                );
            }
        }
    }
}
