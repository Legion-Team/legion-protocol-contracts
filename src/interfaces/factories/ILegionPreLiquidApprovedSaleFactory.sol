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

import { ILegionPreLiquidApprovedSale } from "../sales/ILegionPreLiquidApprovedSale.sol";

/**
 * @title ILegionPreLiquidApprovedSaleFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid V1 sale contract instances
 * @dev Defines events and functions for creating new pre-liquid V1 sale contracts
 */
interface ILegionPreLiquidApprovedSaleFactory {
    /**
     * @notice Emitted when a new pre-liquid V1 sale contract is deployed and initialized
     * @dev Provides details about the new sale instance and its configuration
     * @param saleInstance Address of the newly deployed pre-liquid V1 sale contract
     * @param preLiquidSaleInitParams Struct containing pre-liquid sale initialization parameters
     */
    event NewPreLiquidApprovedSaleCreated(
        address saleInstance, ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /**
     * @notice Deploys a new LegionPreLiquidApprovedSale contract instance
     * @dev Must be implemented to create and initialize a new pre-liquid V1 sale contract
     * @param preLiquidSaleInitParams Calldata struct containing pre-liquid sale initialization parameters
     * @return preLiquidApprovedSaleInstance Address of the newly deployed PreLiquidSaleV1 instance
     */
    function createPreLiquidApprovedSale(
        ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidApprovedSaleInstance);
}
