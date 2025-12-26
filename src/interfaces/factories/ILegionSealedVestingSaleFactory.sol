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
import { ILegionSealedVestingSale } from "../sales/ILegionSealedVestingSale.sol";

/**
 * @title ILegionSealedVestingSaleFactory
 * @author Legion
 * @notice Interface for the Legion LegionSealedVestingSaleFactory contract.
 */
interface ILegionSealedVestingSaleFactory {
    /// @notice Emitted when a new sealed-vesting pre-liquid open application sale contract is deployed and initialized.
    /// @param saleInstance The address of the newly deployed sealed-vesting pre-liquid open application sale contract.
    /// @param saleInitParams The Legion sale initialization parameters used.
    /// @param sealedVestingOpenApplicationSaleInitParams The sealed-vesting pre-liquid open application sale specific
    event NewSealedVestingOpenApplicationSaleCreated(
        address saleInstance,
        ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedVestingSale.PreLiquidSaleInitializationParams sealedVestingOpenApplicationSaleInitParams
    );

    /// @notice Deploys a new LegionSealedVestingSale contract instance.
    /// @param saleInitParams The Legion sale initialization parameters.
    /// @param sealedVestingOpenApplicationSaleInitParams The sealed-vesting pre-liquid open application sale specific
    /// initialization parameters.
    /// @return sealedVestingOpenApplicationSaleInstance The address of the newly deployed and initialized
    /// LegionSealedVestingSale instance.
    function createSealedVestingOpenApplicationSale(
        ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedVestingSale.PreLiquidSaleInitializationParams memory sealedVestingOpenApplicationSaleInitParams
    )
        external
        returns (address payable sealedVestingOpenApplicationSaleInstance);
}
