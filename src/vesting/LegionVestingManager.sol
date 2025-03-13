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

import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";
import { ILegionVestingManager } from "../interfaces/vesting/ILegionVestingManager.sol";

/**
 * @title Legion Vesting Manager
 * @author Legion
 * @notice A contract for managing vesting creation and deployment in the Legion Protocol
 * @dev Abstract contract implementing ILegionVestingManager; handles vesting type logic
 */
abstract contract LegionVestingManager is ILegionVestingManager {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct containing the vesting configuration for the sale
    /// @dev Publicly accessible; stores factory address and other vesting settings
    LegionVestingConfig public vestingConfig;

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current vesting configuration
     * @dev Virtual function providing read-only access to vestingConfig
     * @return LegionVestingConfig memory Struct containing vesting configuration
     */
    function vestingConfiguration() external view virtual returns (LegionVestingConfig memory) {
        return vestingConfig;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a vesting schedule contract for an investor based on configuration
     * @dev Internal virtual function deploying either linear or epoch-based vesting
     * @param investorVestingConfig Calldata struct with vesting schedule configuration
     * @return vestingInstance Address of the deployed vesting contract instance (payable)
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
     * @notice Creates a linear vesting schedule contract
     * @dev Internal virtual function deploying a linear vesting instance via factory
     * @param beneficiary Address to receive the vested tokens
     * @param vestingFactory Address of the vesting factory contract
     * @param startTimestamp Unix timestamp (seconds) when vesting starts
     * @param durationSeconds Duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @return vestingInstance Address of the deployed linear vesting contract (payable)
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
     * @notice Creates a linear epoch-based vesting schedule contract
     * @dev Internal virtual function deploying an epoch vesting instance via factory
     * @param beneficiary Address to receive the vested tokens
     * @param vestingFactory Address of the vesting factory contract
     * @param startTimestamp Unix timestamp (seconds) when vesting starts
     * @param durationSeconds Duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @param epochDurationSeconds Duration of each epoch in seconds
     * @param numberOfEpochs Total number of epochs in the vesting schedule
     * @return vestingInstance Address of the deployed epoch vesting contract (payable)
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
     * @notice Verifies the validity of a vesting configuration
     * @dev Internal virtual function checking vesting parameters for correctness
     * @param investorVestingConfig Calldata struct with vesting schedule configuration
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
