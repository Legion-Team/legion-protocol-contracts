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

import { ILegionPreLiquidApprovedSale } from "../sales/ILegionPreLiquidApprovedSale.sol";

/**
 * @title ILegionPreLiquidApprovedSaleFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid approved sale contract instances
 */
interface ILegionPreLiquidApprovedSaleFactory {
    /**
     * @notice Emitted when a new pre-liquid approved sale contract is deployed and initialized
     * @param saleInstance Address of the newly deployed pre-liquid approved sale contract
     * @param preLiquidSaleInitParams Struct containing pre-liquid sale initialization parameters
     */
    event NewPreLiquidApprovedSaleCreated(
        address saleInstance, ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /**
     * @notice Deploys a new LegionPreLiquidApprovedSale contract instance
     * @param preLiquidSaleInitParams Calldata struct containing pre-liquid sale initialization parameters
     * @return preLiquidApprovedSaleInstance Address of the newly deployed LegionPreLiquidApprovedSale instance
     */
    function createPreLiquidApprovedSale(
        ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidApprovedSaleInstance);
}
