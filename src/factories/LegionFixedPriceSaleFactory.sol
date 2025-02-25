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
import { ILegionFixedPriceSale } from "../interfaces/ILegionFixedPriceSale.sol";
import { ILegionFixedPriceSaleFactory } from "../interfaces/factories/ILegionFixedPriceSaleFactory.sol";
import { LegionFixedPriceSale } from "../LegionFixedPriceSale.sol";

/**
 * @title Legion Fixed Price Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion fixed price sales
 */
contract LegionFixedPriceSaleFactory is ILegionFixedPriceSaleFactory, Ownable {
    using LibClone for address;

    /// @dev The LegionFixedPriceSale implementation contract
    address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /**
     * @dev Constructor to initialize the LegionSaleFactory
     *
     * @param newOwner The owner of the factory contract
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice Deploy a LegionFixedPriceSale contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     *
     * @return fixedPriceSaleInstance The address of the FixedPriceSale instance deployed.
     */
    function createFixedPriceSale(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams,
        ILegionSale.LegionVestingInitializationParams memory vestingInitParams
    )
        external
        onlyOwner
        returns (address payable fixedPriceSaleInstance)
    {
        // Deploy a LegionFixedPriceSale instance
        fixedPriceSaleInstance = payable(fixedPriceSaleTemplate.clone());

        // Emit NewFixedPriceSaleCreated
        emit NewFixedPriceSaleCreated(
            fixedPriceSaleInstance, saleInitParams, fixedPriceSaleInitParams, vestingInitParams
        );

        // Initialize the LegionFixedPriceSale with the provided configuration
        LegionFixedPriceSale(fixedPriceSaleInstance).initialize(
            saleInitParams, fixedPriceSaleInitParams, vestingInitParams
        );
    }
}
