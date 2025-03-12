# ILegionPreLiquidSaleV2Factory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/eacaebdc1fce4e197305af05084de59f36b83e3e/src/interfaces/factories/ILegionPreLiquidSaleV2Factory.sol)


## Functions
### createPreLiquidSaleV2

Deploy a LegionPreLiquidSaleV2 contract.


```solidity
function createPreLiquidSaleV2(ILegionSale.LegionSaleInitializationParams memory saleInitParams)
    external
    returns (address payable preLiquidSaleV2Instance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidSaleV2Instance`|`address payable`|The address of the preLiquidSaleV2Instance deployed.|


## Events
### NewPreLiquidSaleV2Created
This event is emitted when a new pre-liquid V2 sale is deployed and initialized.


```solidity
event NewPreLiquidSaleV2Created(address saleInstance, ILegionSale.LegionSaleInitializationParams saleInitParams);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the sale instance deployed.|
|`saleInitParams`|`ILegionSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|

