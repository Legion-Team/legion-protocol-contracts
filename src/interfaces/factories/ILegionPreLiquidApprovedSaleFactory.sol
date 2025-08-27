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
 * @notice Interface for the LegionPreLiquidApprovedSaleFactory contract.
 */
interface ILegionPreLiquidApprovedSaleFactory {
    /// @notice Emitted when a new pre-liquid approved sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed pre-liquid approved sale contract.
    /// @param preLiquidSaleInitParams The pre-liquid sale initialization parameters used.
    event NewPreLiquidApprovedSaleCreated(
        address saleInstance, ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /// @notice Deploys a new LegionPreLiquidApprovedSale contract instance.
    /// @param preLiquidSaleInitParams The initialization parameters for the pre-liquid approved sale.
    /// @return preLiquidApprovedSaleInstance The address of the newly deployed and initialized
    /// LegionPreLiquidApprovedSale instance.
    function createPreLiquidApprovedSale(
        ILegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidApprovedSaleInstance);
}
