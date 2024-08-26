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
     * @param fixedPriceSalePeriodAndFeeConfig The period and fee configuration for the fixed price sale.
     * @param fixedPriceSaleAddressConfig The address configuration for the fixed price sale.
     */
    event NewFixedPriceSaleCreated(
        address saleInstance,
        ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig fixedPriceSalePeriodAndFeeConfig,
        ILegionFixedPriceSale.FixedPriceSaleAddressConfig fixedPriceSaleAddressConfig
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
     * @param sealedBidAuctionPeriodAndFeeConfig The period and fee configuration for the sealed bid auction.
     * @param sealedBidAuctionAddressConfig The address configuration for the sealed bid auction.
     */
    event NewSealedBidAuctionCreated(
        address saleInstance,
        ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig sealedBidAuctionPeriodAndFeeConfig,
        ILegionSealedBidAuction.SealedBidAuctionAddressConfig sealedBidAuctionAddressConfig
    );

    /**
     * @notice Deploy a LegionFixedPriceSale contract.
     *
     * @param fixedPriceSalePeriodAndFeeConfig The period and fee configuration for the fixed price sale.
     * @param fixedPriceSaleAddressConfig The address configuration for the fixed price sale.
     *
     * @return fixedPriceSaleInstance The address of the fixedPriceSaleInstance deployed.
     */
    function createFixedPriceSale(
        ILegionFixedPriceSale.FixedPriceSalePeriodAndFeeConfig calldata fixedPriceSalePeriodAndFeeConfig,
        ILegionFixedPriceSale.FixedPriceSaleAddressConfig calldata fixedPriceSaleAddressConfig
    ) external returns (address payable fixedPriceSaleInstance);

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
     * @param sealedBidAuctionPeriodAndFeeConfig The period and fee configuration for the sealed bid auction.
     * @param sealedBidAuctionAddressConfig The address configuration for the sealed bid auction.
     *
     * @return sealedBidAuctionInstance The address of the sealedBidAuctionInstance deployed.
     */
    function createSealedBidAuction(
        ILegionSealedBidAuction.SealedBidAuctionPeriodAndFeeConfig calldata sealedBidAuctionPeriodAndFeeConfig,
        ILegionSealedBidAuction.SealedBidAuctionAddressConfig calldata sealedBidAuctionAddressConfig
    ) external returns (address payable sealedBidAuctionInstance);
}
