// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

import { ILegionSale } from "../ILegionSale.sol";
import { ILegionPreLiquidSaleV2 } from "../ILegionPreLiquidSaleV2.sol";

interface ILegionPreLiquidSaleV2Factory {
    /**
     * @notice This event is emitted when a new pre-liquid V2 sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    event NewPreLiquidSaleV2Created(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionPreLiquidSaleV2.LegionVestingInitializationParams vestingInitParams
    );

    /**
     * @notice Deploy a LegionPreLiquidSaleV2 contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     *
     * @return preLiquidSaleV2Instance The address of the preLiquidSaleV2Instance deployed.
     */
    function createPreLiquidSaleV2(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionPreLiquidSaleV2.LegionVestingInitializationParams memory vestingInitParams
    )
        external
        returns (address payable preLiquidSaleV2Instance);
}
