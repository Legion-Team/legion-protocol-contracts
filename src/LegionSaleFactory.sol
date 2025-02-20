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

import { ILegionSale } from "./interfaces/ILegionSale.sol";
import { ILegionSaleFactory } from "./interfaces/ILegionSaleFactory.sol";
import { ILegionFixedPriceSale } from "./interfaces/ILegionFixedPriceSale.sol";
import { ILegionPreLiquidSaleV1 } from "./interfaces/ILegionPreLiquidSaleV1.sol";
import { ILegionPreLiquidSaleV2 } from "./interfaces/ILegionPreLiquidSaleV2.sol";
import { ILegionSealedBidAuctionSale } from "./interfaces/ILegionSealedBidAuctionSale.sol";
import { LegionFixedPriceSale } from "./LegionFixedPriceSale.sol";
import { LegionPreLiquidSaleV1 } from "./LegionPreLiquidSaleV1.sol";
import { LegionPreLiquidSaleV2 } from "./LegionPreLiquidSaleV2.sol";
import { LegionSealedBidAuctionSale } from "./LegionSealedBidAuctionSale.sol";

/**
 * @title Legion Sale Factory
 * @author Legion
 * @notice A factory contract for deploying proxy instances of Legion sales
 */
contract LegionSaleFactory is ILegionSaleFactory, Ownable {
    using LibClone for address;

    /// @dev The LegionFixedPriceSale implementation contract
    address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /// @dev The LegionPreLiquidSaleV1 implementation contract
    address public immutable preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());

    /// @dev The LegionPreLiquidSaleV2 implementation contract
    address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());

    /// @dev The LegionSealedBidAuctionSale implementation contract
    address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());

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
        onlyOwner
        returns (address payable sealedBidAuctionInstance)
    {
        // Deploy a LegionSealedBidAuctionSale instance
        sealedBidAuctionInstance = payable(sealedBidAuctionTemplate.clone());

        // Emit NewSealedBidAuctionCreated
        emit NewSealedBidAuctionCreated(
            sealedBidAuctionInstance, saleInitParams, sealedBidAuctionSaleInitParams, vestingInitParams
        );

        // Initialize the LegionSealedBidAuctionSale with the provided configuration
        LegionSealedBidAuctionSale(sealedBidAuctionInstance).initialize(
            saleInitParams, sealedBidAuctionSaleInitParams, vestingInitParams
        );
    }
}
