# ILegionFixedPriceSaleFactory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/e045131669c5801ab2e88b13e55002362a64c068/src/interfaces/factories/ILegionFixedPriceSaleFactory.sol)


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

