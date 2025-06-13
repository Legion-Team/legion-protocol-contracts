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

import { LibClone } from "@solady/src/utils/LibClone.sol";

import { ILegionVestingFactory } from "../interfaces/factories/ILegionVestingFactory.sol";

import { LegionLinearEpochVesting } from "../vesting/LegionLinearEpochVesting.sol";
import { LegionLinearVesting } from "../vesting/LegionLinearVesting.sol";

/**
 * @title Legion Vesting Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion vesting contracts
 * @dev Utilizes the clone pattern to create new instances of linear and epoch-based vesting contracts
 */
contract LegionVestingFactory is ILegionVestingFactory {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionLinearVesting implementation contract used as template
    /// @dev Immutable reference to the base linear vesting implementation deployed during construction
    address public immutable i_linearVestingTemplate = address(new LegionLinearVesting());

    /// @notice Address of the LegionLinearEpochVesting implementation contract used as template
    /// @dev Immutable reference to the base epoch vesting implementation deployed during construction
    address public immutable i_linearEpochVestingTemplate = address(new LegionLinearEpochVesting());

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new linear vesting contract
     * @dev Clones the linear vesting template and initializes it with provided parameters
     * @param beneficiary Address that will receive the vested tokens
     * @param startTimestamp Unix timestamp when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @return linearVestingInstance Address of the newly deployed and initialized LegionLinearVesting instance
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
        linearVestingInstance = payable(i_linearVestingTemplate.clone());

        // Emit NewLinearVestingCreated
        emit NewLinearVestingCreated(beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds);

        // Initialize the LegionLinearVesting with the provided configuration
        LegionLinearVesting(linearVestingInstance).initialize(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }

    /**
     * @notice Creates a new linear epoch vesting contract
     * @dev Clones the epoch vesting template and initializes it with provided parameters
     * @param beneficiary Address that will receive the vested tokens
     * @param startTimestamp Unix timestamp when the vesting period begins
     * @param durationSeconds Total duration of the vesting period in seconds
     * @param cliffDurationSeconds Duration of the cliff period in seconds
     * @param epochDurationSeconds Duration of each epoch in seconds
     * @param numberOfEpochs Total number of epochs in the vesting schedule
     * @return linearEpochVestingInstance Address of the newly deployed and initialized LegionLinearEpochVesting
     * instance
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
        linearEpochVestingInstance = payable(i_linearEpochVestingTemplate.clone());

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
