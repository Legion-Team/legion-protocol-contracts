# ILegionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/9d232ccfd9d55ef7fb8933835be077c1145ee4d5/src/interfaces/ILegionSaleFactory.sol)


## Functions
### createFixedPriceSale

Deploy a LegionFixedPriceSale contract.


```solidity
function createFixedPriceSale(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
) external returns (address payable fixedPriceSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fixedPriceSaleInstance`|`address payable`|The address of the fixedPriceSaleInstance deployed.|


### createPreLiquidSale

Deploy a LegionPreLiquidSale contract.


```solidity
function createPreLiquidSale(
    ILegionPreLiquidSale.PreLiquidSaleInitializationParams memory preLiquidSaleInitParams,
    ILegionPreLiquidSale.LegionVestingInitializationParams memory vestingInitParams
) external returns (address payable preLiquidSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`ILegionPreLiquidSale.PreLiquidSaleInitializationParams`|The pre-liquid sale initialization params.|
|`vestingInitParams`|`ILegionPreLiquidSale.LegionVestingInitializationParams`|The vesting initialization params.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInstance`|`address payable`|The address of the preLiquidSaleInstance deployed.|


### createSealedBidAuction

Deploy a LegionSealedBidAuctionSale contract.


```solidity
function createSealedBidAuction(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
) external returns (address payable sealedBidAuctionInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`sealedBidAuctionInstance`|`address payable`|The address of the sealedBidAuctionInstance deployed.|


## Events
### NewFixedPriceSaleCreated
This event is emitted when a new fixed price sale is deployed and initialized.


```solidity
event NewFixedPriceSaleCreated(
    address saleInstance,
    ILegionSale.LegionSaleInitializationParams saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams,
    ILegionSale.LegionVestingInitializationParams vestingInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

### NewPreLiquidSaleCreated
This event is emitted when a new pre-liquid sale is deployed and initialized.


```solidity
event NewPreLiquidSaleCreated(
    address saleInstance,
    ILegionPreLiquidSale.PreLiquidSaleInitializationParams preLiquidSaleInitParams,
    ILegionPreLiquidSale.LegionVestingInitializationParams vestingInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`preLiquidSaleInitParams`|`ILegionPreLiquidSale.PreLiquidSaleInitializationParams`|The pre-liquid sale initialization params.|
|`vestingInitParams`|`ILegionPreLiquidSale.LegionVestingInitializationParams`|The vesting initialization params.|

### NewSealedBidAuctionCreated
This event is emitted when a new sealed bid auction is deployed and initialized.


```solidity
event NewSealedBidAuctionCreated(
    address saleInstance,
    ILegionSale.LegionSaleInitializationParams saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams vestingInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`sealedBidAuctionSaleInitParams`|`ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams`|The sealed bid auction sale specific initialization parameters.|
|`vestingInitParams`|`ILegionSale.LegionVestingInitializationParams`|The vesting initialization parameters.|

