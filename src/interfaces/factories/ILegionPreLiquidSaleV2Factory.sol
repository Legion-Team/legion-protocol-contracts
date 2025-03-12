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

import { ILegionSale } from "../sales/ILegionSale.sol";
import { ILegionPreLiquidSaleV2 } from "../sales/ILegionPreLiquidSaleV2.sol";

/**
 * @title ILegionPreLiquidSaleV2Factory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid V2 sale contract instances
 * @dev Defines events and functions for creating new pre-liquid V2 sale contracts
 */
interface ILegionPreLiquidSaleV2Factory {
    /**
     * @notice Emitted when a new pre-liquid V2 sale contract is deployed and initialized
     * @dev Provides details about the new sale instance and its configuration
     * @param saleInstance Address of the newly deployed pre-liquid V2 sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     */
    event NewPreLiquidSaleV2Created(address saleInstance, ILegionSale.LegionSaleInitializationParams saleInitParams);

    /**
     * @notice Deploys a new LegionPreLiquidSaleV2 contract instance
     * @dev Must be implemented to create and initialize a new pre-liquid V2 sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @return preLiquidSaleV2Instance Address of the newly deployed PreLiquidSaleV2 instance
     */
    function createPreLiquidSaleV2(ILegionSale.LegionSaleInitializationParams memory saleInitParams)
        external
        returns (address payable preLiquidSaleV2Instance);
}
