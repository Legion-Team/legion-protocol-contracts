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
 * @notice Interface for deploying and managing Legion token distributor instances
 */
interface ILegionTokenDistributorFactory {
    /**
     * @notice Emitted when a new token distributor contract is deployed and initialized
     * @param distributorInstance Address of the newly deployed token distributor contract
     * @param distributorInitParams Struct containing Legion Token Distributor initialization parameters
     */
    event NewTokenDistributorCreated(
        address distributorInstance, ILegionTokenDistributor.TokenDistributorInitializationParams distributorInitParams
    );

    /**
     * @notice Deploys a new LegionTokenDistributor contract instance
     * @param distributorInitParams Struct containing Legion Token Distributor initialization parameters
     * @return distributorInstance Address of the newly deployed LegionTokenDistributor instance
     */
    function createTokenDistributor(
        ILegionTokenDistributor.TokenDistributorInitializationParams calldata distributorInitParams
    )
        external
        returns (address payable distributorInstance);
}
