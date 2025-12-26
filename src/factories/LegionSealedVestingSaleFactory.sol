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

import { ILegionSealedVestingSale } from "../interfaces/sales/ILegionSealedVestingSale.sol";
import { ILegionSealedVestingSaleFactory } from "../interfaces/factories/ILegionSealedVestingSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionSealedVestingSale } from "../sales/LegionSealedVestingSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Factory
 * @author Legion
 * @notice Deploys proxy instances of Legion pre-liquid open application sale contracts using the clone pattern.
 * @dev Creates gas-efficient clones of a single implementation contract for each pre-liquid open application sale.
 */
contract LegionSealedVestingSaleFactory is ILegionSealedVestingSaleFactory, Ownable {
    using LibClone for address;

    /// @notice The address of the LegionSealedVestingSale implementation contract used as a template.
    /// @dev Immutable reference to the base implementation deployed during construction.
    address public immutable i_sealedVestingOpenApplicationSaleTemplate = address(new LegionSealedVestingSale());

    /// @notice Constructor for the LegionPreLiquidSaleFactory contract.
    /// @dev Initializes ownership during contract deployment.
    /// @param newOwner The address to be set as the initial owner of the factory.
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /// @inheritdoc ILegionSealedVestingSaleFactory
    function createSealedVestingOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedVestingSale.PreLiquidSaleInitializationParams calldata sealedVestingOpenApplicationSaleInitParams
    )
        external
        onlyOwner
        returns (address payable sealedVestingOpenApplicationSaleInstance)
    {
        // Deploy a LegionSealedVestingSale instance
        sealedVestingOpenApplicationSaleInstance = payable(i_sealedVestingOpenApplicationSaleTemplate.clone());

        // Emit NewSealedVestingOpenApplicationSaleCreated
        emit NewSealedVestingOpenApplicationSaleCreated(
            sealedVestingOpenApplicationSaleInstance, saleInitParams, sealedVestingOpenApplicationSaleInitParams
        );

        // Initialize the LegionSealedVestingSale with the provided configuration
        LegionSealedVestingSale(sealedVestingOpenApplicationSaleInstance).initialize(
            saleInitParams, sealedVestingOpenApplicationSaleInitParams
        );
    }
}
