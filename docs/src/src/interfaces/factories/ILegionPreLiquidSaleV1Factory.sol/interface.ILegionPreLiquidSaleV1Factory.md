# ILegionPreLiquidSaleV1Factory
[Git Source](https://github.com/Legion-Team/evm-contracts/blob/1a165deeea33dfd2b1dca142bf23d06b547c39a3/src/interfaces/factories/ILegionPreLiquidSaleV1Factory.sol)


## Functions
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


## Events
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

