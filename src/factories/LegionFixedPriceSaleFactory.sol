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

import { ILegionFixedPriceSale } from "../interfaces/sales/ILegionFixedPriceSale.sol";
import { ILegionFixedPriceSaleFactory } from "../interfaces/factories/ILegionFixedPriceSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionFixedPriceSale } from "../sales/LegionFixedPriceSale.sol";

/**
 * @title Legion Fixed Price Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion fixed price sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each fixed price sale.
 */
contract LegionFixedPriceSaleFactory is ILegionFixedPriceSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionFixedPriceSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /// @notice Constructor for the LegionFixedPriceSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionFixedPriceSaleFactory
    function createFixedPriceSale(
        ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
    )
        external
        onlyOwner
        returns (address payable fixedPriceSaleInstance)
    {
        // Deploy a LegionFixedPriceSale instance
        fixedPriceSaleInstance = payable(i_fixedPriceSaleTemplate.clone());

        // Emit NewFixedPriceSaleCreated
        emit NewFixedPriceSaleCreated(fixedPriceSaleInstance, saleInitParams, fixedPriceSaleInitParams);

        // Initialize the LegionFixedPriceSale with the provided configuration
        LegionFixedPriceSale(fixedPriceSaleInstance).initialize(saleInitParams, fixedPriceSaleInitParams);
    }
}
