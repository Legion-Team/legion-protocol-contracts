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
import { ILegionFixedPriceSale } from "../ILegionFixedPriceSale.sol";

interface ILegionFixedPriceSaleFactory {
    /**
     * @notice This event is emitted when a new fixed price sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
     */
    event NewFixedPriceSaleCreated(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams
    );

    /**
     * @notice Deploy a LegionFixedPriceSale contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
     *
     * @return fixedPriceSaleInstance The address of the FixedPriceSale instance deployed.
     */
    function createFixedPriceSale(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams
    )
        external
        returns (address payable fixedPriceSaleInstance);
}
