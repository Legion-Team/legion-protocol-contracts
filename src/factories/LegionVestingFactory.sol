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

import { LibClone } from "@solady/src/utils/LibClone.sol";

import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";
import { LegionLinearVesting } from "../vesting/LegionLinearVesting.sol";
import { LegionLinearEpochVesting } from "../vesting/LegionLinearEpochVesting.sol";

/**
 * @title Legion Vesting Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion vesting contracts
 */
contract LegionVestingFactory is ILegionVestingFactory {
    using LibClone for address;

    /// @dev The LegionLinearVesting implementation contract
    address public immutable linearVestingTemplate = address(new LegionLinearVesting());

    /// @dev The LegionLinearVesting implementation contract
    address public immutable linearEpochVestingTemplate = address(new LegionLinearEpochVesting());

    /**
     * @notice Creates a new linear vesting contract
     *
     * @param beneficiary The address that will receive the vested tokens
     * @param startTimestamp The Unix timestamp when the vesting period starts
     * @param durationSeconds The duration of the vesting period in seconds
     * @param cliffDurationSeconds The duration of the cliff period in seconds
     * @return linearVestingInstance The address of the deployed LegionLinearVesting instance
     */
    function createLinearVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds
    )
        external
        returns (address payable linearVestingInstance)
    {
        // Deploy a LegionLinearVesting instance
        linearVestingInstance = payable(linearVestingTemplate.clone());

        // Emit NewLinearVestingCreated
        emit NewLinearVestingCreated(beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds);

        // Initialize the LegionLinearVesting with the provided configuration
        LegionLinearVesting(linearVestingInstance).initialize(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }

    /**
     * @notice Creates a new linear epoch vesting contract
     *
     * @param beneficiary The address that will receive the vested tokens
     * @param startTimestamp The Unix timestamp when the vesting period starts
     * @param durationSeconds The duration of the vesting period in seconds
     * @param cliffDurationSeconds The duration of the cliff period in seconds
     * @param epochDurationSeconds The duration of each epoch in seconds
     * @param numberOfEpochs The number of epochs
     * @return linearEpochVestingInstance The address of the deployed LegionLinearVesting instance
     */
    function createLinearEpochVesting(
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint64 cliffDurationSeconds,
        uint256 epochDurationSeconds,
        uint256 numberOfEpochs
    )
        external
        returns (address payable linearEpochVestingInstance)
    {
        // Deploy a LegionLinearVesting instance
        linearEpochVestingInstance = payable(linearEpochVestingTemplate.clone());

        // Emit NewLinearVestingCreated
        emit NewLinearEpochVestingCreated(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds, epochDurationSeconds, numberOfEpochs
        );

        // Initialize the LegionLinearVesting with the provided configuration
        LegionLinearEpochVesting(linearEpochVestingInstance).initialize(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds, epochDurationSeconds, numberOfEpochs
        );
    }
}
