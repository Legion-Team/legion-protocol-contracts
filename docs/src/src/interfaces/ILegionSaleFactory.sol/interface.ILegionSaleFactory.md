# ILegionSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/ac3edaa080a44c4acca1531370a76a05f05491f5/src/interfaces/ILegionSaleFactory.sol)


## Functions
### createFixedPriceSale

Deploy a LegionFixedPriceSale contract.


```solidity
function createFixedPriceSale(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
)
    external
    returns (address payable fixedPriceSaleInstance);
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
|`fixedPriceSaleInstance`|`address payable`|The address of the FixedPriceSale instance deployed.|


### createPreLiquidSaleV1

Deploy a LegionPreLiquidSaleV1 contract.


```solidity
function createPreLiquidSaleV1(
    ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams calldata preLiquidSaleInitParams
)
    external
    returns (address payable preLiquidSaleV1Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleInitParams`|`ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams`|The Pre-Liquid sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV1Instance`|`address payable`|The address of the PreLiquidSale V1 instance deployed.|


### createPreLiquidSaleV2

Deploy a LegionPreLiquidSaleV2 contract.


```solidity
function createPreLiquidSaleV2(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionPreLiquidSaleV2.LegionVestingInitializationParams memory vestingInitParams
)
    external
    returns (address payable preLiquidSaleV2Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`vestingInitParams`|`ILegionPreLiquidSaleV2.LegionVestingInitializationParams`|The vesting initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV2Instance`|`address payable`|The address of the preLiquidSaleV2Instance deployed.|


### createSealedBidAuction

Deploy a LegionSealedBidAuctionSale contract.


```solidity
function createSealedBidAuction(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionSealedBidAuctionSale.SealedBidAuctionSaleInitializationParams memory sealedBidAuctionSaleInitParams,
    ILegionSale.LegionVestingInitializationParams memory vestingInitParams
)
    external
    returns (address payable sealedBidAuctionInstance);
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
|`sealedBidAuctionInstance`|`address payable`|The address of the SealedBidAuction instance deployed.|


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

### NewPreLiquidSaleV1Created
This event is emitted when a new pre-liquid V1 sale is deployed and initialized.


```solidity
event NewPreLiquidSaleV1Created(
    address saleInstance, ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams preLiquidSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`preLiquidSaleInitParams`|`ILegionPreLiquidSaleV1.PreLiquidSaleInitializationParams`|The configuration for the pre-liquid sale.|

### NewPreLiquidSaleV2Created
This event is emitted when a new pre-liquid V2 sale is deployed and initialized.


```solidity
event NewPreLiquidSaleV2Created(
    address saleInstance,
    ILegionSale.LegionSaleInitializationParams saleInitParams,
    ILegionPreLiquidSaleV2.LegionVestingInitializationParams vestingInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`vestingInitParams`|`ILegionPreLiquidSaleV2.LegionVestingInitializationParams`|The vesting initialization parameters.|

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

