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

import { ILegionSealedVestingOpenApplicationSale } from
    "../interfaces/sales/ILegionSealedVestingOpenApplicationSale.sol";
import { ILegionSealedVestingOpenApplicationSaleFactory } from
    "../interfaces/factories/ILegionSealedVestingOpenApplicationSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionSealedVestingOpenApplicationSale } from "../sales/LegionSealedVestingOpenApplicationSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion pre-liquid open application sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each pre-liquid open application sale.
 */
contract LegionSealedVestingOpenApplicationSaleFactory is ILegionSealedVestingOpenApplicationSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionSealedVestingOpenApplicationSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_sealedVestingOpenApplicationSaleTemplate =
        address(new LegionSealedVestingOpenApplicationSale());

    /// @notice Constructor for the LegionPreLiquidOpenApplicationSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionSealedVestingOpenApplicationSaleFactory
    function createSealedVestingOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedVestingOpenApplicationSale.PreLiquidSaleInitializationParams calldata
            sealedVestingOpenApplicationSaleInitParams
    )
        external
        onlyOwner
        returns (address payable sealedVestingOpenApplicationSaleInstance)
    {
        // Deploy a LegionSealedVestingOpenApplicationSale instance
        sealedVestingOpenApplicationSaleInstance = payable(i_sealedVestingOpenApplicationSaleTemplate.clone());

        // Emit NewSealedVestingOpenApplicationSaleCreated
        emit NewSealedVestingOpenApplicationSaleCreated(
            sealedVestingOpenApplicationSaleInstance, saleInitParams, sealedVestingOpenApplicationSaleInitParams
        );

        // Initialize the LegionSealedVestingOpenApplicationSale with the provided configuration
        LegionSealedVestingOpenApplicationSale(sealedVestingOpenApplicationSaleInstance).initialize(
            saleInitParams, sealedVestingOpenApplicationSaleInitParams
        );
    }
}
