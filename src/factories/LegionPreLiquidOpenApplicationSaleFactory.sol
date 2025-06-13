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

import { LibClone } from "@solady/src/utils/LibClone.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { ILegionPreLiquidOpenApplicationSaleFactory } from
    "../interfaces/factories/ILegionPreLiquidOpenApplicationSaleFactory.sol";
import { ILegionAbstractSale } from "../interfaces/sales/ILegionAbstractSale.sol";

import { LegionPreLiquidOpenApplicationSale } from "../sales/LegionPreLiquidOpenApplicationSale.sol";

/**
 * @title Legion Pre-Liquid Open Application Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V2 sales
 * @dev Utilizes the clone pattern to create new instances of LegionPreLiquidOpenApplicationSale contracts
 */
contract LegionPreLiquidOpenApplicationSaleFactory is ILegionPreLiquidOpenApplicationSaleFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionPreLiquidOpenApplicationSale implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_preLiquidOpenApplicationSaleTemplate = address(new LegionPreLiquidOpenApplicationSale());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionPreLiquidOpenApplicationSaleFactory with an owner
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
     * @notice Deploys a new LegionPreLiquidOpenApplicationSale contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @return preLiquidOpenApplicationSaleInstance Address of the newly deployed and initialized PreLiquidSaleV2
     * instance
     */
    function createPreLiquidOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidOpenApplicationSaleInstance)
    {
        // Deploy a LegionPreLiquidOpenApplicationSale instance
        preLiquidOpenApplicationSaleInstance = payable(i_preLiquidOpenApplicationSaleTemplate.clone());

        // Emit NewPreLiquidOpenApplicationSaleCreated
        emit NewPreLiquidOpenApplicationSaleCreated(preLiquidOpenApplicationSaleInstance, saleInitParams);

        // Initialize the LegionPreLiquidOpenApplicationSale with the provided configuration
        LegionPreLiquidOpenApplicationSale(preLiquidOpenApplicationSaleInstance).initialize(saleInitParams);
    }
}
