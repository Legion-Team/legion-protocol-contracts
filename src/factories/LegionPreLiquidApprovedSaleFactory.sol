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

import { ILegionPreLiquidApprovedSale } from "../interfaces/sales/ILegionPreLiquidApprovedSale.sol";
import { ILegionPreLiquidApprovedSaleFactory } from "../interfaces/factories/ILegionPreLiquidApprovedSaleFactory.sol";

import { LegionPreLiquidApprovedSale } from "../sales/LegionPreLiquidApprovedSale.sol";

/**
 * @title Legion Pre-Liquid Approved Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V1 sales
 * @dev Utilizes the clone pattern to create new instances of LegionPreLiquidApprovedSale contracts
 */
contract LegionPreLiquidApprovedSaleFactory is ILegionPreLiquidApprovedSaleFactory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionPreLiquidApprovedSale implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_preLiquidApprovedSaleTemplate = address(new LegionPreLiquidApprovedSale());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionPreLiquidApprovedSaleFactory with an owner
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
     * @notice Deploys a new LegionPreLiquidApprovedSale contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param preLiquidSaleInitParams Calldata struct containing pre-liquid sale initialization parameters
     * @return preLiquidApprovedSaleInstance Address of the newly deployed and initialized PreLiquidSaleV1 instance
     */
    function createPreLiquidApprovedSale(
        LegionPreLiquidApprovedSale.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidApprovedSaleInstance)
    {
        // Deploy a LegionPreLiquidSale instance
        preLiquidApprovedSaleInstance = payable(i_preLiquidApprovedSaleTemplate.clone());

        // Emit NewPreLiquidApprovedSaleCreated
        emit NewPreLiquidApprovedSaleCreated(preLiquidApprovedSaleInstance, preLiquidSaleInitParams);

        // Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidApprovedSale(preLiquidApprovedSaleInstance).initialize(preLiquidSaleInitParams);
    }
}
