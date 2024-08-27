// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * ██      ███████  ██████  ██  ██████  ███    ██
 * ██      ██      ██       ██ ██    ██ ████   ██
 * ██      █████   ██   ███ ██ ██    ██ ██ ██  ██
 * ██      ██      ██    ██ ██ ██    ██ ██  ██ ██
 * ███████ ███████  ██████  ██  ██████  ██   ████
 *
 * If you find a bug, please contact security(at)legion.cc
 * We will pay a fair bounty for any issue that puts user's funds at risk.
 *
 */
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILegionSaleFactory} from "./interfaces/ILegionSaleFactory.sol";

import {LegionFixedPriceSale} from "./LegionFixedPriceSale.sol";
import {LegionPreLiquidSale} from "./LegionPreLiquidSale.sol";
import {LegionSealedBidAuction} from "./LegionSealedBidAuction.sol";

/**
 * @title Legion Sale Factory.
 * @author Legion.
 * @notice A factory contract for deploying proxy instances of Legion sales.
 */
contract LegionSaleFactory is ILegionSaleFactory, Ownable {
    using Clones for address;

    /// @dev The LegionFixedPriceSale implementation contract.
    address public immutable fixedPriceSaleTemplate = address(new LegionFixedPriceSale());

    /// @dev The LegionPreLiquidSale implementation contract.
    address public immutable preLiquidSaleTemplate = address(new LegionPreLiquidSale());

    /// @dev The LegionSealedBidAuction implementation contract.
    address public immutable sealedBidAuctionTemplate = address(new LegionSealedBidAuction());

    /**
     * @dev Constructor to initialize the LegionSaleFactory.
     *
     * @param newOwner The owner of the factory contract.
     */
    constructor(address newOwner) Ownable(newOwner) {}

    /**
     * @notice See {ILegionSaleFactory-createFixedPriceSale}.
     */
    function createFixedPriceSale(LegionFixedPriceSale.FixedPriceSaleConfig calldata fixedPriceSaleConfig)
        external
        onlyOwner
        returns (address payable fixedPriceSaleInstance)
    {
        /// Deploy a LegionFixedPriceSale instance
        fixedPriceSaleInstance = payable(fixedPriceSaleTemplate.clone());

        /// Emit successfully NewFixedPriceSaleCreated
        emit NewFixedPriceSaleCreated(fixedPriceSaleInstance, fixedPriceSaleConfig);

        /// Initialize the LegionFixedPriceSale with the provided configuration
        LegionFixedPriceSale(fixedPriceSaleInstance).initialize(fixedPriceSaleConfig);
    }

    /**
     * @notice See {ILegionSaleFactory-createPreLiquidSale}.
     */
    function createPreLiquidSale(LegionPreLiquidSale.PreLiquidSaleConfig calldata preLiquidSaleConfig)
        external
        onlyOwner
        returns (address payable preLiquidSaleInstance)
    {
        /// Deploy a LegionPreLiquidSale instance
        preLiquidSaleInstance = payable(preLiquidSaleTemplate.clone());

        /// Emit successfully NewPreLiquidSaleCreated
        emit NewPreLiquidSaleCreated(preLiquidSaleInstance, preLiquidSaleConfig);

        /// Initialize the LegionPreLiquidSale with the provided configuration
        LegionPreLiquidSale(preLiquidSaleInstance).initialize(preLiquidSaleConfig);
    }

    /**
     * @notice See {ILegionSaleFactory-createSealedBidAuction}.
     */
    function createSealedBidAuction(LegionSealedBidAuction.SealedBidAuctionConfig calldata sealedBidAuctionConfig)
        external
        onlyOwner
        returns (address payable sealedBidAuctionInstance)
    {
        /// Deploy a LegionSealedBidAuction instance
        sealedBidAuctionInstance = payable(sealedBidAuctionTemplate.clone());

        /// Emit successfully NewSealedBidAuctionCreated
        emit NewSealedBidAuctionCreated(sealedBidAuctionInstance, sealedBidAuctionConfig);

        /// Initialize the LegionSealedBidAuction with the provided configuration
        LegionSealedBidAuction(sealedBidAuctionInstance).initialize(sealedBidAuctionConfig);
    }
}
