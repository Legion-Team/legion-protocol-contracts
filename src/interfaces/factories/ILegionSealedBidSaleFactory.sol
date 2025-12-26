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
import { ILegionSealedBidSale } from "../sales/ILegionSealedBidSale.sol";

/**
 * @title ILegionSealedBidSaleFactory
 * @author Legion
 * @notice Interface for the LegionSealedBidSaleFactory contract.
 */
interface ILegionSealedBidSaleFactory {
    /// @notice Emitted when a new sealed bid sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed sealed bid sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    /// @param sealedBidSaleInitParams The sealed bid sale specific initialization parameters used.
    event NewSealedBidSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedBidSale.SealedBidSaleInitializationParams sealedBidSaleInitParams
    );

    /// @notice Deploys a new LegionSealedBidSale contract instance.
    /// @param saleInitParams The general Legion sale initialization parameters.
    /// @param sealedBidSaleInitParams The sealed bid sale specific initialization parameters.
    /// @return sealedBidSaleInstance The address of the newly deployed and initialized LegionSealedBidSale
    /// instance.
    function createSealedBidSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedBidSale.SealedBidSaleInitializationParams memory sealedBidSaleInitParams
    )
        external
        returns (address payable sealedBidSaleInstance);
}
