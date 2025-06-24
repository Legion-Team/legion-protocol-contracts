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

import { ILegionCapitalRaise } from "../raise/ILegionCapitalRaise.sol";

/**
 * @title ILegionCapitalRaiseFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion capital raise contract instances
 */
interface ILegionCapitalRaiseFactory {
    /**
     * @notice Emitted when a new capital raise contract is deployed and initialized
     * @param capitalRaiseInstance Address of the newly deployed capital raise contract
     * @param capitalRaiseInitParams Struct containing capital raise initialization parameters
     */
    event NewCapitalRaiseCreated(
        address capitalRaiseInstance, ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams
    );

    /**
     * @notice Deploys a new LegionCapitalRaise contract instance
     * @param capitalRaiseInitParams Calldata struct containing capital raise initialization parameters
     * @return capitalRaiseInstance Address of the newly deployed LegionCapitalRaise instance
     */
    function createCapitalRaise(ILegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
        external
        returns (address payable capitalRaiseInstance);
}
