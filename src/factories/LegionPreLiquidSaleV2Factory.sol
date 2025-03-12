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
import { ILegionPreLiquidSaleV2Factory } from "../interfaces/factories/ILegionPreLiquidSaleV2Factory.sol";
import { ILegionPreLiquidSaleV2 } from "../interfaces/sales/ILegionPreLiquidSaleV2.sol";
import { LegionPreLiquidSaleV2 } from "../sales/LegionPreLiquidSaleV2.sol";

/**
 * @title Legion Pre-Liquid Sale V2 Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V2 sales
 * @dev Utilizes the clone pattern to create new instances of LegionPreLiquidSaleV2 contracts
 */
contract LegionPreLiquidSaleV2Factory is ILegionPreLiquidSaleV2Factory, Ownable {
    using LibClone for address;

    /// @notice Address of the LegionPreLiquidSaleV2 implementation contract used as template
    /// @dev Immutable reference to the base implementation deployed during construction
    address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());

    /**
     * @notice Initializes the LegionPreLiquidSaleV2Factory with an owner
     * @dev Sets up ownership during contract deployment
     * @param newOwner Address to be set as the initial owner of the factory
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice Deploys a new LegionPreLiquidSaleV2 contract instance
     * @dev Clones the template contract and initializes it with provided parameters; restricted to owner
     * @param saleInitParams Struct containing Legion sale initialization parameters
     * @return preLiquidSaleV2Instance Address of the newly deployed and initialized PreLiquidSaleV2 instance
     */
    function createPreLiquidSaleV2(ILegionSale.LegionSaleInitializationParams memory saleInitParams)
        external
        onlyOwner
        returns (address payable preLiquidSaleV2Instance)
    {
        // Deploy a LegionPreLiquidSaleV2 instance
        preLiquidSaleV2Instance = payable(preLiquidSaleV2Template.clone());

        // Emit NewPreLiquidSaleV2Created
        emit NewPreLiquidSaleV2Created(preLiquidSaleV2Instance, saleInitParams);

        // Initialize the LegionPreLiquidSaleV2 with the provided configuration
        LegionPreLiquidSaleV2(preLiquidSaleV2Instance).initialize(saleInitParams);
    }
}
