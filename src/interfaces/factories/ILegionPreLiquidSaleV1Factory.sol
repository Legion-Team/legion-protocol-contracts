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

interface ILegionPreLiquidSaleV1Factory {
    /**
     * @notice This event is emitted when a new pre-liquid V1 sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param preLiquidSaleInitParams The configuration for the pre-liquid sale.
     */
    event NewPreLiquidSaleV1Created(
        address saleInstance, ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /**
     * @notice Deploy a LegionPreLiquidSaleV1 contract.
     *
     * @param preLiquidSaleInitParams The Pre-Liquid sale initialization parameters.
     *
     * @return preLiquidSaleV1Instance The address of the PreLiquidSale V1 instance deployed.
     */
    function createPreLiquidSaleV1(
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidSaleV1Instance);
}
