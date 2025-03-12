# ILegionFixedPriceSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/a0becaf0413338ea78e3b0a0ce4527f7e1695849/src/interfaces/factories/ILegionFixedPriceSaleFactory.sol)


## Functions
### createFixedPriceSale

Deploy a LegionFixedPriceSale contract.


```solidity
function createFixedPriceSale(
    ILegionSale.LegionSaleInitializationParams memory saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams memory fixedPriceSaleInitParams
)
    external
    returns (address payable fixedPriceSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fixedPriceSaleInstance`|`address payable`|The address of the FixedPriceSale instance deployed.|


## Events
### NewFixedPriceSaleCreated
This event is emitted when a new fixed price sale is deployed and initialized.


```solidity
event NewFixedPriceSaleCreated(
    address saleInstance,
    ILegionSale.LegionSaleInitializationParams saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|

