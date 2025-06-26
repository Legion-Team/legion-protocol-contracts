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
 * @notice Interface for the Legion PreLiquidOpenApplicationSaleFactory contract.
 */
interface ILegionPreLiquidOpenApplicationSaleFactory {
    /// @notice Emitted when a new pre-liquid open application sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed pre-liquid open application sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    event NewPreLiquidOpenApplicationSaleCreated(
        address saleInstance, ILegionAbstractSale.LegionSaleInitializationParams saleInitParams
    );

    /// @notice Deploys a new LegionPreLiquidOpenApplicationSale contract instance.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @return preLiquidOpenApplicationSaleInstance The address of the newly deployed and initialized
    /// LegionPreLiquidOpenApplicationSale instance.
    function createPreLiquidOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams
    )
        external
        returns (address payable preLiquidOpenApplicationSaleInstance);
}
