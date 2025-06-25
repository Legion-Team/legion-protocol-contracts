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

import { ILegionAbstractSale } from "../sales/ILegionAbstractSale.sol";

/**
 * @title ILegionPreLiquidOpenApplicationSaleFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid open application sale contract instances
 */
interface ILegionPreLiquidOpenApplicationSaleFactory {
    /**
     * @notice Emitted when a new pre-liquid open application sale contract is deployed and initialized
     * @param saleInstance Address of the newly deployed pre-liquid open application sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     */
    event NewPreLiquidOpenApplicationSaleCreated(
        address saleInstance, ILegionAbstractSale.LegionSaleInitializationParams saleInitParams
    );

    /**
     * @notice Deploys a new LegionPreLiquidOpenApplicationSale contract instance
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @return preLiquidOpenApplicationSaleInstance Address of the newly deployed LegionPreLiquidOpenApplicationSale
     * instance
     */
    function createPreLiquidOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams
    )
        external
        returns (address payable preLiquidOpenApplicationSaleInstance);
}
