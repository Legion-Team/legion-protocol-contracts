// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

import { ILegionSale } from "../interfaces/ILegionSale.sol";
import { ILegionPreLiquidSaleV2Factory } from "../interfaces/factories/ILegionPreLiquidSaleV2Factory.sol";
import { ILegionPreLiquidSaleV2 } from "../interfaces/ILegionPreLiquidSaleV2.sol";
import { LegionPreLiquidSaleV2 } from "../LegionPreLiquidSaleV2.sol";
/**
 * @title Legion Pre-Liquid Sale V2 Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V2 sales
 */

contract LegionPreLiquidSaleV2Factory is ILegionPreLiquidSaleV2Factory, Ownable {
    using LibClone for address;

    /// @dev The LegionPreLiquidSaleV2 implementation contract
    address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());

    /**
     * @dev Constructor to initialize the LegionSaleFactory
     *
     * @param newOwner The owner of the factory contract
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice Deploy a LegionPreLiquidSaleV2 contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     *
     * @return preLiquidSaleV2Instance The address of the preLiquidSaleV2Instance deployed.
     */
    function createPreLiquidSaleV2(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionPreLiquidSaleV2.LegionVestingInitializationParams memory vestingInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidSaleV2Instance)
    {
        // Deploy a LegionPreLiquidSaleV2 instance
        preLiquidSaleV2Instance = payable(preLiquidSaleV2Template.clone());

        // Emit NewPreLiquidSaleV2Created
        emit NewPreLiquidSaleV2Created(preLiquidSaleV2Instance, saleInitParams, vestingInitParams);

        // Initialize the LegionPreLiquidSaleV2 with the provided configuration
        LegionPreLiquidSaleV2(preLiquidSaleV2Instance).initialize(saleInitParams, vestingInitParams);
    }
}
