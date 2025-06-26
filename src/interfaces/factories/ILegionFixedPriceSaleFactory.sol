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

import { ILegionFixedPriceSale } from "../sales/ILegionFixedPriceSale.sol";
import { ILegionAbstractSale } from "../sales/ILegionAbstractSale.sol";

/**
 * @title ILegionFixedPriceSaleFactory
 * @author Legion
 * @notice Interface for the LegionFixedPriceSaleFactory contract.
 */
interface ILegionFixedPriceSaleFactory {
    /// @notice Emitted when a new fixed price sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    /// @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters used.
    event NewFixedPriceSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams
    );

    /// @notice Deploys a new LegionFixedPriceSale contract instance.
    /// @param saleInitParams The general Legion sale initialization parameters.
    /// @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
    /// @return fixedPriceSaleInstance The address of the newly deployed and initialized LegionFixedPriceSale instance.
    function createFixedPriceSale(
        ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external
        returns (address payable fixedPriceSaleInstance);
}
