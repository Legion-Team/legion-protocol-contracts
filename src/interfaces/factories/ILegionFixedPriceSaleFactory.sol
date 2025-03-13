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

import { ILegionFixedPriceSale } from "../sales/ILegionFixedPriceSale.sol";
import { ILegionSale } from "../sales/ILegionSale.sol";

/**
 * @title ILegionFixedPriceSaleFactory
 * @author Legion
 * @notice Interface for deploying and managing Legion fixed price sale contract instances
 * @dev Defines events and functions for creating new fixed price sale contracts
 */
interface ILegionFixedPriceSaleFactory {
    /**
     * @notice Emitted when a new fixed price sale contract is deployed and initialized
     * @dev Provides details about the new sale instance and its configuration
     * @param saleInstance Address of the newly deployed sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param fixedPriceSaleInitParams Struct containing fixed price sale specific initialization parameters
     */
    event NewFixedPriceSaleCreated(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams
    );

    /**
     * @notice Deploys a new LegionFixedPriceSale contract instance
     * @dev Must be implemented to create and initialize a new sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param fixedPriceSaleInitParams Struct containing fixed price sale specific initialization parameters
     * @return fixedPriceSaleInstance Address of the newly deployed FixedPriceSale instance
     */
    function createFixedPriceSale(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams
    )
        external
        returns (address payable fixedPriceSaleInstance);
}
