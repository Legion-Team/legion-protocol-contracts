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

import { ILegionAbstractSale } from "../sales/ILegionAbstractSale.sol";
import { ILegionSealedVestingOpenApplicationSale } from "../sales/ILegionSealedVestingOpenApplicationSale.sol";

/**
 * @title ILegionSealedVestingOpenApplicationSaleFactory
 * @author Legion
 * @notice Interface for the Legion LegionSealedVestingOpenApplicationSaleFactory contract.
 */
interface ILegionSealedVestingOpenApplicationSaleFactory {
    /// @notice Emitted when a new sealed-vesting pre-liquid open application sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed sealed-vesting pre-liquid open application sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    /// @param sealedVestingOpenApplicationSaleInitParams The sealed-vesting pre-liquid open application sale specific
    event NewSealedVestingOpenApplicationSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedVestingOpenApplicationSale.PreLiquidSaleInitializationParams
            sealedVestingOpenApplicationSaleInitParams
    );

    /// @notice Deploys a new LegionSealedVestingOpenApplicationSale contract instance.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @param sealedVestingOpenApplicationSaleInitParams The sealed-vesting pre-liquid open application sale specific
    /// initialization parameters.
    /// @return sealedVestingOpenApplicationSaleInstance The address of the newly deployed and initialized
    /// LegionSealedVestingOpenApplicationSale instance.
    function createSealedVestingOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedVestingOpenApplicationSale.PreLiquidSaleInitializationParams memory
            sealedVestingOpenApplicationSaleInitParams
    )
        external
        returns (address payable sealedVestingOpenApplicationSaleInstance);
}
