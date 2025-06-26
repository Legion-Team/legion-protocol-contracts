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

import { ILegionVesting } from "./ILegionVesting.sol";

/**
 * @title ILegionLinearEpochVesting
 * @author Legion
 * @notice Interface for the LegionLinearEpochVesting contract.
 */
interface ILegionLinearEpochVesting is ILegionVesting {
    /// @notice Returns the duration of each epoch in seconds
    /// @return uint256 Duration of each epoch in seconds
    function epochDurationSeconds() external view returns (uint256);

    /// @notice Returns the total number of epochs in the vesting schedule
    /// @return uint256 Total number of epochs in the vesting schedule
    function numberOfEpochs() external view returns (uint256);

    /// @notice Returns the last epoch for which tokens were claimed
    /// @return uint256 Last epoch number for which tokens were claimed
    function lastClaimedEpoch() external view returns (uint256);
}
