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

import { ILegionSale } from "../sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../sales/ILegionSealedBidAuctionSale.sol";

interface ILegionSealedBidAuctionSaleFactory {
    /**
     * @notice This event is emitted when a new sealed bid auction is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
     */
    event NewSealedBidAuctionCreated(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams
    );

    /**
     * @notice Deploy a LegionSealedBidAuctionSale contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
     *
     * @return sealedBidAuctionInstance The address of the SealedBidAuction instance deployed.
     */
    function createSealedBidAuction(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams
    )
        external
        returns (address payable sealedBidAuctionInstance);
}
