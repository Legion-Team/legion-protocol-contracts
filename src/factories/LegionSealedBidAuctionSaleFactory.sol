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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";
import { ILegionSealedBidAuctionSale } from "../interfaces/sales/ILegionSealedBidAuctionSale.sol";
import { ILegionSealedBidAuctionSaleFactory } from "../interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol";

import { LegionSealedBidAuctionSale } from "../sales/LegionSealedBidAuctionSale.sol";

/**
 * @title Legion Sealed Bid Auction Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion sealed bid auction sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each sealed bid auction sale.
 */
contract LegionSealedBidAuctionSaleFactory is ILegionSealedBidAuctionSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionSealedBidAuctionSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());

    /// @notice Constructor for the LegionSealedBidAuctionSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionSealedBidAuctionSaleFactory
    function createSealedBidAuctionSale(
        ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams calldata sealedBidAuctionSaleInitParams
    )
        external
        onlyOwner
        returns (address payable sealedBidAuctionInstance)
    {
        // Deploy a LegionSealedBidAuctionSale instance
        sealedBidAuctionInstance = payable(i_sealedBidAuctionTemplate.clone());

        // Emit NewSealedBidAuctionSaleCreated
        emit NewSealedBidAuctionSaleCreated(sealedBidAuctionInstance, saleInitParams, sealedBidAuctionSaleInitParams);

        // Initialize the LegionSealedBidAuctionSale with the provided configuration
        LegionSealedBidAuctionSale(sealedBidAuctionInstance).initialize(saleInitParams, sealedBidAuctionSaleInitParams);
    }
}
