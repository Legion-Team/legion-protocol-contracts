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

import { ILegionPreLiquidSaleFactory } from "../interfaces/factories/ILegionPreLiquidSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionPreLiquidSale } from "../sales/LegionPreLiquidSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion pre-liquid open application sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each pre-liquid open application sale.
 */
contract LegionPreLiquidSaleFactory is ILegionPreLiquidSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionPreLiquidSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_preLiquidOpenApplicationSaleTemplate = address(new LegionPreLiquidSale());

    /// @notice Constructor for the LegionPreLiquidSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionPreLiquidSaleFactory
    function createPreLiquidOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidOpenApplicationSaleInstance)
    {
        // Deploy a LegionPreLiquidSale instance
        preLiquidOpenApplicationSaleInstance = payable(i_preLiquidOpenApplicationSaleTemplate.clone());

        // Emit NewPreLiquidOpenApplicationSaleCreated
        emit NewPreLiquidOpenApplicationSaleCreated(preLiquidOpenApplicationSaleInstance, saleInitParams);

        // Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidSale(preLiquidOpenApplicationSaleInstance).initialize(saleInitParams);
    }
}
