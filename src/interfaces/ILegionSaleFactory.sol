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

import { ILegionSale } from "./ILegionSale.sol";
import { ILegionFixedPriceSale } from "./ILegionFixedPriceSale.sol";
import { ILegionPreLiquidSaleV1 } from "./ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV2 } from "./ILegionPreLiquidSaleV2.sol";
import { ILegionSealedBidAuctionSale } from "./ILegionSealedBidAuctionSale.sol";

interface ILegionSaleFactory {
    /**
     * @notice This event is emitted when a new fixed price sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param fixedPriceSaleInitParams The fixed price sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    event NewFixedPriceSaleCreated(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams,
        ILegionSale.LegionVestingInitializationParams vestingInitParams
    );

    /**
     * @notice This event is emitted when a new pre-liquid V1 sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param preLiquidSaleInitParams The configuration for the pre-liquid sale.
     */
    event NewPreLiquidSaleV1Created(
        address saleInstance, ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams
    );

    /**
     * @notice This event is emitted when a new pre-liquid V2 sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    event NewPreLiquidSaleV2Created(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionPreLiquidSaleV2.LegionVestingInitializationParams vestingInitParams
    );

    /**
     * @notice This event is emitted when a new sealed bid auction is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param saleInitParams The Legion sale initialization parameters.
     * @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     */
    event NewSealedBidAuctionCreated(
        address saleInstance,
        ILegionSale.LegionSaleInitializationParams saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams,
        ILegionSale.LegionVestingInitializationParams vestingInitParams
    );

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
        returns (address payable fixedPriceSaleInstance);

    /**
     * @notice Deploy a LegionPreLiquidSaleV1 contract.
     *
     * @param preLiquidSaleInitParams The Pre-Liquid sale initialization parameters.
     *
     * @return preLiquidSaleV1Instance The address of the PreLiquidSale V1 instance deployed.
     */
    function createPreLiquidSaleV1(
        ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        returns (address payable preLiquidSaleV1Instance);

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
        returns (address payable preLiquidSaleV2Instance);

    /**
     * @notice Deploy a LegionSealedBidAuctionSale contract.
     *
     * @param saleInitParams The Legion sale initialization parameters.
     * @param sealedBidAuctionSaleInitParams The sealed bid auction sale specific initialization parameters.
     * @param vestingInitParams The vesting initialization parameters.
     *
     * @return sealedBidAuctionInstance The address of the SealedBidAuction instance deployed.
     */
    function createSealedBidAuction(
        ILegionSale.LegionSaleInitializationParams memory saleInitParams,
        ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
        ILegionSale.LegionVestingInitializationParams memory vestingInitParams
    )
        external
        returns (address payable sealedBidAuctionInstance);
}
