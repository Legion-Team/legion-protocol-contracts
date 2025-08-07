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

import { LibClone } from "@solady/src/utils/LibClone.sol";

import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";

import { LegionLinearEpochVesting } from "../vesting/LegionLinearEpochVesting.sol";
import { LegionLinearVesting } from "../vesting/LegionLinearVesting.sol";

/**
 * @title Legion Vesting Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion vesting contracts using the clone pattern.
 * @dev Creates gas-efficient clones of vesting implementation contracts for linear and epoch-based vesting schedules.
 */
contract LegionVestingFactory is ILegionVestingFactory {
    using LibClone for address;

    /// @notice The address of the LegionLinearVesting implementation contract used as a template.
    /// @dev Immutable reference to the base linear vesting implementation deployed during construction.
    address public immutable i_linearVestingTemplate = address(new LegionLinearVesting());

    /// @notice The address of the LegionLinearEpochVesting implementation contract used as a template.
    /// @dev Immutable reference to the base epoch vesting implementation deployed during construction.
    address public immutable i_linearEpochVestingTemplate = address(new LegionLinearEpochVesting());

    /// @inheritdoc ILegionVestingFactory
    function createLinearVesting(
        address beneficiary,
        address vestingController,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        returns (address payable linearVestingInstance)
    {
        // Deploy a LegionLinearVesting instance
        linearVestingInstance = payable(i_linearVestingTemplate.clone());

        // Emit NewLinearVestingCreated
        emit NewLinearVestingCreated(
            beneficiary, vestingController, startTimestamp, durationSeconds, cliffDurationSeconds
        );

        // Initialize the LegionLinearVesting with the provided configuration
        LegionLinearVesting(linearVestingInstance).initialize(
            beneficiary, vestingController, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }

    /// @inheritdoc ILegionVestingFactory
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
        returns (address payable linearEpochVestingInstance)
    {
        // Deploy a LegionLinearEpochVesting instance
        linearEpochVestingInstance = payable(i_linearEpochVestingTemplate.clone());

        // Emit NewLinearEpochVestingCreated
        emit NewLinearEpochVestingCreated(
            beneficiary,
            vestingController,
            askToken,
            startTimestamp,
            durationSeconds,
            cliffDurationSeconds,
            epochDurationSeconds,
            numberOfEpochs
        );

        // Initialize the LegionLinearEpochVesting with the provided configuration
        LegionLinearEpochVesting(linearEpochVestingInstance).initialize(
            beneficiary,
            vestingController,
            askToken,
            startTimestamp,
            durationSeconds,
            cliffDurationSeconds,
            epochDurationSeconds,
            numberOfEpochs
        );
    }
}
