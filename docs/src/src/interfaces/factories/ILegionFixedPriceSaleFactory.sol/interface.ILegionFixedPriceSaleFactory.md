# ILegionFixedPriceSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/85d479ea08d148a380138b535ed11768adee16de/src/interfaces/factories/ILegionFixedPriceSaleFactory.sol)

**Author:**
Legion

Interface for the LegionFixedPriceSaleFactory contract.


## Functions
### createFixedPriceSale

Deploys a new LegionFixedPriceSale contract instance.


```solidity
function createFixedPriceSale(
    ILegionAbstractSale.LegionSaleInitializationParams calldata saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams calldata fixedPriceSaleInitParams
)
    external
    returns (address payable fixedPriceSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The general Legion sale initialization parameters.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`fixedPriceSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionFixedPriceSale instance.|


## Events
### NewFixedPriceSaleCreated
Emitted when a new fixed price sale contract is deployed and initialized.


```solidity
event NewFixedPriceSaleCreated(
    address saleInstance,
    ILegionAbstractSale.LegionSaleInitializationParams saleInitParams,
    ILegionFixedPriceSale.FixedPriceSaleInitializationParams fixedPriceSaleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed sale contract.|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters used.|
|`fixedPriceSaleInitParams`|`ILegionFixedPriceSale.FixedPriceSaleInitializationParams`|The fixed price sale specific initialization parameters used.|

