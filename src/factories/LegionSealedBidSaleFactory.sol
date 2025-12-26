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
import { ILegionSealedBidSale } from "../interfaces/sales/ILegionSealedBidSale.sol";
import { ILegionSealedBidSaleFactory } from "../interfaces/factories/ILegionSealedBidSaleFactory.sol";

import { LegionSealedBidSale } from "../sales/LegionSealedBidSale.sol";

/**
 * @title Legion Sealed Bid Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion sealed bid  sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each sealed bid  sale.
 */
contract LegionSealedBidSaleFactory is ILegionSealedBidSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionSealedBidSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_sealedBidSaleTemplate = address(new LegionSealedBidSale());

    /// @notice Constructor for the LegionSealedBidSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionSealedBidSaleFactory
    function createSealedBidSale(
        ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
        ILegionSealedBidSale.SealedBidSaleInitializationParams calldata sealedBidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable sealedBidSaleInstance)
    {
        // Deploy a LegionSealedBidSale instance
        sealedBidSaleInstance = payable(i_sealedBidSaleTemplate.clone());

        // Emit NewSealedBidSaleCreated
        emit NewSealedBidSaleCreated(sealedBidSaleInstance, saleInitParams, sealedBidSaleInitParams);

        // Initialize the LegionSealedBidSale with the provided configuration
        LegionSealedBidSale(sealedBidSaleInstance).initialize(saleInitParams, sealedBidSaleInitParams);
    }
}
