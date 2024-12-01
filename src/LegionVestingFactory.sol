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

import { LibClone } from "@solady/src/utils/LibClone.sol";

import { ILegionVestingFactory } from "./interfaces/ILegionVestingFactory.sol";
import { LegionLinearVesting } from "./LegionLinearVesting.sol";

/**
 * @title Legion Vesting Factory.
 * @author Legion.
 * @notice A factory contract for deploying proxy instances of a Legion vesting contracts.
 */
contract LegionVestingFactory is ILegionVestingFactory {
    using LibClone for address;

    /// @dev The LegionLinearVesting implementation contract.
    address public immutable linearVestingTemplate = address(new LegionLinearVesting());

    /**
     * @notice See {ILegionLinearVestingFactory-createLinearVesting}.
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

        // Emit successfully NewLinearVestingCreated
        emit NewLinearVestingCreated(beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds);

        // Initialize the LegionLinearVesting with the provided configuration
        LegionLinearVesting(linearVestingInstance).initialize(
            beneficiary, startTimestamp, durationSeconds, cliffDurationSeconds
        );
    }
}
