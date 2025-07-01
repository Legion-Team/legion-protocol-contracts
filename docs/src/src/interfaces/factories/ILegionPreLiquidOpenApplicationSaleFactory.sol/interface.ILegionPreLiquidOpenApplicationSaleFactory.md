# ILegionPreLiquidOpenApplicationSaleFactory
[Git Source](https://github.com/Legion-Team/legion-protocol-contracts/blob/76d9c4dea483beb3f4b747419db2d23fd27a8182/src/interfaces/factories/ILegionPreLiquidOpenApplicationSaleFactory.sol)

**Author:**
Legion

Interface for the Legion PreLiquidOpenApplicationSaleFactory contract.


## Functions
### createPreLiquidOpenApplicationSale

Deploys a new LegionPreLiquidOpenApplicationSale contract instance.


```solidity
function createPreLiquidOpenApplicationSale(ILegionAbstractSale.LegionSaleInitializationParams memory saleInitParams)
    external
    returns (address payable preLiquidOpenApplicationSaleInstance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`preLiquidOpenApplicationSaleInstance`|`address payable`|The address of the newly deployed and initialized LegionPreLiquidOpenApplicationSale instance.|


## Events
### NewPreLiquidOpenApplicationSaleCreated
Emitted when a new pre-liquid open application sale contract is deployed and initialized.


```solidity
event NewPreLiquidOpenApplicationSaleCreated(
    address saleInstance, ILegionAbstractSale.LegionSaleInitializationParams saleInitParams
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`saleInstance`|`address`|The address of the newly deployed pre-liquid open application sale contract.|
|`saleInitParams`|`ILegionAbstractSale.LegionSaleInitializationParams`|The Legion sale initialization parameters used.|

