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

import { ILegionPreLiquidSaleV1 } from "../sales/ILegionPreLiquidSaleV1.sol";

/**
 * @title ILegionPreLiquidSaleV1Factory
 * @author Legion
 * @notice Interface for deploying and managing Legion pre-liquid V1 sale contract instances
 * @dev Defines events and functions for creating new pre-liquid V1 sale contracts
 */
interface ILegionPreLiquidSaleV1Factory {
    /**
     * @notice Emitted when a new pre-liquid V1 sale contract is deployed and initialized
     * @dev Provides details about the new sale instance and its configuration
     * @param saleInstance Address of the newly deployed pre-liquid V1 sale contract
     * @param preLiquidSaleInitParams Struct containing pre-liquid sale initialization parameters
     */
    event NewPreLiquidSaleV1Created(
        address saleInstance, ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /**
     * @notice Deploys a new LegionPreLiquidSaleV1 contract instance
     * @dev Must be implemented to create and initialize a new pre-liquid V1 sale contract
     * @param preLiquidSaleInitParams Calldata struct containing pre-liquid sale initialization parameters
     * @return preLiquidSaleV1Instance Address of the newly deployed PreLiquidSaleV1 instance
     */
    function createPreLiquidSaleV1(
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidSaleV1Instance);
}
