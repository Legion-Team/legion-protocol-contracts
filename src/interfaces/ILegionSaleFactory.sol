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
import {ILegionFixedPriceSale} from "./ILegionFixedPriceSale.sol";
import {ILegionPreLiquidSale} from "./ILegionPreLiquidSale.sol";
import {ILegionSealedBidAuction} from "./ILegionSealedBidAuction.sol";

interface ILegionSaleFactory {
    /**
     * @notice This event is emitted when a new fixed price sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param fixedPriceSaleConfig The configuration for the fixed price sale.
     */
    event NewFixedPriceSaleCreated(
        address saleInstance, ILegionFixedPriceSale.FixedPriceSaleConfig fixedPriceSaleConfig
    );

    /**
     * @notice This event is emitted when a new pre-liquid sale is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param preLiquidSaleConfig The configuration for the pre-liquid sale.
     */
    event NewPreLiquidSaleCreated(address saleInstance, ILegionPreLiquidSale.PreLiquidSaleConfig preLiquidSaleConfig);

    /**
     * @notice This event is emitted when a new sealed bid auction is deployed and initialized.
     *
     * @param saleInstance The address of the sale instance deployed.
     * @param sealedBidAuctionConfig The configuration for the sealed bid auction.
     */
    event NewSealedBidAuctionCreated(
        address saleInstance, ILegionSealedBidAuction.SealedBidAuctionConfig sealedBidAuctionConfig
    );

    /**
     * @notice Deploy a LegionFixedPriceSale contract.
     *
     * @param fixedPriceSaleConfig The configuration for the fixed price sale.
     *
     * @return fixedPriceSaleInstance The address of the fixedPriceSaleInstance deployed.
     */
    function createFixedPriceSale(ILegionFixedPriceSale.FixedPriceSaleConfig calldata fixedPriceSaleConfig)
        external
        returns (address payable fixedPriceSaleInstance);

    /**
     * @notice Deploy a LegionPreLiquidSale contract.
     *
     * @param preLiquidSaleConfig The configuration for the pre-liquid sale.
     *
     * @return preLiquidSaleInstance The address of the preLiquidSaleInstance deployed.
     */
    function createPreLiquidSale(ILegionPreLiquidSale.PreLiquidSaleConfig calldata preLiquidSaleConfig)
        external
        returns (address payable preLiquidSaleInstance);

    /**
     * @notice Deploy a LegionSealedBidAuction contract.
     *
     * @param sealedBidAuctionConfig The configuration for the sealed bid auction.
     *
     * @return sealedBidAuctionInstance The address of the sealedBidAuctionInstance deployed.
     */
    function createSealedBidAuction(ILegionSealedBidAuction.SealedBidAuctionConfig calldata sealedBidAuctionConfig)
        external
        returns (address payable sealedBidAuctionInstance);
}
