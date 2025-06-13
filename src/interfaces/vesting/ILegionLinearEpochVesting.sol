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

import { ILegionVesting } from "./ILegionVesting.sol";

/**
 * @title ILegionLinearEpochVesting
 * @author Legion
 * @notice Interface for a linear epoch-based vesting contract in the Legion Protocol
 * @dev Extends vesting functionality with epoch-based release and cliff mechanics
 */
interface ILegionLinearEpochVesting is ILegionVesting {
    /**
     * @notice Returns the duration of each epoch in seconds
     * @dev Specific to this interface; defines the vesting interval for epoch-based releases
     * @return uint256 Duration of each epoch in seconds
     */
    function epochDurationSeconds() external view returns (uint256);

    /**
     * @notice Returns the total number of epochs in the vesting schedule
     * @dev Specific to this interface; determines the granularity of token releases
     * @return uint256 Total number of epochs in the vesting schedule
     */
    function numberOfEpochs() external view returns (uint256);

    /**
     * @notice Returns the last epoch for which tokens were claimed
     * @dev Specific to this interface; tracks the progress of vesting claims
     * @return uint256 Last epoch number for which tokens were claimed
     */
    function lastClaimedEpoch() external view returns (uint256);
}
