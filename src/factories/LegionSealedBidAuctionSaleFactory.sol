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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionSale } from "../interfaces/ILegionSale.sol";
import { ILegionSealedBidAuctionSaleFactory } from "../interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol";
import { ILegionSealedBidAuctionSale } from "../interfaces/ILegionSealedBidAuctionSale.sol";
import { LegionSealedBidAuctionSale } from "../LegionSealedBidAuctionSale.sol";

/**
 * @title Legion Sealed Bid Auction Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion sealed bid auction sales
 */
contract LegionSealedBidAuctionSaleFactory is ILegionSealedBidAuctionSaleFactory, Ownable {
    using LibClone for address;

    /// @dev The LegionSealedBidAuctionSale implementation contract
    address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());

    /**
     * @dev Constructor to initialize the LegionSaleFactory
     *
     * @param newOwner The owner of the factory contract
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

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
        onlyOwner
        returns (address payable sealedBidAuctionInstance)
    {
        // Deploy a LegionSealedBidAuctionSale instance
        sealedBidAuctionInstance = payable(sealedBidAuctionTemplate.clone());

        // Emit NewSealedBidAuctionCreated
        emit NewSealedBidAuctionCreated(sealedBidAuctionInstance, saleInitParams, sealedBidAuctionSaleInitParams);

        // Initialize the LegionSealedBidAuctionSale with the provided configuration
        LegionSealedBidAuctionSale(sealedBidAuctionInstance).initialize(saleInitParams, sealedBidAuctionSaleInitParams);
    }
}
