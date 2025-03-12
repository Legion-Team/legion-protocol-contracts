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

import { ILegionPreLiquidSaleV1Factory } from "../interfaces/factories/ILegionPreLiquidSaleV1Factory.sol";
import { ILegionPreLiquidSaleV1 } from "../interfaces/sales/ILegionPreLiquidSaleV1.sol";
import { LegionPreLiquidSaleV1 } from "../sales/LegionPreLiquidSaleV1.sol";

/**
 * @title Legion Pre-Liquid Sale V1 Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion pre-liquid V1 sales
 */
contract LegionPreLiquidSaleV1Factory is ILegionPreLiquidSaleV1Factory, Ownable {
    using LibClone for address;

    /// @dev The LegionPreLiquidSaleV1 implementation contract
    address public immutable preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());

    /**
     * @dev Constructor to initialize the LegionSaleFactory
     *
     * @param newOwner The owner of the factory contract
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice Deploy a LegionPreLiquidSaleV1 contract.
     *
     * @param preLiquidSaleInitParams The Pre-Liquid sale initialization parameters.
     *
     * @return preLiquidSaleV1Instance The address of the PreLiquidSale V1 instance deployed.
     */
    function createPreLiquidSaleV1(
        LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidSaleV1Instance)
    {
        // Deploy a LegionPreLiquidSale instance
        preLiquidSaleV1Instance = payable(preLiquidSaleV1Template.clone());

        // Emit NewPreLiquidSaleV1Created
        emit NewPreLiquidSaleV1Created(preLiquidSaleV1Instance, preLiquidSaleInitParams);

        // Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidSaleV1(preLiquidSaleV1Instance).initialize(preLiquidSaleInitParams);
    }
}
