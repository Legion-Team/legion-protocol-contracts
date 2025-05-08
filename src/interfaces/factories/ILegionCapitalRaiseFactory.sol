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

import { ILegionCapitalRaise } from "../raise/ILegionCapitalRaise.sol";

/**
 * @title ILegionCapitalRaiseFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion capital raise contract instances
 * @dev Defines events and functions for creating new capital raise contracts
 */
interface ILegionCapitalRaiseFactory {
    /**
     * @notice Emitted when a new capital raise contract is deployed and initialized
     * @dev Provides details about the new capital raise instance and its configuration
     * @param capitalRaiseInstance Address of the newly deployed capital raise contract
     * @param capitalRaiseInitParams Struct containing capital raise initialization parameters
     */
    event NewCapitalRaiseCreated(
        address capitalRaiseInstance, ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams
    );

    /**
     * @notice Deploys a new LegionCapitalRaise contract instance
     * @dev Must be implemented to create and initialize a new capital raise contract
     * @param capitalRaiseInitParams Calldata struct containing capital raise initialization parameters
     * @return capitalRaiseInstance Address of the newly deployed LegionCapitalRaise instance
     */
    function createCapitalRaise(ILegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
        external
        returns (address payable capitalRaiseInstance);
}
