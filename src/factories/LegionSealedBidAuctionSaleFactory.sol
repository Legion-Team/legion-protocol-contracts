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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionSale } from "../interfaces/sales/ILegionSale.sol";
import { ILegionSealedBidAuctionSale } from "../interfaces/sales/ILegionSealedBidAuctionSale.sol";
import { ILegionSealedBidAuctionSaleFactory } from "../interfaces/factories/ILegionSealedBidAuctionSaleFactory.sol";

import { LegionSealedBidAuctionSale } from "../sales/LegionSealedBidAuctionSale.sol";

/**
 * @title Legion Sealed Bid Auction Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion sealed bid auction sales
 * @dev Utilizes the clone pattern to create new instances of LegionSealedBidAuctionSale contracts
 */
contract LegionSealedBidAuctionSaleFactory is ILegionSealedBidAuctionSaleFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionSealedBidAuctionSale implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionSealedBidAuctionSaleFactory with an owner
     * @dev Sets up ownership during contract deployment
     * @param newOwner Address to be set as the initial owner of the factory
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /*//////////////////////////////////////////////////////////////////////////
                              EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys a new LegionSealedBidAuctionSale contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @param sealedBidAuctionSaleInitParams Struct containing sealed bid auction sale specific initialization
     * parameters
     * @return sealedBidAuctionInstance Address of the newly deployed and initialized SealedBidAuction instance
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
