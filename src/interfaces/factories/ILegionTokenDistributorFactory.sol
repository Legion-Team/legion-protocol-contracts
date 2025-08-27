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

import { ILegionTokenDistributor } from "../distribution/ILegionTokenDistributor.sol";

/**
 * @title ILegionTokenDistributorFactory
 * @author Legion
 * @notice Interface for the LegionTokenDistributorFactory contract.
 * @dev Provides factory functionality for deploying and initializing token distributor contracts.
 */
interface ILegionTokenDistributorFactory {
    /// @notice Emitted when a new token distributor contract is deployed and initialized.
    /// @param distributorInstance The address of the newly deployed token distributor contract.
    /// @param distributorInitParams The Legion Token Distributor initialization parameters used.
    event NewTokenDistributorCreated(
        address distributorInstance, ILegionTokenDistributor.TokenDistributorInitializationParams distributorInitParams
    );

    /// @notice Deploys a new LegionTokenDistributor contract instance.
    /// @param distributorInitParams The Legion Token Distributor initialization parameters.
    /// @return distributorInstance The address of the newly deployed LegionTokenDistributor instance.
    function createTokenDistributor(
        ILegionTokenDistributor.TokenDistributorInitializationParams calldata distributorInitParams
    )
        external
        returns (address payable distributorInstance);
}
