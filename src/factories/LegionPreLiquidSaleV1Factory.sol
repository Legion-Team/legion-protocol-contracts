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

import { ILegionPreLiquidSaleV1 } from "../interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV1Factory } from "../interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";

import { LegionPreLiquidSaleV1 } from "../sales/LegionPreLiquidSaleV1.sol";

/**
 * @title Legion Pre-Liquid Sale V1 Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V1 sales
 * @dev Utilizes the clone pattern to create new instances of LegionPreLiquidSaleV1 contracts
 */
contract LegionPreLiquidSaleV1Factory is ILegionPreLiquidSaleV1Factory, Ownable {
    using LibClone for address;

    /*//////////////////////////////////////////////////////////////////////////
                                 STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Address of the LegionPreLiquidSaleV1 implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable i_preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());

    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the LegionPreLiquidSaleV1Factory with an owner
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
     * @notice Deploys a new LegionPreLiquidSaleV1 contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param preLiquidSaleInitParams Calldata struct containing pre-liquid sale initialization parameters
     * @return preLiquidSaleV1Instance Address of the newly deployed and initialized PreLiquidSaleV1 instance
     */
    function createPreLiquidSaleV1(
        LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidSaleV1Instance)
    {
        // Deploy a LegionPreLiquidSale instance
        preLiquidSaleV1Instance = payable(i_preLiquidSaleV1Template.clone());

        // Emit NewPreLiquidSaleV1Created
        emit NewPreLiquidSaleV1Created(preLiquidSaleV1Instance, preLiquidSaleInitParams);

        // Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidSaleV1(preLiquidSaleV1Instance).initialize(preLiquidSaleInitParams);
    }
}
