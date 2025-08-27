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

import { ILegionPreLiquidApprovedSale } from "../interfaces/sales/ILegionPreLiquidApprovedSale.sol";
import { ILegionPreLiquidApprovedSaleFactory } from "../interfaces/factories/ILegionPreLiquidApprovedSaleFactory.sol";

import { LegionPreLiquidApprovedSale } from "../sales/LegionPreLiquidApprovedSale.sol";

/**
 * @title Legion Pre-Liquid Approved Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion pre-liquid approved sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each pre-liquid approved sale.
 */
contract LegionPreLiquidApprovedSaleFactory is ILegionPreLiquidApprovedSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionPreLiquidApprovedSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_preLiquidApprovedSaleTemplate = address(new LegionPreLiquidApprovedSale());

    /// @notice Constructor for the LegionPreLiquidApprovedSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionPreLiquidApprovedSaleFactory
    function createPreLiquidApprovedSale(
        LegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidApprovedSaleInstance)
    {
        // Deploy a LegionPreLiquidApprovedSale instance
        preLiquidApprovedSaleInstance = payable(i_preLiquidApprovedSaleTemplate.clone());

        // Emit NewPreLiquidApprovedSaleCreated
        emit NewPreLiquidApprovedSaleCreated(preLiquidApprovedSaleInstance, preLiquidSaleInitParams);

        // Initialize the LegionPreLiquidApprovedSale with the provided configuration
        LegionPreLiquidApprovedSale(preLiquidApprovedSaleInstance).initialize(preLiquidSaleInitParams);
    }
}
