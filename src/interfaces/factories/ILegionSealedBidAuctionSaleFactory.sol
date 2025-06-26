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
import { ILegionSealedBidAuctionSale } from "../sales/ILegionSealedBidAuctionSale.sol";

/**
 * @title ILegionSealedBidAuctionSaleFactory
 * @author Legion
 * @notice Interface for the LegionSealedBidAuctionSaleFactory contract.
 */
interface ILegionSealedBidAuctionSaleFactory {
    /// @notice Emitted when a new sealed bid auction sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed sealed bid auction sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    /// @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters used.
    event NewSealedBidAuctionSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams
    );

    /// @notice Deploys a new LegionSealedBidAuctionSale contract instance.
    /// @param saleInitParams The general Legion sale initialization parameters.
    /// @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
    /// @return sealedBidAuctionInstance The address of the newly deployed and initialized LegionSealedBidAuctionSale
    /// instance.
    function createSealedBidAuctionSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams
    )
        external
        returns (address payable sealedBidAuctionInstance);
}
