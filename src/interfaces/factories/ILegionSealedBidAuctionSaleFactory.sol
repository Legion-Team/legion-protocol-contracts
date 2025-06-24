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
 * @notice Interface for deploying and managing Legion sealed bid auction sale contract instances
 */
interface ILegionSealedBidAuctionSaleFactory {
    /**
     * @notice Emitted when a new sealed bid auction sale contract is deployed and initialized
     * @param saleInstance Address of the newly deployed sealed bid auction sale contract
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param sealedBidAuctionSaleInitParams Struct containing sealed bid auction sale specific initialization
     * parameters
     */
    event NewSealedBidAuctionSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams
    );

    /**
     * @notice Deploys a new LegionSealedBidAuctionSale contract instance
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param sealedBidAuctionSaleInitParams Struct containing sealed bid auction sale specific initialization
     * parameters
     * @return sealedBidAuctionInstance Address of the newly deployed SealedBidAuction instance
     */
    function createSealedBidAuctionSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams
    )
        external
        returns (address payable sealedBidAuctionInstance);
}
