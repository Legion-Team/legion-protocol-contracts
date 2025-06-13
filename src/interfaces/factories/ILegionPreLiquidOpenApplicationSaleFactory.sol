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

import { ILegionAbstractSale } from "../sales/ILegionAbstractSale.sol";

/**
 * @title ILegionPreLiquidOpenApplicationSaleFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid V2 sale contract instances
 * @dev Defines events and functions for creating new pre-liquid V2 sale contracts
 */
interface ILegionPreLiquidOpenApplicationSaleFactory {
    /**
     * @notice Emitted when a new pre-liquid V2 sale contract is deployed and initialized
     * @dev Provides details about the new sale instance and its configuration
     * @param saleInstance Address of the newly deployed pre-liquid V2 sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     */
    event NewPreLiquidOpenApplicationSaleCreated(
        address saleInstance, ILegionAbstractSale.LegionSaleInitializationParams saleInitParams
    );

    /**
     * @notice Deploys a new LegionPreLiquidOpenApplicationSale contract instance
     * @dev Must be implemented to create and initialize a new pre-liquid V2 sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @return preLiquidOpenApplicationSaleInstance Address of the newly deployed PreLiquidSaleV2 instance
     */
    function createPreLiquidOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams
    )
        external
        returns (address payable preLiquidOpenApplicationSaleInstance);
}
