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
 * @notice Interface for the LegionCapitalRaiseFactory contract.
 */
interface ILegionCapitalRaiseFactory {
    /// @notice Emitted when a new capital raise contract is deployed and initialized
    /// @param capitalRaiseInstance Address of the newly deployed capital raise contract
    /// @param capitalRaiseInitParams Struct containing capital raise initialization parameters
    event NewCapitalRaiseCreated(
        address capitalRaiseInstance, ILegionCapitalRaise.CapitalRaiseInitializationParams capitalRaiseInitParams
    );

    /// @notice Deploys a new LegionCapitalRaise contract instance.
    /// @param capitalRaiseInitParams The initialization parameters for the capital raise campaign.
    /// @return capitalRaiseInstance The address of the newly deployed and initialized LegionCapitalRaise instance.
    function createCapitalRaise(ILegionCapitalRaise.CapitalRaiseInitializationParams calldata capitalRaiseInitParams)
        external
        returns (address payable capitalRaiseInstance);
}
