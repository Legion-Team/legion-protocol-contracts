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
 * @title Legion Sale Factory.
 * @author Legion.
 * @notice A factory contract for deploying proxy instances of Legion sales.
 */
contract LegionSaleFactory is ILegionSaleFactory, Ownable {
    using LibClone for address;

    /// @dev The LegionFixedPriceSale implementation contract.
    address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /// @dev The LegionPreLiquidSaleV1 implementation contract.
    address public immutable preLiquidSaleV1Template = address(new LegionPreLiquidSaleV1());

    /// @dev The LegionPreLiquidSaleV2 implementation contract.
    address public immutable preLiquidSaleV2Template = address(new LegionPreLiquidSaleV2());

    /// @dev The LegionSealedBidAuctionSale implementation contract.
    address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuctionSale());

    /**
     * @dev Constructor to initialize the LegionSaleFactory.
     *
     * @param newOwner The owner of the factory contract.
     */
    constructor(address newOwner) {
        _initializeOwner(newOwner);
    }

    /**
     * @notice See {ILegionSaleFactory-createFixedPriceSale}.
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

        // Emit successfully NewFixedPriceSaleCreated
        emit NewFixedPriceSaleCreated(
            fixedPriceSaleInstance, saleInitParams, fixedPriceSaleInitParams, vestingInitParams
        );

        // Initialize the LegionFixedPriceSale with the provided configuration
        LegionFixedPriceSale(fixedPriceSaleInstance).initialize(
            saleInitParams, fixedPriceSaleInitParams, vestingInitParams
        );
    }

    /**
     * @notice See {ILegionSaleFactory-createPreLiquidSale}.
     */
    function createPreLiquidSaleV1(
        LegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
    )
        external
        onlyOwner
        returns (address payable preLiquidSaleInstance)
    {
        /// Deploy a LegionPreLiquidSale instance
        preLiquidSaleInstance = payable(preLiquidSaleV1Template.clone());

        /// Emit successfully NewPreLiquidSaleCreated
        emit NewPreLiquidSaleV1Created(preLiquidSaleInstance, preLiquidSaleInitParams);

        /// Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidSaleV1(preLiquidSaleInstance).initialize(preLiquidSaleInitParams);
    }

    /**
     * @notice See {ILegionSaleFactory-createPreLiquidSaleV2}.
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

        // Emit successfully NewPreLiquidSaleCreated
        emit NewPreLiquidSaleV2Created(preLiquidSaleV2Instance, saleInitParams, vestingInitParams);

        // Initialize the LegionPreLiquidSaleV2 with the provided configuration
        LegionPreLiquidSaleV2(preLiquidSaleV2Instance).initialize(saleInitParams, vestingInitParams);
    }

    /**
     * @notice See {ILegionSaleFactory-createSealedBidAuction}.
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

        // Emit successfully NewSealedBidAuctionCreated
        emit NewSealedBidAuctionCreated(
            sealedBidAuctionInstance, saleInitParams, sealedBidAuctionSaleInitParams, vestingInitParams
        );

        // Initialize the LegionSealedBidAuctionSale with the provided configuration
        LegionSealedBidAuctionSale(sealedBidAuctionInstance).initialize(
            saleInitParams, sealedBidAuctionSaleInitParams, vestingInitParams
        );
    }
}
